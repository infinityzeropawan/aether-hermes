#!/bin/bash

echo "========================================="
echo "   HERMES Touch Sensor Test Suite"
echo "========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ $2${NC}"
    else
        echo -e "${RED}✗ $2${NC}"
    fi
}

# Check 1: Module loaded
echo -e "${BLUE}[1] Checking if module is loaded...${NC}"
if lsmod | grep -q hermes_core; then
    print_status 0 "Module loaded"
else
    print_status 1 "Module NOT loaded - loading now..."
    sudo insmod /home/pawan/aether-hermes/hermes/drivers/module1_hello/hermes_core.ko
    sleep 1
fi

# Check 2: GPIO allocation
echo -e "\n${BLUE}[2] Checking GPIO allocation...${NC}"
if gpioinfo gpiochip0 2>/dev/null | grep -q "hermes_touch"; then
    print_status 0 "GPIO 17 (Touch) allocated"
else
    print_status 1 "GPIO 17 (Touch) NOT allocated"
fi

if gpioinfo gpiochip0 2>/dev/null | grep -q "hermes_led_red"; then
    print_status 0 "GPIO 27 (Red LED) allocated"
else
    print_status 1 "GPIO 27 (Red LED) NOT allocated"
fi

if gpioinfo gpiochip0 2>/dev/null | grep -q "hermes_led_green"; then
    print_status 0 "GPIO 22 (Green LED) allocated"
else
    print_status 1 "GPIO 22 (Green LED) NOT allocated"
fi

if gpioinfo gpiochip0 2>/dev/null | grep -q "hermes_led_blue"; then
    print_status 0 "GPIO 23 (Blue LED) allocated"
else
    print_status 1 "GPIO 23 (Blue LED) NOT allocated"
fi

# Check 3: IRQ status
echo -e "\n${BLUE}[3] Checking IRQ assignment...${NC}"
cat /proc/interrupts | grep gpio

# Check 4: Kernel messages
echo -e "\n${BLUE}[4] Recent kernel messages (last 5 HERMES lines)...${NC}"
dmesg | grep HERMES | tail -5

# Check 5: GPIO Input state
echo -e "\n${BLUE}[5] GPIO Input State${NC}"
gpio_value=$(cat /sys/class/gpio/gpio17/value 2>/dev/null)
if [ -z "$gpio_value" ]; then
    echo -e "${YELLOW}GPIO 17 value: Not directly accessible (kernel module is using it)${NC}"
    echo "This is expected - the kernel module manages the GPIO directly."
else
    echo "GPIO 17 (Touch) value: $gpio_value"
fi

# Check 6: Instructions for testing
echo -e "\n${BLUE}[6] Testing Instructions${NC}"
echo -e "${YELLOW}The system is now monitoring GPIO 17 for touch events.${NC}"
echo ""
echo "Follow these steps to test:"
echo "1. Check the LED status - should be RED initially (system disarmed)"
echo "2. Gently touch the sensor connected to GPIO 17"
echo "3. Watch for LED changes:"
echo "   - First touch: LED should blink BLUE twice, then turn GREEN (system ARMED)"
echo "   - Second touch: LED should turn RED (system DISARMED)"
echo "4. Check kernel messages:"
echo "   Run: dmesg | tail -10"
echo "5. You should see messages like:"
echo "   'HERMES: Touch detected! Changing state.'"
echo "   'HERMES: System ARMED (Green LED)' or 'HERMES: System DISARMED (Red LED)'"
echo ""

# Check 7: Real-time monitoring
echo -e "${BLUE}[7] Starting real-time kernel message monitoring...${NC}"
echo -e "${YELLOW}Touch the sensor now (Ctrl+C to stop)${NC}"
echo ""
dmesg -w | grep HERMES &
DMESG_PID=$!

# Give user time to test
sleep 15

# Kill the monitoring
kill $DMESG_PID 2>/dev/null
wait $DMESG_PID 2>/dev/null

echo ""
echo -e "${BLUE}[8] Test Summary${NC}"
echo -e "${GREEN}Module is ready for testing!${NC}"
echo "If you didn't see touch events, check:"
echo "  1. Physical connection to GPIO 17"
echo "  2. Pull-up/pull-down configuration on the sensor"
echo "  3. Sensor voltage levels (should be 3.3V for Raspberry Pi)"
echo ""
echo "To unload module: sudo rmmod hermes_core"
echo ""
