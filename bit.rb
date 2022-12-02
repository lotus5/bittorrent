
require 'bencode'
require 'digest/sha1'
require 'socket'
require 'cgi'

meta = BEncode.load_file('flatland.torrent')
info_hash = Digest::SHA1.digest(meta["info"].bencode)
info_hash = CGI.escape(info_hash)

getRequest = "GET /announce?info_hash=#{info_hash}"
#should have a randomly generated peer_id
getRequest += "&peer_id=01234567890123456789"
#???
getRequest += "&port=51413"
getRequest += "&uploaded=0"
getRequest += "&downloaded=0"
getRequest += "&left=#{meta["info"]["length"]}"
#bobby said 30
getRequest += "&numwant=30"
getRequest += "&compact=1"
getRequest += "&event=started"
#http and traker ip and port
getRequest += " HTTP/1.1\r\nHost:128.8.126.63:21212\r\n\r\n"

#creating connection
cSock = TCPSocket.open("128.8.126.63", 21212)
#sending GET request
cSock.puts(getRequest)

#receiving header
response = cSock.gets("\r\n\r\n")
print response
print "\n"

#extracting length of the bencode
benLen = response.scan(/Content-Length: \d+/)
benLen = benLen[0].scan(/\d+/)
benLen = benLen[0].to_i

#reading bencode from socket based on length
bencode = cSock.read(benLen)
peers = BEncode.load(bencode)
print peers
print "\n"

cSock.close


