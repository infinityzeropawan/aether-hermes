# HERMES Touch Sensor - Shutdown Issue Fix

## Problem Identified
The original kernel module was **blocking the IRQ handler** by calling `msleep()` directly. This caused the system watchdog (BCM2835) to think the kernel was hung, triggering an automatic reset/shutdown.

### Root Causes:
1. **msleep() in IRQ handler**: The interrupt handler was calling sleep functions, which can block other critical kernel tasks
2. **Hardware watchdog timeout**: The BCM2835 watchdog was detecting the system hang and rebooting
3. **No workqueue deferral**: LED operations were done synchronously in the IRQ context

## Solution Implemented

### Changes Made:
✓ **Added Workqueue Architecture**:
   - Created `hermes_led` workqueue for deferred LED operations
   - IRQ handler now only updates state and queues work
   - LED animations run in non-IRQ context (can safely use msleep)

✓ **Thread-Safe State Management**:
   - Added spinlock for state variable protection
   - IRQ handler holds lock only for state update
   - Lock released before long operations

✓ **Improved Logging**:
   - Added detailed kernel messages for debugging
   - Clear indication of what's happening at each step

## Module Architecture

```
Touch Interrupt (GPIO 17)
    ↓
touch_irq_handler() [Fast - IRQ context]
    ├── Update system_armed state (with spinlock)
    ├── Allocate LED work task
    └── Queue work to workqueue
         ↓
led_blink_worker() [Slow - Can sleep]
    ├── Set LED colors
    ├── Call msleep() safely
    └── Print status messages
```

## How to Test

### Option 1: Quick Test (15 seconds)
```bash
cd /home/pawan/aether-hermes/hermes/drivers/module1_hello
./test_safe.sh
```

### Option 2: Manual Test
```bash
# 1. Ensure module is loaded
sudo insmod /home/pawan/aether-hermes/hermes/drivers/module1_hello/hermes_core.ko

# 2. Monitor kernel messages
dmesg -w | grep HERMES

# 3. In another terminal, touch the sensor
# Watch for LED changes and kernel messages

# 4. Check system stability
dmesg | tail -20  # Look for no watchdog/hung task messages
```

### Expected Behavior
1. **Initial State**: Red LED (system disarmed)
2. **First Touch**: 
   - LED blinks blue twice
   - LED turns green (system armed)
   - Kernel message: "HERMES: System ARMED"
3. **Second Touch**:
   - LED turns red (system disarmed)
   - Kernel message: "HERMES: System DISARMED"
4. **System Status**: Should NOT shut down or reboot

## Kernel Messages

Check with: `dmesg | grep HERMES`

**Normal output:**
```
[  403.117493] HERMES: System ready. Touch sensor on GPIO 17.
[  403.117508] HERMES: RED = Disarmed. Touch to toggle state.
[  403.117511] HERMES: Using workqueue for safe LED updates (no blocking in IRQ handler).
[  450.234567] HERMES: Touch detected on GPIO 17!
[  450.234600] HERMES: Touch handler done. New state: ARMED (queued LED update)
[  450.234700] HERMES: LED worker - showing ARMED sequence
[  450.235100] HERMES: System ARMED (Green LED on GPIO 22)
```

**Error indicators to watch for:**
- `Watchdog timeout` - Still blocking somewhere
- `Hung task` - IRQ handler taking too long
- `Soft lockup` - System not responsive

## Unload Module
```bash
sudo rmmod hermes_core
```

## Rebuild Module
```bash
cd /home/pawan/aether-hermes/hermes/drivers/module1_hello
make clean
make
```

## Debug Information

### GPIO Status
Check GPIO allocation:
```bash
gpioinfo gpiochip0 | grep hermes
```

### LED Control (if not using module)
```bash
# Set LED manually via sysfs
echo 1 > /sys/class/gpio/gpio27/value  # Red ON
echo 1 > /sys/class/gpio/gpio22/value  # Green ON
echo 1 > /sys/class/gpio/gpio23/value  # Blue ON
```

### Watchdog Info
```bash
# Check if watchdog is active
grep -i watchdog /proc/interrupts
ls -la /dev/watchdog*

# View watchdog logs
journalctl -u systemd-watchdog
```

## Why This Fix Works

1. **No blocking in IRQ**: The interrupt handler completes in microseconds
2. **Deferred work**: LED animations happen later in workqueue context
3. **Watchdog stays happy**: Kernel can process other tasks normally
4. **Thread-safe**: State variable protected by spinlock

This is the proper Linux kernel pattern for handling hardware interrupts with long-running operations!
