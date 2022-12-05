require 'bencode'
require 'digest/sha1'
require 'socket'
require 'cgi'

# This program is used to test for messages sending, receiving and parsing
# First run bit.rb, then run this program as ruby bit.rb

def keepAliveMessage                            # <len=0000>
    "\x00\x00\x00\x00"
end

def chokeMessage                                # <len=0001><id=0>
    "\x00\x00\x00\x01\x00"
end

def unchokeMessage                              # <len=0001><id=1>
    "\x00\x00\x00\x01\x01"
end

def interestedMessage                           # <len=0001><id=2>
    "\x00\x00\x00\x01\x02"
end

def notInterestedMessage                        # <len=0001><id=3>
    "\x00\x00\x00\x01\x03"
end
# TODO: weird performance with length in send
def haveMessage(id)                             # <len=0005><id=4><piece index>
    id = [id].pack('N')
    "\x00\x00\x00\x05\x04#{id}"
end

def bitfieldMessage(bitArray)                   # <len=0001+X><id=5><bitfield>
    len = (bitArray.length.to_f/8).ceil + 1
    m_bitfield = "#{[len].pack('N')}\x05"
    #pad the bitfield with 0 at the end
    numPad = 8 - bitArray.length.modulo(8)
    b = bitArray.join()
    for i in 1..numPad
        b += "0"
    end
    b = b.to_s.scan(/.{8}/)
    for i in 0..(b.length - 1)
        tmp = [b[i].to_i(2)]
        m_bitfield += tmp.pack('C')
    end
    m_bitfield
end

def requestMessage(id, beg, len)                # <len=0013><id=6><index><begin><length>
    id = [id].pack('N')
    beg = [beg].pack('N')
    len = [len].pack('N')
    "\x00\x00\x00\x0d\x06#{id}#{beg}#{len}"
end

# TODO: pieceMessage

def cancelMessage(id, beg, len)                 # <len=0013><id=8><index><begin><length>
    id = [id].pack('N')
    beg = [beg].pack('N')
    len = [len].pack('N')
    "\x00\x00\x00\x0d\x08#{id}#{beg}#{len}"
end

def portMessage(port)                           # <len=0003><id=9><listen-port>
    port = [port].pack('n')
    "\x00\x00\x00\x03\x09#{port}"
end

cSock = TCPSocket.open("127.0.0.1", 2000)

test = keepAliveMessage
cSock.write(test)
test = chokeMessage
cSock.write(test)
test = unchokeMessage
cSock.write(test)
test = interestedMessage
cSock.write(test)
test = notInterestedMessage
cSock.write(test)
test = haveMessage(3)
cSock.write(test)
test = bitfieldMessage([1,1,1,1,1,1,1,1,1])
cSock.write(test)
test = requestMessage(1, 0, 128)
cSock.write(test)
#TODO: piece
test = cancelMessage(1, 0, 128)
cSock.write(test)
test = portMessage(2000)
cSock.write(test)

cSock.close

