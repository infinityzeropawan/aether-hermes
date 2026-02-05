# HERMES Touch Sensor & LED Wiring Diagram

**Author: Pawan kumar dubey**

## GPIO Pin Assignments

| Component | GPIO Pin | BCM | Physical Pin |
|-----------|----------|-----|--------------|
| Touch Sensor | 17 | GPIO17 | Pin 11 |
| Red LED | 27 | GPIO27 | Pin 13 |
| Green LED | 22 | GPIO22 | Pin 15 |
| Blue LED | 23 | GPIO23 | Pin 16 |

## Raspberry Pi 5 Pinout (Relevant Pins)

```
PIN LAYOUT (Top View):
        +3.3V          GND
         ↓              ↓
    ┌────────────────────────┐
    │ 1(3.3V)   2(5V)        │
    │ 3(GPIO2)  4(5V)        │
    │ 5(GPIO3)  6(GND)       │
    │ 7(GPIO4)  8(GPIO14)    │
    │ 9(GND)   10(GPIO15)    │
    │11(GPIO17)12(GPIO18)    │ ← GPIO17 (TOUCH)
    │13(GPIO27)14(GND)       │ ← GPIO27 (RED LED)
    │15(GPIO22)16(GPIO23)    │ ← GPIO22 (GREEN), GPIO23 (BLUE)
    │17(3.3V)  18(GPIO24)    │
    │19(GPIO10)20(GND)       │
    └────────────────────────┘
```

## Complete Wiring Diagram

### Touch Sensor (GPIO 17)
```
Touch Sensor Module
    ┌─────────────────┐
    │  GND  OUT  VCC  │
    │   │    │    │   │
    └───┼────┼────┼───┘
        │    │    │
        │    │    └─── 3.3V (Pin 1 or 17)
        │    │
        │    └─────────── GPIO 17 (Pin 11)
        │
        └─────────────── GND (Pin 6, 9, 14, 20, 25, 30)
```

**Connections:**
- Touch VCC → Raspberry Pi 3.3V (Pin 1 or 17)
- Touch OUT → GPIO 17 (Pin 11) 
- Touch GND → Ground (Pin 6, 9, 14, 20, 25, or 30)

---

### RGB LED Module

#### Option 1: Common Cathode RGB LED (Most Common)
```
RGB LED (Common Cathode)
    ┌─────────────────┐
    │ R  G  K  B      │
    │ │  │  │  │      │
    └─┼──┼──┼──┼──────┘
      │  │  │  │
      │  │  │  └─ Blue (GPIO 23, Pin 16)
      │  │  │
      │  │  └────── Common Cathode GND (Pin 6, 9, 14, 20, 25, 30)
      │  │
      │  └────────── Green (GPIO 22, Pin 15)
      │
      └──────────── Red (GPIO 27, Pin 13)
```

**Wiring for Common Cathode:**
- Red LED → GPIO 27 (Pin 13)
- Green LED → GPIO 22 (Pin 15)
- Blue LED → GPIO 23 (Pin 16)
- Common Cathode → GND (Pin 6, 9, 14, 20, 25, or 30)

#### Option 2: Common Anode RGB LED
```
RGB LED (Common Anode)
    ┌─────────────────┐
    │ R  G  K  B      │
    │ │  │  │  │      │
    └─┼──┼──┼──┼──────┘
      │  │  │  │
      │  │  │  └─ Blue → GND (with resistor)
      │  │  │
      │  │  └────── Common Anode VCC (3.3V)
      │  │
      │  └────────── Green → GND (with resistor)
      │
      └──────────── Red → GND (with resistor)
```

**Note:** Common Anode requires software inversion (not currently implemented)

---

## Resistor Requirements

**For each LED output, use a current-limiting resistor:**

### For 3.3V GPIO (Raspberry Pi):
| LED Color | Forward Voltage | Recommended Resistor |
|-----------|-----------------|----------------------|
| Red | 1.8-2.0V | 330Ω - 470Ω |
| Green | 3.0-3.2V | 100Ω - 150Ω |
| Blue | 3.2-3.4V | 100Ω - 150Ω |

### Resistor Placement:
```
For Common Cathode (Recommended):

GPIO 27 (Red)    ──[330Ω]──○ Red LED Anode
GPIO 22 (Green)  ──[150Ω]──○ Green LED Anode
GPIO 23 (Blue)   ──[150Ω]──○ Blue LED Anode
GND              ─────────────○ Common Cathode
```

---

## Complete Assembly Diagram

```
RASPBERRY PI 5                    TOUCH SENSOR
┌────────────────┐                ┌─────────────┐
│  3.3V(1,17)────┼────────────────│ VCC         │
│  GPIO17(11)────┼────────────────│ OUT         │
│  GPIO27(13)────┼─[330Ω]─────────│ Red Anode   │
│  GPIO22(15)────┼─[150Ω]────────╱             │
│  GPIO23(16)────┼─[150Ω]────────│ Green Anode │
│  GND(6,9,14...)─┼─────────────┬─│ Blue Anode  │
│                │             │ │ Common CK   │
│                │             │ └─────────────┘
│                │             │
│                │             └──── RGB LED
└────────────────┘
```

---

## Step-by-Step Connection Guide

### 1. Touch Sensor Connection
- [ ] Connect sensor VCC to Pin 1 (3.3V)
- [ ] Connect sensor OUT to Pin 11 (GPIO 17)
- [ ] Connect sensor GND to Pin 6 or 9 (GND)

### 2. Red LED (GPIO 27)
- [ ] Insert 330Ω resistor in series
- [ ] Connect resistor to GPIO 27 (Pin 13)
- [ ] Connect LED anode to resistor
- [ ] Connect LED cathode to GND

### 3. Green LED (GPIO 22)
- [ ] Insert 150Ω resistor in series
- [ ] Connect resistor to GPIO 22 (Pin 15)
- [ ] Connect LED anode to resistor
- [ ] Connect LED cathode to GND

### 4. Blue LED (GPIO 23)
- [ ] Insert 150Ω resistor in series
- [ ] Connect resistor to GPIO 23 (Pin 16)
- [ ] Connect LED anode to resistor
- [ ] Connect LED cathode to GND

### 5. Power & Ground
- [ ] Verify all GND connections are to same ground rail
- [ ] Verify 3.3V connections are stable

---

## Testing Connections

### Before Loading Module:
```bash
# Export GPIO pins to sysfs
echo 17 > /sys/class/gpio/export
echo 27 > /sys/class/gpio/export
echo 22 > /sys/class/gpio/export
echo 23 > /sys/class/gpio/export

# Set as outputs
echo out > /sys/class/gpio/gpio27/direction
echo out > /sys/class/gpio/gpio22/direction
echo out > /sys/class/gpio/gpio23/direction
echo in > /sys/class/gpio/gpio17/direction

# Test Red LED
echo 1 > /sys/class/gpio/gpio27/value  # RED ON
sleep 1
echo 0 > /sys/class/gpio/gpio27/value  # RED OFF

# Test Green LED
echo 1 > /sys/class/gpio/gpio22/value  # GREEN ON
sleep 1
echo 0 > /sys/class/gpio/gpio22/value  # GREEN OFF

# Test Blue LED
echo 1 > /sys/class/gpio/gpio23/value  # BLUE ON
sleep 1
echo 0 > /sys/class/gpio/gpio23/value  # BLUE OFF
```

### With Module Loaded:
```bash
# Module will control GPIOs directly
dmesg | grep HERMES  # Verify module loaded

# Watch for LED changes when touching sensor
dmesg -w | grep HERMES
```

---

## Common Issues & Solutions

### LEDs Don't Light Up
1. ❌ Check polarity (cathode to GND, anode to GPIO via resistor)
2. ❌ Verify resistor values (not too high)
3. ❌ Test with manual GPIO control first
4. ❌ Check GPIO pin mapping in code

### LEDs Too Dim
1. ↓ Reduce resistor value (200Ω → 100Ω)
2. ⚠️ Don't go below 100Ω for 3.3V GPIO

### LEDs Too Bright
1. ↑ Increase resistor value (150Ω → 330Ω)

### Touch Sensor Not Working
1. Verify sensor is on GPIO 17 (Pin 11)
2. Check VCC voltage (should be 3.3V)
3. Test sensor output with multimeter
4. Try sensor with pull-up: `echo "high" > /sys/class/gpio/gpio17/direction`

### Module Doesn't Load
1. Check kernel version: `uname -r`
2. Verify GPIO availability: `gpioinfo gpiochip0`
3. Check for conflicts: `grep gpio /proc/interrupts`

---

## Power Consumption

### Typical GPIO Current Draw:
- GPIO Output (HIGH): ~2-4mA per pin
- GPIO Input: <1mA

### LED Current (with resistors):
- Red LED: ~5mA
- Green LED: ~5mA
- Blue LED: ~5mA
- **Total: ~15mA max** ✓ Safe for Raspberry Pi GPIO

---

## Schematic (Simplified)

```
3.3V ──┬─────────────────────────── Touch Sensor VCC
       │
       │
GND ───┼─────┬─[R]─○─ Red LED
       │     │
       │     ├─[R]─○─ Green LED
       │     │
       │     ├─[R]─○─ Blue LED
       │     │
       │     └───── Touch Sensor GND & Common Cathode
       │
       │
GPIO17─┴───────────── Touch Sensor OUT
GPIO27─────[R]──────- Red LED Anode
GPIO22─────[R]──────- Green LED Anode
GPIO23─────[R]──────- Blue LED Anode


Legend: [R] = Current Limiting Resistor
        ○ = LED
```

---

## PIN Reference TABLE

```
GPIO Pin | Pin # | Label | Connected To | Direction
---------|-------|-------|--------------|----------
GPIO17   | 11    | BCM17 | Touch Sensor  | Input
GPIO27   | 13    | BCM27 | Red LED       | Output
GPIO22   | 15    | BCM22 | Green LED     | Output
GPIO23   | 16    | BCM23 | Blue LED      | Output
3.3V     | 1,17  | 3V3   | Touch VCC     | -
GND      | 6,9.. | GND   | All Commons   | -
```

---

## Verification Checklist

- [ ] All 4 GPIO pins connected correctly
- [ ] Resistors installed in series with each LED
- [ ] LED polarity correct (anode to GPIO, cathode to GND)
- [ ] Touch sensor VCC on 3.3V rail
- [ ] Touch sensor OUT on GPIO 17
- [ ] All GND connections to same ground
- [ ] No shorts between adjacent pins
- [ ] Manual GPIO test passes
- [ ] Module loads without errors
- [ ] Touch detection works

**Status:** ✓ Ready to test with HERMES module!
