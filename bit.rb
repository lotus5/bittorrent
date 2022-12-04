require 'bencode'
require 'digest/sha1'
require 'socket'
require 'cgi'

# call the program with ruby bit.rb <filename.torrent> <1 for compact, 0 for noncompact>
# pieces_hash is an array of hashes for each piece of the file
# peerState is an array: [[socket, am_choking, am_interested, peer_choking, peer_interested]]
# bitField is an array with length of numPiece, initialized with all 0

# fields for peerState
SOCKET = 0
AMCHOKING = 1
AMINTERESTED = 2
PEERCHOKING = 3
PEERINTERESTED = 4

# message functions for peer communication
# all functions have the return value format of [message, length_of_message]
def keepAliveMessage                            # <len=0000>
    ["\x00\x00\x00\x00", 4]
end

def chokeMessage                                # <len=0001><id=0>
    ["\x00\x00\x00\x01\x00", 5]
end

def unchokeMessage                              # <len=0001><id=1>
    ["\x00\x00\x00\x01\x01", 5]
end

def interestedMessage                           # <len=0001><id=2>
    ["\x00\x00\x00\x01\x02", 5]
end

def notInterestedMessage                        # <len=0001><id=3>
    ["\x00\x00\x00\x01\x03", 5]
end
# TODO: weird performance with length in send
def haveMessage(id)                             # <len=0005><id=4><piece index>
    id = [id].pack('N')
    m_have = "\x00\x00\x00\x05\x04#{id}"
    [m_have, 9]     #----> should have length of 9(len:4 + id:1 + index:4)
    #[m_have, 16]    #----> the send socket won't take anything under 16 as length for sending this message.
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
    [m_bitfield, (len + 4)]
end

def requestMessage(id, beg, len)                # <len=0013><id=6><index><begin><length>
    id = [id].pack('N')
    beg = [beg].pack('N')
    len = [len].pack('N')
    m_req = "\x00\x00\x00\x0d\x06#{id}#{beg}#{len}"
    [m_req, 17]
end

# TODO: pieceMessage

def cancelMessage(id, beg, len)                 # <len=0013><id=8><index><begin><length>
    id = [id].pack('N')
    beg = [beg].pack('N')
    len = [len].pack('N')
    m_req = "\x00\x00\x00\x0d\x08#{id}#{beg}#{len}"
    [m_req, 17]
end

def portMessage(port)                           # <len=0003><id=9><listen-port>
    port = [port].pack('n')
    m_port = "\x00\x00\x00\x03\x09#{port}"
    [m_port, 7]
end

def generatePeerID()
    x = [*'a'..'z', *'A'..'Z', *0..9]
    x = x.shuffle
    x = x.slice(0..19)
    x.join
end

# Parsing the message from other peers
def parseResponse(s)
    len = s.read(4).unpack('N')[0]
        p "message length: #{len}"
    if len == 0
        # received a keep alive message
        p "received a keep alive message"
    else
        mId = s.read(1).unpack('C')[0]
        p "message id: #{mId}"
        if mId == 0
            # received a choke message
            p "received a choke message"
        elsif mId == 1
            # received an unchoke message
            p "received an unchoke message"
        elsif mId == 2
            # received an interested message
            p "received an interested message"
        elsif mId == 3
            # received a not interested message
            p "received a not interested message"
        elsif mId == 4
            # received a have message
            p "received a have message"
            pieceId = s.read(4).unpack('N')
            p "Peer have pieceId: #{pieceId}"
        elsif (mId == 5)
            # received a bitfield message
            p "received a bitfield message"
            recvBF = s.read(len - 1).bytes.each_slice(6).to_a()[0]
            for i in 0..(recvBF.length - 1)
                recvBF[i] = recvBF[i].to_s(2)
            end
            recvBF = recvBF.join("")
            p "bitfield received: #{recvBF}"
        elsif mId == 6
            # received a request message
            p "received a request message"
            pId = s.read(4).unpack('N')[0]
            pBeg = s.read(4).unpack('N')[0]
            pLen = s.read(4).unpack('N')[0]
            p "pieceId: #{pId}, begin: #{pBeg}, length: #{pLen}"
        elsif mId == 7
            # received a piece message
            p "received a piece message"
        elsif mId == 8
            # received a cancel message
            p "received a cancel message"
            pId = s.read(4).unpack('N')[0]
            pBeg = s.read(4).unpack('N')[0]
            pLen = s.read(4).unpack('N')[0]
            p "pieceId: #{pId}, begin: #{pBeg}, length: #{pLen}"
        elsif mId == 9
            # received a port message
            p "received a port message"
            port = s.read(2).unpack('n')[0]
            p "port: #{port}"
        end
    end
end

# Parsing the torrent file
meta = BEncode.load_file(ARGV[0])
compact = ARGV[1]
info_hash = Digest::SHA1.digest(meta["info"].bencode)
info_hash = CGI.escape(info_hash)

# Properties of the file
name = meta["info"]["name"]
totalLen = meta["info"]["length"]
pieceLen = meta["info"]["piece length"]
numPiece = ((totalLen.to_f)/(pieceLen.to_f)).ceil
bitField = Array.new(numPiece, 0)

# Hashes for each piece
pieces_hash = meta["info"]["pieces"].scan(/.{20}/)
for i in 0..(pieces_hash.length - 1) do
    pieces_hash[i] = pieces_hash[i].unpack('H*')
end


print "\nTorrent file accepted. Trying to download the file <#{name}> with total length of #{totalLen}\n"
print "info_hash for file is: #{info_hash}\n"
print "There are #{numPiece} pieces with piece length #{pieceLen}\n\n"
print "pieces_hash for each piece is: #{pieces_hash}\n\n"

trackerInfo = meta["announce"].split("/")
trackerInfo = trackerInfo[2].split(":")

# Creating connection
cSock = TCPSocket.open(trackerInfo[0], trackerInfo[1])

# Tracker communication
# Forming the GET request
getRequest = "GET /announce?info_hash=#{info_hash}"
peer_id = generatePeerID()
#p peer_id
getRequest += "&peer_id=#{CGI.escape(peer_id)}"
# our port
getRequest += "&port=#{cSock.addr[1]}"
getRequest += "&uploaded=0"
getRequest += "&downloaded=0"
# for multi-file mode
# length = meta["info"]["files"][0]["length"]
length = totalLen
getRequest += "&left=#{length}"
# Bobby said 30
getRequest += "&numwant=30"
getRequest += "&compact=#{compact}"
getRequest += "&event=started"
# Http and traker ip and port
getRequest += " HTTP/1.1\r\nHost:#{trackerInfo[0]}:#{trackerInfo[1]}\r\n\r\n"

# Sending GET request
cSock.puts(getRequest)

# Receiving header for tracker response
respHeader = cSock.gets("\r\n\r\n")
#print "tracker response header: \n"
#print respHeader
#print "\n"

# Extracting length of the bencode from the header
benLen = respHeader.scan(/Content-Length: \d+/)
benLen = benLen[0].scan(/\d+/)
benLen = benLen[0].to_i

# Reading bencode from socket based on length in header
bencode = cSock.read(benLen)
data = BEncode.load(bencode)
#print data
#print "\n"
#print numPeers
#print "\n"

# Parsing peers
peerInfo = []
if data["peers"].is_a?(String)
    # compact response
    peerInfo = data["peers"].bytes.each_slice(6).to_a
    numPeers = data["peers"].length/6
    for i in 0..(numPeers - 1) do
        peerIp = []
        peerIp[0] = peerInfo[i][0].to_s
        peerIp[1] = peerInfo[i][1].to_s
        peerIp[2] = peerInfo[i][2].to_s
        peerIp[3] = peerInfo[i][3].to_s
        peerIp = peerIp.join(".")
        peerPort = (peerInfo[i][4]*256 + peerInfo[i][5]).to_s
        peerInfo[i] = peerIp + ":" + peerPort
    end
else
    # noncompact response
    for i in 0..30 do
        if data["peers"][i] == nil
            break
        else
            peerInfo[i] = data["peers"][i]["ip"] + ":" + data["peers"][i]["port"].to_s
        end
    end
end
numPeers = peerInfo.length

print "peers parsed:\n#{peerInfo}\n\n"

#TODO: Peer communication
# Connecting to all peers
peerState = Array.new(numPeers){Array.new(5)}

#print "connected\n"
hex_info_hash = Digest::SHA1.digest(meta["info"].bencode)
handshake = "\x13BitTorrent protocol\x00\x00\x00\x00\x00\x00\x00\x00#{hex_info_hash}#{peer_id}"
for i in 0..(numPeers - 1) do
=begin
    This is how I think we should eventually connect to peers, this handles the case where the connection
    is refused w/o our client crashing
    
    begin
        x = peerInfo[i].split(":")
        s = TCPSocket.open(x[0], x[1])
    rescue => exception
        p "connection to #{x[0]} at port #{x[1]} failed"
    else
        p "connection to #{x[0]} at port #{x[1]} successful"
        peerState[i][SOCKET] = s #will eventually hold the socket after we create it
        peerState[i][AMCHOKING] = 1
        peerState[i][AMINTERESTED] = 0
        peerState[i][PEERCHOKING] = 1
        peerState[i][PEERINTERESTED] = 0
    end
=end
    if (peerInfo[i] == "128.8.126.63:55555") then
        p "connecting to Poole client"
        x = peerInfo[i].split(":")
        s = TCPSocket.open(x[0], x[1])
        p "connected to Poole client"
        s.write(handshake, handshake.length)
        p "handshake sent"

        # parsing the received handshake
        pstrlen = s.read(1).unpack('C')
        recvHs = s.read(pstrlen[0] + 8 + 20 + 20)
        #p recvHs

        #testing for receiving messages
        parseResponse(s)

        # testing for sending messages
        #test = haveMessage(1)
        #p test
        #s.write(test[0], test[1])
    else
        #p "not the Poole client, ignoring"
        s = 9999
    end
    peerState[i][SOCKET] = s #will eventually hold the socket after we create it
    peerState[i][AMCHOKING] = 1
    peerState[i][AMINTERESTED] = 0
    peerState[i][PEERCHOKING] = 1
    peerState[i][PEERINTERESTED] = 0
    #making connections with peers
    #peerAddr = peerInfo[i].split(":")
    #pSock[i] = TCPSocket.open(peerAddr[0], peerAddr[1])
end
# p peerState

# whenever a client connects we send a biffield message (if we have a piece)

# for testing messages parsing with the send.rb
=begin
test = -1

server = TCPServer.new 2000 # Server bind to port 2000
while test == -1
  test = server.accept    # Wait for a client to connect
end

parseResponse(test)

test.close
=end

cSock.close

