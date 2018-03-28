import time

import RPi.GPIO as GPIO

GPIO.setmode(GPIO.BCM)

GPIO.setup(21, GPIO.IN, pull_up_down=GPIO.PUD_DOWN)  #Button to GPIO23

try:
    while True:
         button_state = GPIO.input(21)
         if (button_state == True):

             print('Button Pressed...')
             time.sleep(0.2)

except:
    GPIO.cleanup()
