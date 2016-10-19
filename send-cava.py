import socket
import time
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server_address = ('ledraspberrypi.local', 10000)
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
sock.connect(server_address)
sock.sendall('1;1;1;1;1;1;1;1;1;1;1;1;')

with open('/tmp/cava', 'r', 0) as cava:
    while True:    
            line = cava.readline()
            print(line)
            sock.sendall(line)
            time.sleep(0.08)