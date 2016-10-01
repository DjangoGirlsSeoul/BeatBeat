#!/usr/bin/env python
# encoding: utf-8

from samplebase import SampleBase
import sys
import socket

class Visualizer(SampleBase):
        def __init__(self, *args, **kwargs):
                super(Visualizer, self).__init__(*args, **kwargs)

        def Run(self):
            a = 1
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
#            server_address = ('192.168.2.3', 10000)
            server_address = ('localhost', 10000)
            sock.bind(server_address)
            sock.listen(1)
            connection, addr = sock.accept()
            while True:
                line = connection.recv(999)
                if line:
                        print(line)
                        intensity_array = line.split(';')
                        if len(intensity_array) < 10:
                                print('broken')
                                break
                        a = a + 1
                        print(a, intensity_array)
                        offsetCanvas = self.matrix.CreateFrameCanvas()
                        for index, intensity in enumerate(intensity_array[:-1]):
                                for x in range(0, int(intensity)):
                                        offsetCanvas.SetPixel(index, x + 2, 255,255,255)
                        offsetCanvas = self.matrix.SwapOnVSync(offsetCanvas)

if __name__ == '__main__':
        parser = Visualizer()
        if (not parser.process()):
                parser.print_help()
