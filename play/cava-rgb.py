#!/usr/bin/env python
# encoding: utf-8
 
from samplebase import SampleBase
import sys
 
class Visualizer(SampleBase):
    def __init__(self, *args, **kwargs):
        super(Visualizer, self).__init__(*args, **kwargs)
 
    def Run(self):
        for line in sys.stdin:
            offsetCanvas = self.matrix.CreateFrameCanvas()
            intensity_array = line.split(';')
            for index, intensity  in enumerate(intensity_array[:-1]):
                for x in range(0, int(intensity)):
                    offsetCanvas.SetPixel(index, x + 2, 255,255,255)
            offsetCanvas = self.matrix.SwapOnVSync(offsetCanvas)
            self.usleep(1 * 1000)      
 
if __name__ == '__main__':
    parser = Visualizer()
    if (not parser.process()):
        parser.print_help()
