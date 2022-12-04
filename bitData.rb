
class BitData
    # INCOMPLETE: this still needs work, I am not entirely sure how to parse/receive/set the bitmap
    attr_accessor :bitField, :bitMap
    def initialize(numPiece, pieceLen)
        @bitField = Array.new(numPiece, 0)
        @bitMap = Array.new(numPiece) {Array.new(pieceLen, 0)}
    end

end