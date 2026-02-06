#!/bin/bash
# Author: Pawan kumar dubey
# Quick status check script
echo "╔════════════════════════════════════════╗"
echo "║  HERMES Module Status Checker          ║"
echo "╚════════════════════════════════════════╝"
echo ""

# Check module status
echo "📌 Module Status:"
if lsmod | grep -q hermes_core; then
    echo "   ✓ hermes_core loaded"
    lsmod | grep hermes_core
else
    echo "   ✗ hermes_core NOT loaded"
    echo "   Loading now..."
    sudo insmod /home/pawan/aether-hermes/hermes/drivers/module1_hello/hermes_core.ko
    sleep 1
fi

echo ""
echo "📌 GPIO Allocation:"
gpioinfo gpiochip0 2>/dev/null | grep hermes || echo "   (gpioinfo not available)"

echo ""
echo "📌 Recent Kernel Messages (HERMES):"
dmesg | grep HERMES | tail -5

echo ""
echo "📌 Watchdog Status:"
if [ -c /dev/watchdog ]; then
    echo "   ✓ Watchdog device active: /dev/watchdog"
else
    echo "   ✗ No watchdog device found"
fi

echo ""
echo "📌 System Load:"
uptime

echo ""
echo "📌 Test Options:"
echo "   1. Quick test (15s):    ./test_safe.sh"
echo "   2. Full debug test:     ./debug_touch.sh"
echo "   3. Manual monitoring:   dmesg -w | grep HERMES"
echo ""
