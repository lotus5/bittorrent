require 'bencode'
require 'digest/sha1'
require 'socket'
require 'cgi'

# call the program with ruby bit.rb <filename.torrent>
# pieces_hash is a list of hashes for each piece of the file
# peerState with structure [[socket, am_choking, am_interested, peer_choking, peer_interested]]
# bitField with length of numPiece, initialized with all 0

SOCKET = 0
AMCHOKING = 1
AMINTERESTED = 2
PEERCHOKING = 3
PEERINTERESTED = 4

#Parsing the torrent file
meta = BEncode.load_file(ARGV[0])
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
print "\ninfo_hash for file is: "
print info_hash
print "\n\n"
print "There are #{numPiece} pieces with piece length #{pieceLen}\n"
print "\npieces_hash for each piece is: \n"
print pieces_hash
print "\n\n"


#tracker communication
#forming the GET request
getRequest = "GET /announce?info_hash=#{info_hash}"
#TODO: randomly generated peer_id
peer_id = "01234567890123456789"
getRequest += "&peer_id=#{peer_id}"
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
getRequest += "&compact=1"
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

numPeers = data["peers"].length/6

#parsing peers
reg = ''
for i in 1..numPeers do
    reg += 'CCCCS'
end
peers = data["peers"].unpack(reg)
peerInfo = []
for i in 0..(numPeers - 1) do
    peerInfo[i] = peers[5 * i].to_s + "." + peers[5 * i + 1].to_s + "." + peers[5 * i + 2].to_s + "." + peers[5 * i + 3].to_s + ":" + peers[5 * i + 4].to_s
end
print "peers parsed:\n"
print peerInfo
#print "\n\n"


#TODO: Peer communication
#connecting to all peers
pSock = []
width = 5
height = numPeers
peerState = Array.new(height){Array.new(width)}

#peerSock = TCPSocket.open("128.8.126.63", "51413")
#print "connected\n"

for i in 0..(numPeers - 1) do
    #state for peers
    peerState[i][SOCKET] = 9999
    peerState[i][AMCHOKING] = 1
    peerState[i][AMINTERESTED] = 0
    peerState[i][PEERCHOKING] = 1
    peerState[i][PEERINTERESTED] = 0
    #making connections with peers
    peerAddr = peerInfo[i].split(":")
    #pSock[i] = TCPSocket.open(peerAddr[0], peerAddr[1])
end

#print peerState
#print "\n"

#send handshake to all peers
handshake = ""





cSock.close


