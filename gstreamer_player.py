
#!/usr/bin/env python

import sys, os
import gi
gi.require_version('Gst', '1.0')
from gi.repository import Gst, GObject, Gtk

CLIENT_ID = ''
default_stream_url = 'https://api.soundcloud.com/tracks/134204364/stream?client_id=' + CLIENT_ID

Gst.init(None)

class GTK_Player(object):

    def __init__(self,stream_url):
        print("init PLAYER with url{}".format(stream_url))
        self.player = Gst.ElementFactory.make("playbin", "player")
        self.player.set_property("uri", stream_url)
        self.start = False
        
    def start_stop(self):
        if not self.start:
            print("Start player : {}".format(self.player))
            self.player.set_state(Gst.State.PLAYING)
            self.start = True
        else:
            self.player.set_state(Gst.State.NULL)

    def on_message(self, bus, message):
        #implement later#
        pass


if __name__ == '__main__':
    player_s = GTK_Player(default_stream_url)
    player_s.start_stop()
    raw_input("Press any key to stop")