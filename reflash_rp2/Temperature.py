#!/usr/bin/python3
import serial
import psutil
import time

#SERIAL_PORT = '/dev/ttyS0'
SERIAL_PORT = '/dev/ttyS4'
BAUD_RATE = 115200

set = serial.Serial(SERIAL_PORT, BAUD_RATE)

def get_cpu_temperature():
    # get temperature from PC
    temps = psutil.sensors_temperatures()
    if 'coretemp' in temps:
        cpu_temp = temps['coretemp'][0].current
        return cpu_temp
    else:
        return None

try:
    while True:
        temp = get_cpu_temperature()
        if temp is not None:
            print(f"CPU Temperature: {temp}°C")
            set.write(f"{temp}\n".encode())
        else:
            print("Unable to read temperature.")
        time.sleep(1)
except KeyboardInterrupt:
    set.close()
    print("Program terminated.")
