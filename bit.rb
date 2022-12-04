require 'bencode'
require 'digest/sha1'
require 'socket'
require 'cgi'

# call the program with ruby bit.rb <filename.torrent> <1 for compact, 0 for noncompact>
# pieces_hash is a list of hashes for each piece of the file
# peerState with structure [[socket, am_choking, am_interested, peer_choking, peer_interested]]
# bitField with length of numPiece, initialized with all 0

def generatePeerID()
    x = [*'a'..'z', *'A'..'Z', *0..9]
    x = x.shuffle
    x = x.slice(0..19)
    x.join
end

SOCKET = 0
AMCHOKING = 1
AMINTERESTED = 2
PEERCHOKING = 3
PEERINTERESTED = 4

#Parsing the torrent file
meta = BEncode.load_file(ARGV[0])
compact = ARGV[1]
info_hash = Digest::SHA1.digest(meta["info"].bencode)
info_hash = CGI.escape(info_hash)


#print meta["info"]


#properties of the file
name = meta["info"]["name"]
totalLen = meta["info"]["length"]
pieceLen = meta["info"]["piece length"]
numPiece = ((totalLen.to_f)/(pieceLen.to_f)).ceil
bitField = Array.new(numPiece, 0)

#the hashes for each piece
pieces_hash = meta["info"]["pieces"].scan(/.{20}/)
for i in 0..(pieces_hash.length - 1) do
    pieces_hash[i] = pieces_hash[i].unpack('H*')
end

print "\nTorrent file accepted. Trying to download the file <#{name}> with total length of #{totalLen}"
print "\ninfo_hash for file is: #{info_hash}\n\n"
print "There are #{numPiece} pieces with piece length #{pieceLen}\n"
print "\npieces_hash for each piece is: #{pieces_hash}\n\n"

#tracker communication
#forming the GET request
getRequest = "GET /announce?info_hash=#{info_hash}"
peer_id = generatePeerID()
#p peer_id
getRequest += "&peer_id=#{CGI.escape(peer_id)}"
#TODO: port???
getRequest += "&port=51413"
getRequest += "&uploaded=0"
getRequest += "&downloaded=0"
#for multi-file mode
#length = meta["info"]["files"][0]["length"]
length = totalLen
getRequest += "&left=#{length}"
#bobby said 30
getRequest += "&numwant=30"
# *********************************** compact ******************************************
getRequest += "&compact=#{compact}"
getRequest += "&event=started"
#http and traker ip and port
trackerInfo = meta["announce"].split("/")
trackerInfo = trackerInfo[2].split(":")
getRequest += " HTTP/1.1\r\nHost:#{trackerInfo[0]}:#{trackerInfo[1]}\r\n\r\n"

#creating connection
cSock = TCPSocket.open(trackerInfo[0], trackerInfo[1])
#sending GET request
cSock.puts(getRequest)

#receiving header for tracker response
respHeader = cSock.gets("\r\n\r\n")
#print "tracker response header: \n"
#print respHeader
#print "\n"

#extracting length of the bencode from the header
benLen = respHeader.scan(/Content-Length: \d+/)
benLen = benLen[0].scan(/\d+/)
benLen = benLen[0].to_i

#reading bencode from socket based on length in header
bencode = cSock.read(benLen)
data = BEncode.load(bencode)

#print data
#print "\n"
#print "\n"



#print data
#print "\n"
#print numPeers
#print "\n"

#parsing peers

peerInfo = []
if data["peers"].is_a?(String)
    #compact response
    peerInfo = data["peers"].bytes.each_slice(6).to_a
    numPeers = data["peers"].length/6
    for i in 0..(numPeers - 1) do
        peerIp = [4]
        peerIp[0] = peerInfo[i][0].to_s
        peerIp[1] = peerInfo[i][1].to_s
        peerIp[2] = peerInfo[i][2].to_s
        peerIp[3] = peerInfo[i][3].to_s
        peerIp = peerIp.join(".")
        peerPort = (peerInfo[i][4]*256 + peerInfo[i][5]).to_s
        peerInfo[i] = peerIp + ":" + peerPort
    end
else
    #noncompact response
    for i in 0..30 do
        if data["peers"][i] == nil
            break
        else
            peerInfo[i] = data["peers"][i]["ip"] + ":" + data["peers"][i]["port"].to_s
        end
    end
end
numPeers = peerInfo.length

print "peers parsed:\n"
print peerInfo
print "\n\n"

#TODO: Peer communication
#connecting to all peers
peerState = Array.new(numPeers){Array.new(5)}

#peerSock = TCPSocket.open("128.8.126.63", "51413")
#print "connected\n"
hex_info_hash = Digest::SHA1.digest(meta["info"].bencode)
handshake = "\x13BitTorrent protocol\x00\x00\x00\x00\x00\x00\x00\x00#{hex_info_hash}#{peer_id}"
p handshake
for i in 0..(numPeers - 1) do
    #state for peers
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
        s.send(handshake, handshake.length)
        p "sent handshake"
        s.gets()
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

#print peerState
#print "\n"

cSock.close

