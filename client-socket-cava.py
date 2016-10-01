import socket
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server_address = ('192.168.2.3', 10000)
server_address = ('localhost', 10000)
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
sock.connect(server_address)
sock.sendall('1;1;1;1;1;1;1;1;1;1;1;1;')

# for i in range(20):
#     time.sleep(0.1)
#     sock.sendall('1;1;{};1;1;1;1;7;5;1;1;1;'.format(i+1))

while True:
    with open('/tmp/cava', 'r', 0) as cava:
            line = cava.readline()
            sock.sendall(line)
    time.sleep(0.1)
