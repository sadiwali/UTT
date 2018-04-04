import os, signal
import time
import RPi.GPIO as GPIO

GPIO.setmode(GPIO.BCM)
GPIO.setup(21, GPIO.IN, pull_up_down = GPIO.PUD_UP)

playing = 0 # is music playing?


def kill_proc(proc_name: 'str') -> None:
    ''' Given a process name, kill all instances of it '''
    # get all processes with process name
    for line in os.popen('ps ax | grep ' + proc_name + ' | grep -v grep'):
        pid = line.split()[0] # get the pid for each process
        os.kill(int(pid), signal.SIGKILL) # issue kill signal (kills process)

def play() -> None:
    ''' Play music if not already playing '''
    global playing
    playing = 1 
    print('playing')
    os.system('omxplayer -o local music.mp3 &') # system command

def stop() -> None:
    ''' Stop music if playing '''
    global playing
    playing = 0
    print('stopping')
    # kill the process and sub process
    kill_proc('omxplayer.bin') 
    kill_proc('omxplayer')

if __name__ == '__main__':
    while True:
        # infinite loop
        inval = GPIO.input(21)
        if (inval):
            # play if not playing
            if not playing:
                play()
        else:
            # stop if playing
            if playing:
                stop()
        # increase this to slow down checking and free up processing power
        time.sleep(0.1)
