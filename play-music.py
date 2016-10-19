import socket
import subprocess

sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server_address = ('musicraspberrypi.local', 10001)
#server_address = ('192.168.2.2', 10001)
sock.bind(server_address)
sock.listen(3)
connection, addr = sock.accept()
stream_url = 'http://www.stephaniequinn.com/Music/Commercial%20DEMO%20-%2009.mp3'
music_process = False
while True:
    global music_process
    line = connection.recv(999)
    if line:
        print('line')
        print(line)
        if 'stop' in line:           
            if music_process:
                music_process.terminate()
        else:
            stream_url = line
            if music_process:
                music_process.terminate()
            music_process = subprocess.Popen(['gst-launch-1.0', 'playbin', 'uri={}'.format(stream_url)], stdout=subprocess.PIPE)