
require 'bencode'
require 'digest/sha1'
require 'socket'
require 'cgi'

#call the program with ruby bit.rb <filename.torrent>
meta = BEncode.load_file(ARGV[0])
info_hash = Digest::SHA1.digest(meta["info"].bencode)
info_hash = CGI.escape(info_hash)

print "\ninfo_hash: "
print info_hash
print "\n\n"


#forming the GET request
getRequest = "GET /announce?info_hash=#{info_hash}"
#randomly generated peer_id
myId = "01234567890123456789"
getRequest += "&peer_id=#{myId}"
#???
getRequest += "&port=51413"
getRequest += "&uploaded=0"
getRequest += "&downloaded=0"
#for multi-file mode
#length = meta["info"]["files"][0]["length"]
length = meta["info"]["length"]
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

#receiving header
respHeader = cSock.gets("\r\n\r\n")
print "tracker response header: \n"
print respHeader
print "\n"

#extracting length of the bencode
benLen = respHeader.scan(/Content-Length: \d+/)
benLen = benLen[0].scan(/\d+/)
benLen = benLen[0].to_i

#reading bencode from socket based on length
bencode = cSock.read(benLen)
data = BEncode.load(bencode)
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
print "\n\n"

#connecting to all peers
pSock = []
width = 5
height = numPeers
peerState = Array.new(height){Array.new(width)}
for i in 0..(numPeers - 1) do
    #state for peers
    peerState[i][0] = 9999
    peerState[i][1] = 1
    peerState[i][2] = 0
    peerState[i][3] = 1
    peerState[i][4] = 0
    #making connections with peers
    peerAddr = peerInfo[i].split(":")
    #pSock[i] = TCPSocket.open(peerAddr[0], peerAddr[1])
end

print peerState
print "\n"

#send handshake to all peers






cSock.close


