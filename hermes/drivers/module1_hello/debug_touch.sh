#!/bin/bash
# Author: Pawan kumar dubey
# HERMES Touch Sensor Debug & Test Script
# This script will monitor all system activity while testing the touch sensor

echo "======================================"
echo "HERMES Touch Sensor Debug Test"
echo "======================================"
echo ""

# Create a temporary log file to capture everything
DEBUG_LOG="/tmp/hermes_debug_$(date +%s).log"
echo "Debug log will be saved to: $DEBUG_LOG"
echo ""

# Function to log messages
log_msg() {
    echo "[$(date '+%H:%M:%S')] $1" | tee -a "$DEBUG_LOG"
}

log_msg "Starting HERMES debug test..."
log_msg "Module status:"
lsmod | grep hermes_core | tee -a "$DEBUG_LOG"

# Check watchdog
log_msg ""
log_msg "=== Checking Watchdog Status ==="
if [ -f /dev/watchdog ]; then
    log_msg "⚠️  Watchdog device found at /dev/watchdog"
    ls -la /dev/watchdog* 2>/dev/null | tee -a "$DEBUG_LOG"
else
    log_msg "✓ No watchdog device found"
fi

# Check system journal for any power-related events
log_msg ""
log_msg "=== Recent System Events ==="
journalctl --no-pager -n 20 2>/dev/null | tee -a "$DEBUG_LOG"

# Start monitoring kernel messages in background
log_msg ""
log_msg "=== Starting kernel message monitoring ==="
dmesg -w 2>/dev/null | while read line; do
    log_msg "KERNEL: $line"
done &
DMESG_PID=$!

# Start monitoring system journal in background
journalctl -f 2>/dev/null | while read line; do
    log_msg "JOURNAL: $line"
done &
JOURNAL_PID=$!

log_msg ""
log_msg "=== GPIO State Before Touch ==="
gpio readall 2>/dev/null | head -20 | tee -a "$DEBUG_LOG" || log_msg "gpio readall not available"

log_msg ""
log_msg "=== Ready for testing! ==="
log_msg "Instructions:"
log_msg "1. LED should be RED initially (disarmed state)"
log_msg "2. Gently touch sensor on GPIO 17"
log_msg "3. Watch for LED changes and kernel messages"
log_msg "4. Press Ctrl+C to stop test and save logs"
log_msg ""
log_msg "Test duration: 30 seconds"
log_msg "Touch the sensor NOW if you want to test!"
log_msg ""

# Wait for 30 seconds, monitoring everything
for i in {30..1}; do
    sleep 1
    printf "\r[%02d seconds remaining]" $i
done

echo ""
log_msg ""
log_msg "=== Test Complete ==="
log_msg "Stopping monitors..."

# Kill monitoring processes
kill $DMESG_PID 2>/dev/null
kill $JOURNAL_PID 2>/dev/null
wait $DMESG_PID 2>/dev/null
wait $JOURNAL_PID 2>/dev/null

# Get final GPIO state
log_msg ""
log_msg "=== GPIO State After Test ==="
gpio readall 2>/dev/null | head -20 | tee -a "$DEBUG_LOG" || log_msg "gpio readall not available"

# Get LED status
log_msg ""
log_msg "=== LED Status ==="
log_msg "Checking LED GPIO values..."
for led_num in 27 22 23; do
    if [ -d "/sys/class/gpio/gpio${led_num}" ]; then
        val=$(cat "/sys/class/gpio/gpio${led_num}/value" 2>/dev/null)
        log_msg "GPIO $led_num (LED): $val"
    fi
done

# Summary
log_msg ""
log_msg "=== Debug Information ==="
log_msg "System uptime:"
uptime | tee -a "$DEBUG_LOG"

log_msg ""
log_msg "Current system load:"
cat /proc/loadavg | tee -a "$DEBUG_LOG"

log_msg ""
log_msg "System clock:"
date | tee -a "$DEBUG_LOG"

log_msg ""
log_msg "=== Test Complete ==="
log_msg "Full debug log saved to: $DEBUG_LOG"
log_msg ""
log_msg "Review the log for any anomalies related to:"
log_msg "  - Watchdog timeouts"
log_msg "  - Power management events"
log_msg "  - Reboot requests"
log_msg "  - Kernel panics"
log_msg ""
echo "Debug log: $DEBUG_LOG"
echo ""
echo "To view the debug log:"
echo "  cat $DEBUG_LOG"
echo ""
echo "To search for errors:"
echo "  grep -i 'error\|warning\|reset\|reboot\|shutdown' $DEBUG_LOG"
