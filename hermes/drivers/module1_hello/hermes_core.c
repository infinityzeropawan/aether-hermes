#/*******************************************************************************
 * HERMES Kernel Module
 * Author: Pawan kumar dubey
 * Note: This file modified/maintained by Pawan kumar dubey
 ******************************************************************************/

#include <linux/module.h>
#include <linux/init.h>
#include <linux/gpio.h>
#include <linux/interrupt.h>
#include <linux/delay.h>
#include <linux/spinlock.h>
#include <linux/workqueue.h>

#define TOUCH_GPIO 17
#define LED_R 27
#define LED_G 22  
#define LED_B 23
#define DEBOUNCE_MS 200  // 200ms debounce time

static int touch_irq_number;
static bool system_armed = false;
static spinlock_t state_lock;
static struct workqueue_struct *led_workqueue;
static unsigned long last_touch_time = 0;

struct led_work {
    struct work_struct work;
    bool is_armed;
};

static void set_led_color(int red, int green, int blue) {
    gpio_set_value(LED_R, red);
    gpio_set_value(LED_G, green);
    gpio_set_value(LED_B, blue);
}

// This function runs in workqueue context (can sleep)
static void led_blink_worker(struct work_struct *work) {
    struct led_work *led_task = container_of(work, struct led_work, work);
    bool is_armed = led_task->is_armed;
    
    if (is_armed) {
        printk(KERN_INFO "HERMES: LED worker - showing ARMED sequence\n");
        
        // Blue blink 1
        set_led_color(0, 0, 1);
        msleep(300);
        
        // LED off
        set_led_color(0, 0, 0);
        msleep(150);
        
        // Blue blink 2
        set_led_color(0, 0, 1);
        msleep(300);
        
        // Green steady
        set_led_color(0, 1, 0);
        printk(KERN_INFO "HERMES: System ARMED (Green LED on GPIO 22)\n");
    } else {
        printk(KERN_INFO "HERMES: LED worker - showing DISARMED sequence\n");
        
        // All LEDs off first
        set_led_color(0, 0, 0);
        msleep(100);
        
        // Red steady
        set_led_color(1, 0, 0);
        msleep(400);
        
        printk(KERN_INFO "HERMES: System DISARMED (Red LED on GPIO 27)\n");
    }
    
    kfree(led_task);
}

// This function runs in IRQ context (must be quick)
static irqreturn_t touch_irq_handler(int irq, void *dev_id) {
    unsigned long flags;
    unsigned long now = jiffies;
    struct led_work *task;
    
    // Debounce: ignore touches within DEBOUNCE_MS
    if (time_before(now, last_touch_time + msecs_to_jiffies(DEBOUNCE_MS))) {
        printk(KERN_DEBUG "HERMES: Touch ignored (debounce)\n");
        return IRQ_HANDLED;
    }
    
    last_touch_time = now;
    
    printk(KERN_INFO "HERMES: Touch detected on GPIO 17!\n");
    
    // Quickly read and update state under spinlock
    spin_lock_irqsave(&state_lock, flags);
    system_armed = !system_armed;
    spin_unlock_irqrestore(&state_lock, flags);
    
    // Allocate work for deferred processing
    task = kmalloc(sizeof(struct led_work), GFP_ATOMIC);
    if (!task) {
        printk(KERN_ERR "HERMES: Failed to allocate work\n");
        return IRQ_HANDLED;
    }
    
    task->is_armed = system_armed;
    INIT_WORK(&task->work, led_blink_worker);
    
    // Queue the work to be executed later (non-blocking)
    queue_work(led_workqueue, &task->work);
    
    printk(KERN_INFO "HERMES: Touch handler done. New state: %s (queued LED update)\n",
           system_armed ? "ARMED" : "DISARMED");
    
    return IRQ_HANDLED;
}

static int __init hermes_init(void) {
    int ret;
    int leds[] = {LED_R, LED_G, LED_B};
    char *led_names[] = {"hermes_led_red", "hermes_led_green", "hermes_led_blue"};
    
    spin_lock_init(&state_lock);
    
    // Create workqueue for LED operations
    led_workqueue = create_workqueue("hermes_led");
    if (!led_workqueue) {
        printk(KERN_ERR "HERMES: Failed to create workqueue\n");
        return -ENOMEM;
    }
    
    for (int i = 0; i < 3; i++) {
        ret = gpio_request(leds[i], led_names[i]);
        if (ret) {
            printk(KERN_ERR "HERMES: Failed to request GPIO %d\n", leds[i]);
            for (int j = 0; j < i; j++) gpio_free(leds[j]);
            destroy_workqueue(led_workqueue);
            return ret;
        }
        gpio_direction_output(leds[i], 0);
    }
    
    if (!gpio_is_valid(TOUCH_GPIO)) {
        printk(KERN_ERR "HERMES: Invalid touch GPIO %d\n", TOUCH_GPIO);
        for (int i = 0; i < 3; i++) gpio_free(leds[i]);
        destroy_workqueue(led_workqueue);
        return -ENODEV;
    }
    
    ret = gpio_request(TOUCH_GPIO, "hermes_touch");
    if (ret) {
        printk(KERN_ERR "HERMES: Cannot request touch GPIO\n");
        for (int i = 0; i < 3; i++) gpio_free(leds[i]);
        destroy_workqueue(led_workqueue);
        return ret;
    }
    
    gpio_direction_input(TOUCH_GPIO);
    touch_irq_number = gpio_to_irq(TOUCH_GPIO);
    
    ret = request_irq(touch_irq_number, touch_irq_handler,
                     IRQF_TRIGGER_RISING, "hermes_touch", NULL);
    if (ret) {
        printk(KERN_ERR "HERMES: Cannot request touch IRQ\n");
        gpio_free(TOUCH_GPIO);
        for (int i = 0; i < 3; i++) gpio_free(leds[i]);
        destroy_workqueue(led_workqueue);
        return ret;
    }
    
    set_led_color(1, 0, 0);
    printk(KERN_INFO "HERMES: System ready. Touch sensor on GPIO %d.\n", TOUCH_GPIO);
    printk(KERN_INFO "HERMES: RED = Disarmed. Touch to toggle state.\n");
    printk(KERN_INFO "HERMES: Using workqueue for safe LED updates (no blocking in IRQ handler).\n");
    
    return 0;
}

static void __exit hermes_exit(void) {
    set_led_color(0, 0, 0);
    free_irq(touch_irq_number, NULL);
    gpio_free(TOUCH_GPIO);
    gpio_free(LED_R);
    gpio_free(LED_G);
    gpio_free(LED_B);
    
    // Flush and destroy workqueue
    if (led_workqueue) {
        flush_workqueue(led_workqueue);
        destroy_workqueue(led_workqueue);
        printk(KERN_INFO "HERMES: Workqueue destroyed.\n");
    }
    
    printk(KERN_INFO "HERMES: Module unloaded. All GPIOs freed.\n");
}

module_init(hermes_init);
module_exit(hermes_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Your Name");
MODULE_DESCRIPTION("HERMES Security Module - Touch Sensor with RGB LED");
MODULE_VERSION("1.0");