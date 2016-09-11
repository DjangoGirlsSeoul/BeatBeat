import soundcloud

QUERY = 'girlsgeneration'
CLIENT_ID = '' 
client = soundcloud.Client(client_id=CLIENT_ID)
tracks = client.get('/tracks', q=QUERY, order='hotness', limit=1)
for track in tracks:
  print track.stream_url

