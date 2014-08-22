class Piece {
    enum Color {
        case White, Black
    }

    let color: Color

    var hasEverMoved = false

    var label: String {
        return ""
    }

    var value: Int {
        return 0
    }

    init(color: Color) {
        self.color = color
    }

    enum MoveType {
        case Direction([Coordinate])
        case MoveOrCapture(Coordinate)
        case MoveOnly(Coordinate)
        case CaptureOnly(Coordinate)

        case CastleLeft(Coordinate)
        case CastleRight(Coordinate)
    }

    func validMovesFrom(start: Coordinate) -> [MoveType] {
        return []
    }

    var algebraicName: String {
        return ""
    }

    private func filterValidCoordinates(moves: [MoveType]) -> [MoveType] {
        var validMoves = [MoveType]()
        for move in moves {
            switch(move) {
            case .Direction(let coordinates):
                let validCoordinates = coordinates.filter { $0.valid }
                if validCoordinates.count > 0 {
                    validMoves.append(.Direction(validCoordinates))
                }
            case .MoveOnly(let coordinate):
                if coordinate.valid {
                    validMoves.append(move)
                }
            case .MoveOrCapture(let coordinate):
                if coordinate.valid {
                    validMoves.append(move)
                }
            case .CaptureOnly(let coordinate):
                if coordinate.valid {
                    validMoves.append(move)
                }
            case .CastleLeft: fallthrough
            case .CastleRight:
                validMoves.append(move)
            }
        }
        return validMoves
    }
}

prefix func !(color: Piece.Color) -> Piece.Color {
    if color == .White {
        return .Black
    } else {
        return .White
    }
}

class Pawn: Piece {
    override var label: String {
        return color == .Black ? "♟" : "♙"
    }

    override var value: Int {
        return 1
    }

    enum Direction {
        case Up, Down
    }

    var direction: Direction

    init(color: Color, direction: Direction) {
        self.direction = direction
        super.init(color: color)
    }

    override func validMovesFrom(start: Coordinate) -> [MoveType] {
        var moves: [MoveType]
        switch(direction) {
        case .Up:
            moves = [
                .MoveOnly(Coordinate(row: start.row - 1, col: start.col)),
                .CaptureOnly(Coordinate(row: start.row - 1, col: start.col + 1)),
                .CaptureOnly(Coordinate(row: start.row - 1, col: start.col - 1)),
            ]
            if !hasEverMoved {
                moves.append(.MoveOnly(Coordinate(row: start.row - 2, col: start.col)))
            }
        case .Down:
            moves = [
                .MoveOnly(Coordinate(row: start.row + 1, col: start.col)),
                .CaptureOnly(Coordinate(row: start.row + 1, col: start.col + 1)),
                .CaptureOnly(Coordinate(row: start.row + 1, col: start.col - 1)),
            ]
            if !hasEverMoved {
                moves.append(.MoveOnly(Coordinate(row: start.row + 2, col: start.col)))
            }
        }
        return moves
    }
}

class Rook: Piece {
    override var label: String {
        return color == .Black ? "♜" : "♖"
    }

    override var value: Int {
        return 5
    }

    override func validMovesFrom(start: Coordinate) -> [MoveType] {
        let directions: [MoveType] = [
            .Direction((1...7).map { Coordinate(row: start.row - $0, col: start.col) }),
            .Direction((1...7).map { Coordinate(row: start.row + $0, col: start.col) }),
            .Direction((1...7).map { Coordinate(row: start.row, col: start.col - $0) }),
            .Direction((1...7).map { Coordinate(row: start.row, col: start.col + $0) }),
        ]
        return filterValidCoordinates(directions)
    }

    override var algebraicName: String { return "R" }
}

class Knight: Piece {
    override var label: String {
        return color == .Black ? "♞" : "♘"
    }

    override var value: Int {
        return 3
    }

    override func validMovesFrom(start: Coordinate) -> [MoveType] {
        return filterValidCoordinates([
            Coordinate(row: start.row + 1, col: start.col + 2),
            Coordinate(row: start.row + 2, col: start.col + 1),
            Coordinate(row: start.row - 1, col: start.col + 2),
            Coordinate(row: start.row - 2, col: start.col + 1),
            Coordinate(row: start.row + 1, col: start.col - 2),
            Coordinate(row: start.row + 2, col: start.col - 1),
            Coordinate(row: start.row - 1, col: start.col - 2),
            Coordinate(row: start.row - 2, col: start.col - 1),
        ].map { .MoveOrCapture($0) })
    }

    override var algebraicName: String { return "N" }
}

class Bishop: Piece {
    override var label: String {
        return color == .Black ? "♝" : "♗"
    }

    override var value: Int {
        return 3
    }

    override func validMovesFrom(start: Coordinate) -> [MoveType] {
        let directions: [MoveType] = [
            .Direction((1...7).map { Coordinate(row: start.row - $0, col: start.col - $0) }),
            .Direction((1...7).map { Coordinate(row: start.row + $0, col: start.col - $0) }),
            .Direction((1...7).map { Coordinate(row: start.row - $0, col: start.col + $0) }),
            .Direction((1...7).map { Coordinate(row: start.row + $0, col: start.col + $0) }),
        ]
        return filterValidCoordinates(directions)
    }

    override var algebraicName: String { return "B" }
}

class Queen: Piece {
    override var label: String {
        return color == .Black ? "♛" : "♕"
    }

    override var value: Int {
        return 9
    }

    override func validMovesFrom(start: Coordinate) -> [MoveType] {
        let directions: [MoveType] = [
            .Direction((1...7).map { Coordinate(row: start.row - $0, col: start.col) }),
            .Direction((1...7).map { Coordinate(row: start.row + $0, col: start.col) }),
            .Direction((1...7).map { Coordinate(row: start.row, col: start.col - $0) }),
            .Direction((1...7).map { Coordinate(row: start.row, col: start.col + $0) }),
            .Direction((1...7).map { Coordinate(row: start.row - $0, col: start.col - $0) }),
            .Direction((1...7).map { Coordinate(row: start.row + $0, col: start.col - $0) }),
            .Direction((1...7).map { Coordinate(row: start.row - $0, col: start.col + $0) }),
            .Direction((1...7).map { Coordinate(row: start.row + $0, col: start.col + $0) }),
        ]
        return filterValidCoordinates(directions)
    }

    override var algebraicName: String { return "Q" }
}

class King: Piece {
    override var label: String {
        return color == .Black ? "♚" : "♔"
    }

    override func validMovesFrom(start: Coordinate) -> [MoveType] {
        var basicMoves: [MoveType] = [
            .MoveOrCapture(Coordinate(row: start.row - 1, col: start.col)),
            .MoveOrCapture(Coordinate(row: start.row + 1, col: start.col)),
            .MoveOrCapture(Coordinate(row: start.row, col: start.col - 1)),
            .MoveOrCapture(Coordinate(row: start.row, col: start.col + 1)),
            .MoveOrCapture(Coordinate(row: start.row - 1, col: start.col - 1)),
            .MoveOrCapture(Coordinate(row: start.row + 1, col: start.col - 1)),
            .MoveOrCapture(Coordinate(row: start.row - 1, col: start.col + 1)),
            .MoveOrCapture(Coordinate(row: start.row + 1, col: start.col + 1)),
        ]
        if !hasEverMoved {
            basicMoves.append(.CastleLeft(Coordinate(row: start.row, col: start.col - 2)))
            basicMoves.append(.CastleRight(Coordinate(row: start.row, col: start.col + 2)))
        }
        return filterValidCoordinates(basicMoves)
    }

    override var algebraicName: String { return "K" }
}
