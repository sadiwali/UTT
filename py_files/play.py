import os, signal
import time
import RPi.GPIO as GPIO

GPIO.setmode(GPIO.BCM)
GPIO.setup(21, GPIO.IN, pull_up_down = GPIO.PUD_UP)

playing = 0 # is music playing?


def kill_proc(pstring):
    for line in os.popen('ps ax | grep ' + pstring + ' | grep -v grep'):
        fields = line.split()
        pid = fields[0]
        os.kill(int(pid), signal.SIGKILL)

def play():
    global playing
    playing = 1 
    print('playing')
    os.system('omxplayer -o local music.mp3 &')

def stop():
    global playing
    playing = 0
    print('stopping')
    kill_proc('omxplayer.bin') 
    kill_proc('omxplayer')



while True:
    inval = GPIO.input(21)
    if (inval):
        # play if not playing
        if not playing:
            play()
    else:
        # stop if playing
        if playing:
            stop()
    time.sleep(0.3)

