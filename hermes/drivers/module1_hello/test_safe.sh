#!/bin/bash

# HERMES Safe Touch Sensor Test
# This version includes watchdog monitoring

echo "========================================"
echo "HERMES Touch Sensor Safe Test"
echo "========================================"
echo ""

# Verify module is loaded
if ! lsmod | grep -q hermes_core; then
    echo "ERROR: Module not loaded. Loading now..."
    sudo insmod /home/pawan/aether-hermes/hermes/drivers/module1_hello/hermes_core.ko
    sleep 2
fi

echo "✓ Module loaded"
echo ""

# Show watchdog info
echo "=== Watchdog Status ==="
if [ -c /dev/watchdog ]; then
    echo "✓ Watchdog device detected: /dev/watchdog"
else
    echo "✗ No watchdog device"
fi

# Show current system state
echo ""
echo "=== System Information ==="
echo "Kernel: $(uname -r)"
echo "Uptime: $(uptime | sed 's/.*up \([^,]*\).*/\1/')"
echo "Load: $(cat /proc/loadavg | awk '{print $1, $2, $3}')"

echo ""
echo "=== Touch Sensor Test ==="
echo "LED should be RED (Disarmed state)"
echo ""
echo "Instructions:"
echo "  1. Gently touch GPIO 17 sensor"
echo "  2. Watch for LED color changes"
echo "  3. Check kernel messages below"
echo ""
echo "Monitoring kernel messages (15 seconds)..."
echo "Press Ctrl+C to stop early"
echo ""

# Clear dmesg and start fresh
sudo dmesg -c > /dev/null

# Run the test
timeout 15 dmesg -w 2>/dev/null | grep HERMES &
MONITOR_PID=$!

# Wait for user to test
sleep 15
kill $MONITOR_PID 2>/dev/null
wait $MONITOR_PID 2>/dev/null

echo ""
echo "=== Test Results ==="
echo ""
dmesg | grep HERMES | tail -10

echo ""
echo "=== Post-Test System Check ==="
echo "System still responsive: $(date)"
echo "Load: $(cat /proc/loadavg | awk '{print $1, $2, $3}')"

# Check for any kernel errors
if dmesg | tail -50 | grep -qi "error\|panic\|oops"; then
    echo "⚠️  WARNING: Kernel errors detected!"
    dmesg | tail -20
else
    echo "✓ No kernel errors detected"
fi

echo ""
echo "Test complete. If Pi shut down, check:"
echo "  1. Watchdog timeout (kernel hung task)"
echo "  2. GPIO short circuit or power issue"
echo "  3. Sensor connectivity"
echo ""
