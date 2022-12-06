# Implemented by Jordan Johnson

def waitforResponse (peerState, x)
    p peerState
    sox = Array.new
    a = 0
    for i in 0..x do
        if (peerState[i][SOCKET] != 9999) then
            sox[a] = peerState[i][SOCKET]
            a = a + 1
        end
    end
    p sox
    x = select(sox, [], [], 5)
    if (x == nil) then
        p "timeout occurred send keep alive"
    else
        readable = x[0]
        readable.each { |socket| parseResponse(socket)}
    end
end
