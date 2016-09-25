import soundcloud
import pygst
import gst

QUERY = 'girlsgeneration'
CLIENT_ID = ''
client = soundcloud.Client(client_id=CLIENT_ID)
track_url = 'http://soundcloud.com/forss/flickermood'
tracks = client.get('/tracks', q=QUERY, order='hotness', limit=1)
for track in tracks:
  print vars(track)
  stream_url = track.attachments_uri

def on_tag(bus, msg):
  taglist = msg.parse_tag()
  print 'on_tag:'
  for key in taglist.keys():
    print '\t%s = %s' % (key, taglist[key])

#our stream to play
music_stream_uri = stream_url

#creates a playbin (plays media form an uri) 
player = gst.element_factory_make("playbin", "player")

#set the uri
player.set_property('uri', music_stream_uri)

#start playing
player.set_state(gst.STATE_PLAYING)

#listen for tags on the message bus; tag event might be called more than once
bus = player.get_bus()
bus.enable_sync_message_emission()
bus.add_signal_watch()
bus.connect('message::tag', on_tag)

#wait and let the music play
raw_input('Press enter to stop playing...')
