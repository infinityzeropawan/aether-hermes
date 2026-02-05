#!/bin/bash

echo "═══════════════════════════════════════════════"
echo "HERMES GPIO 17 Wiring Diagnostic"
echo "═══════════════════════════════════════════════"
echo ""

# Check GPIO 17 without module loaded
echo "⚠️  Make sure module is UNLOADED"
if lsmod | grep -q hermes_core; then
    echo "ERROR: Module still loaded! Unload first."
    exit 1
fi

echo "✓ Module unloaded"
echo ""

# Export GPIO 17 to userspace
echo "Exporting GPIO 17 to /sys/class/gpio..."
sudo bash -c "echo 17 > /sys/class/gpio/export" 2>/dev/null
sleep 1

# Set as input
echo "Setting GPIO 17 as input..."
sudo bash -c "echo in > /sys/class/gpio/gpio17/direction" 2>/dev/null
sleep 1

echo ""
echo "═══════════════════════════════════════════════"
echo "Monitoring GPIO 17 input value (30 seconds)"
echo "DO NOT TOUCH THE SENSOR"
echo "═══════════════════════════════════════════════"
echo ""

# Monitor the GPIO value
last_val=""
change_count=0

for i in {30..1}; do
    val=$(cat /sys/class/gpio/gpio17/value 2>/dev/null)
    
    if [ "$val" != "$last_val" ]; then
        change_count=$((change_count + 1))
        timestamp=$(date '+%H:%M:%S')
        echo "[$timestamp] GPIO 17 changed: $last_val → $val (Change #$change_count)"
        last_val=$val
    fi
    
    sleep 1
    printf "\r[Remaining: %2d seconds]" $i
done

echo ""
echo ""
echo "═══════════════════════════════════════════════"
echo "Diagnosis Results"
echo "═══════════════════════════════════════════════"
echo ""

if [ $change_count -eq 0 ]; then
    echo "✓ GPIO 17 is STABLE (no changes detected)"
    echo "  → Sensor wiring is GOOD"
    echo "  → Problem may be in module debouncing"
elif [ $change_count -lt 5 ]; then
    echo "⚠️  GPIO 17 had $change_count changes (may be electrical noise)"
    echo "  → Check sensor connections"
    echo "  → Add 100nF capacitor across sensor output"
elif [ $change_count -gt 20 ]; then
    echo "❌ GPIO 17 is TOGGLING RAPIDLY (possibly floating/floating input)"
    echo "  → Sensor may not be properly connected"
    echo "  → Check:"
    echo "    1. Sensor OUT pin connected to GPIO 17"
    echo "    2. Sensor GND connected to Pi GND"
    echo "    3. No loose wires"
    echo "    4. Try adding pull-up resistor (10k to 3.3V)"
fi

echo ""
echo "═══════════════════════════════════════════════"

# Cleanup
echo ""
echo "Cleaning up..."
sudo bash -c "echo 17 > /sys/class/gpio/unexport" 2>/dev/null

echo "✓ GPIO 17 unexported"
echo ""
echo "Next: Check wiring and reload module with ./check_status.sh"
