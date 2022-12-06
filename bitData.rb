class BitData
    # INCOMPLETE: this still needs work, need to implement parse/receive/set the bitmap
    attr_accessor :bitField, :bitMap
    def initialize(numPiece, pieceLen, totalLen)
        @totalLen = totalLen
        @bitField = Array.new(numPiece, 0)
        @bitMap = Array.new(numPiece) {Array.new(pieceLen, 0)}
    end

end
