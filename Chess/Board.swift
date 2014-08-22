struct Coordinate : Hashable {
    var row: Int
    var col: Int

    var hashValue: Int {
        return (row << 8) | col
    }

    var valid: Bool {
        return row >= 0 && row < 8 && col >= 0 && col < 8
    }
}

func ==(lhs: Coordinate, rhs: Coordinate) -> Bool {
    return lhs.row == rhs.row && lhs.col == rhs.col
}

protocol BoardDelegate: class {
    func boardDidMovePiece(piece: Piece, fromCoordinate: Coordinate, toCoordinate: Coordinate)
    func boardDidRemovePieceAfterCapture(piece: Piece, fromCoordinate: Coordinate)
    func boardWillRemovePieceAfterCapture(piece: Piece, fromCoordinate: Coordinate)
    func boardDidPromotePiece(piece: Piece, onCoordinate: Coordinate)
}

class Board {
    var pieceStorage = [Coordinate:Piece]()
    var nextTurn = Piece.Color.White

    subscript(coordinate: Coordinate) -> Piece? {
        get {
            return pieceStorage[coordinate]
        }
        set {
            pieceStorage[coordinate] = newValue
        }
    }

    var delegate: BoardDelegate?

    init() {
        reset()
    }

    var blackIsInCheck = false
    var whiteIsInCheck = false
    var blackIsInCheckmate = false
    var whiteIsInCheckmate = false

    func movePiece(piece: Piece, fromCoordinate start: Coordinate, toCoordinate end: Coordinate) {
        var newPiece = piece
        let capturedPiece = pieceStorage.removeValueForKey(end)
        if capturedPiece != nil {
            delegate?.boardWillRemovePieceAfterCapture(capturedPiece!, fromCoordinate: end)
        }

        var didPromote = false
        if let pawn = piece as? Pawn {
            if (pawn.direction == Pawn.Direction.Up) && (end.row == 0) || (pawn.direction == Pawn.Direction.Down) && (end.row == 7) {
                newPiece = Queen(color: piece.color)
                didPromote = true
            }
        }

        pieceStorage.removeValueForKey(start)
        pieceStorage[end] = newPiece
        piece.hasEverMoved = true
        delegate?.boardDidMovePiece(newPiece, fromCoordinate: start, toCoordinate: end)
        if capturedPiece != nil {
            // Capturing
            delegate?.boardDidRemovePieceAfterCapture(capturedPiece!, fromCoordinate: end)
        }
        if didPromote {
            delegate?.boardDidPromotePiece(newPiece, onCoordinate: end)
        }

        if piece is King && abs(start.col - end.col) == 2 {
            // Castling
            var rookStart: Coordinate
            var rookEnd: Coordinate
            if (start.col < end.col) {
                rookStart = Coordinate(row: start.row, col: 7)
                rookEnd = Coordinate(row: start.row, col: start.col + 1)
            } else {
                rookStart = Coordinate(row: start.row, col: 0)
                rookEnd = Coordinate(row: start.row, col: start.col - 1)
            }
            if let rook = pieceStorage.removeValueForKey(rookStart) {
                rook.hasEverMoved = true
                pieceStorage[rookEnd] = rook
                delegate?.boardDidMovePiece(rook, fromCoordinate: rookStart, toCoordinate: rookEnd)
            }
        }
        nextTurn = !nextTurn
    }

    private func filterUnblockedMoves(moves: [Piece.MoveType]) -> [Coordinate] {
        var validCoordinates = [Coordinate]()
        for move in moves {
            switch(move) {
            case .Direction(let coordinates):
                for otherCoordinate in coordinates {
                    if let otherPiece = pieceStorage[otherCoordinate] {
                        if otherPiece.color != nextTurn {
                            validCoordinates.append(otherCoordinate)
                        }
                        break
                    }
                    validCoordinates.append(otherCoordinate)
                }
            case .MoveOrCapture(let otherCoordinate):
                if let otherPiece = pieceStorage[otherCoordinate] {
                    if otherPiece.color != nextTurn {
                        validCoordinates.append(otherCoordinate)
                    }
                } else {
                    validCoordinates.append(otherCoordinate)
                }
            case .MoveOnly(let otherCoordinate):
                if pieceStorage[otherCoordinate] == nil {
                    validCoordinates.append(otherCoordinate)
                }
            case .CaptureOnly(let otherCoordinate):
                if let otherPiece = pieceStorage[otherCoordinate] {
                    if otherPiece.color != nextTurn {
                        validCoordinates.append(otherCoordinate)
                    }
                }
            case .CastleLeft(let otherCoordinate):
                if let rook = pieceStorage[Coordinate(row: otherCoordinate.row, col: 0)] as? Rook {
                    if !rook.hasEverMoved &&
                        pieceStorage[Coordinate(row: otherCoordinate.row, col: 1)] == nil &&
                        pieceStorage[Coordinate(row: otherCoordinate.row, col: 1)] == nil &&
                        pieceStorage[Coordinate(row: otherCoordinate.row, col: 1)] == nil {
                            validCoordinates.append(otherCoordinate)
                    }
                }
            case .CastleRight(let otherCoordinate):
                if let rook = pieceStorage[Coordinate(row: otherCoordinate.row, col: 7)] as? Rook {
                    if !rook.hasEverMoved &&
                        pieceStorage[Coordinate(row: otherCoordinate.row, col: 6)] == nil &&
                        pieceStorage[Coordinate(row: otherCoordinate.row, col: 5)] == nil {
                            validCoordinates.append(otherCoordinate)
                    }
                }
            }
        }
        return validCoordinates
    }

    func validMovesFrom(coordinate: Coordinate) -> [Coordinate] {
        if let piece = pieceStorage[coordinate] {
            return filterUnblockedMoves(piece.validMovesFrom(coordinate))
        } else {
            return []
        }
    }

    func canMoveFrom(start: Coordinate, to end: Coordinate) -> Bool {
        return validMovesFrom(start).reduce(false, combine: { (foundYet, otherCoordinate) in
            foundYet || (otherCoordinate == end)
        })
    }

    var whiteScore: Int {
        return colorScore(.White)
    }

    var blackScore: Int {
        return colorScore(.Black)
    }

    func colorScore(color: Piece.Color) -> Int {
        var score = 0
        for (coordinate, piece) in pieceStorage {
            if piece.color == color {
                score += piece.value
            }
        }
        return score
    }

    func reset() {
        nextTurn = Piece.Color.White
        pieceStorage = [:]

        func addPieceToBoard(piece: Piece, row: Int, col: Int) {
            pieceStorage[Coordinate(row: row, col: col)] = piece
        }

        for col in 0..<8 {
            addPieceToBoard(Pawn(color: .Black, direction: .Down), 1, col)
            addPieceToBoard(Pawn(color: .White, direction: .Up), 6, col)
        }

        addPieceToBoard(Rook(color: .Black), 0, 0)
        addPieceToBoard(Rook(color: .Black), 0, 7)
        addPieceToBoard(Rook(color: .White), 7, 0)
        addPieceToBoard(Rook(color: .White), 7, 7)

        addPieceToBoard(Knight(color: .Black), 0, 1)
        addPieceToBoard(Knight(color: .Black), 0, 6)
        addPieceToBoard(Knight(color: .White), 7, 1)
        addPieceToBoard(Knight(color: .White), 7, 6)

        addPieceToBoard(Bishop(color: .Black), 0, 2)
        addPieceToBoard(Bishop(color: .Black), 0, 5)
        addPieceToBoard(Bishop(color: .White), 7, 2)
        addPieceToBoard(Bishop(color: .White), 7, 5)

        addPieceToBoard(Queen(color: .Black), 0, 3)
        addPieceToBoard(Queen(color: .White), 7, 3)
        addPieceToBoard(King(color: .Black), 0, 4)
        addPieceToBoard(King(color: .White), 7, 4)
    }
}