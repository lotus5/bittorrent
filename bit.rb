
require 'bencode'  # don't forget to do % gem install bencode
require 'digest/sha1'
require 'socket'
require 'cgi'

meta = BEncode.load_file('flatland.torrent') # File or file path
info_hash = Digest::SHA1.digest(meta["info"].bencode)
info_hash = CGI.escape(info_hash)
info_hash = info_hash.downcase


print meta
print "\n"
print meta["info"]["length"]
print "\n"

print info_hash
print "\n"
hash = "%d4Cz%edh%1c%b0l%5e%cb%cf%2c%7fY%0a%e8%a3%f7%3a%eb"

getRequest = "GET /announce?info_hash=#{hash}"
#should have a randomly generated peer_id
getRequest += "&peer_id=01234567890123456789"
#???
getRequest += "&port=51413"
getRequest += "&uploaded=0"
getRequest += "&downloaded=0"
getRequest += "&left=#{meta["info"]["length"]}"
#bobby said 30
getRequest += "&numwant=30"
#should generate 8 bytes-long key
getRequest += "&key=12345678"
getRequest += "&compact=1"
#??? 1 in wireshark for transmission
getRequest += "&supportcrypto=0"
getRequest += "&event=started"
#??? the client ip address?
getRequest += "&ipv6=2600%3A4040%3A2c69%3Ab500%3Ad32%3Ac436%3Ad7df%3A9ca4"
#http and traker ip and port
getRequest += "HTTP/1.1\r\nHost:128.8.126.63:21212\r\n\r\n"


cSock = TCPSocket.open("128.8.126.63", 21212)
cSock.puts(getRequest)

sleep(10)
#response = cSock.gets
#print response
cSock.close


