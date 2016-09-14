import pyaudio
from pydub import AudioSegment
import sounddevice as sd
import numpy as np
# sd.default.samplerate = 44100
import matplotlib as mpl
mpl.use('TkAgg') 
import matplotlib.pyplot as plt
# from matplotlib.animation import FuncAnimation
import matplotlib.animation as animation
from queue import LifoQueue, Queue, Empty

queue = LifoQueue()

# song = AudioSegment.from_file('1.mp3')
song = AudioSegment.from_file('clip.m4a')
frame_rate = song.frame_rate

song_array = np.frombuffer(song.raw_data, dtype=np.int32)

def callback(indata, outdata, frames, time, status):
    global song_array
    if len(song_array) > frames:
        new_output = song_array[0:frames]
        song_array = np.delete(song_array, range(0,frames))
        new_outdata = new_output.reshape((frames, 1))
        queue.put(new_output)
        outdata[:] = new_outdata
    else:
        raise sd.CallbackStop

stream = sd.Stream(dtype=np.int32, channels=1, samplerate=frame_rate, callback=callback)

stream.start()

def animate(frame):
    global plotdata
    block = True  # The first read from the queue is blocking ...
    while True:
        try:
            data = queue.get(block=block)
        except Empty:
            break
        shift = len(data)
        plotdata = np.roll(plotdata, -shift, axis=0)
        plotdata[-shift:] = data
        block = False  # ... all further reads are non-blocking
    for column, line in enumerate(lines):
        line.set_ydata(plotdata)
    return lines

plotdata = np.zeros(4096)
fig, ax = plt.subplots()
lines = ax.plot(plotdata)
# ax.axis((0, len(plotdata), -1, 1))
# ax.set_yticks([0])
# ax.yaxis.grid(True)
# ax.tick_params(bottom='off', top='off', labelbottom='off',
#                right='off', left='off', labelleft='off')
fig.tight_layout(pad=0)

ani = animation.FuncAnimation(fig, animate, interval=500, blit=False)

with stream:
    plt.show()
