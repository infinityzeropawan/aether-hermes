#!/bin/bash
# Author: Pawan kumar dubey
echo "=== HERMES Module Test ==="
echo "1. Building module..."
make

echo "2. Loading module..."
sudo insmod hermes_core.ko

echo "3. Checking kernel messages..."
dmesg | tail -10

echo "4. Module info:"
modinfo hermes_core.ko

echo "5. Touch the sensor now!"
echo "   Watch LED: Red -> Touch -> Blue blink -> Green"
echo "   Check: dmesg | tail -5"

echo "6. To unload: sudo rmmod hermes_core"