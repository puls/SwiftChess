//
//  ViewController.swift
//  Chess
//
//  Created by Jim Puls on 8/6/14.
//  Copyright (c) 2014 Square, Inc. All rights reserved.
//

import UIKit

extension CGVector {
    init(point: CGPoint) {
        dx = point.x
        dy = point.y
    }
    var magnitude: CGFloat {
        return sqrt(dx * dx + dy * dy)
    }
}

typealias PieceView = UILabel
typealias GridSquareView = UIView

class MoveCell: UICollectionViewCell {
    @IBOutlet weak var captionLabel: UILabel!

    func configureWithColor(color: Piece.Color) {
        switch(color) {
        case .White:
            backgroundColor = UIColor.whiteColor()
            captionLabel.textColor = UIColor.blackColor()
        case .Black:
            backgroundColor = UIColor.blackColor()
            captionLabel.textColor = UIColor.whiteColor()
        }
    }
}

class ViewController: UIViewController, UICollectionViewDataSource, BoardDelegate {
                            
    @IBOutlet weak var boardView: UIView!
    @IBOutlet weak var scoreLabel: UILabel!

    private var gridSize: CGFloat {
        return CGRectGetWidth(boardView.bounds) / 8.0
    }

    private func updateScores() {
//        scoreLabel.text = "White: \(board.whiteScore) Black: \(board.blackScore)"
    }

    struct Move {
        var piece: Piece
        var capturedPiece: Piece?
        var from: Coordinate
        var to: Coordinate

        var description: String {
            var string = piece.algebraicName
            if let capturedPiece_ = capturedPiece {
                if countElements(string) == 0 {
                    string += String(Array("abcdefgh")[from.col])
                }
                string += "x"
            }
            let colStr = String(Array("abcdefgh")[to.col])
            let rowStr = String(8 - to.row)
            string += colStr + rowStr
            return string
        }
    }


    @IBOutlet weak var collectionView: UICollectionView!

    private var allMoves = [Move]()
    func collectionView(collectionView: UICollectionView!, cellForItemAtIndexPath indexPath: NSIndexPath!) -> UICollectionViewCell! {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Move", forIndexPath: indexPath) as MoveCell
        let move = allMoves[indexPath.item]
        let piece = move.piece
        cell.configureWithColor(piece.color)
        cell.captionLabel.text = move.description
        return cell
    }

    func collectionView(collectionView: UICollectionView!, numberOfItemsInSection section: Int) -> Int {
        return allMoves.count
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let gestureRecognizer = UIPanGestureRecognizer(target: self, action: "gestureRecognized:")
        boardView.addGestureRecognizer(gestureRecognizer)

        createBoardGrid()
        setInitialLayout()
        board.delegate = self
        updateScores()
    }

    var draggingPiece: Piece?
    var draggingPieceView: PieceView?
    var dragStartCoordinate: Coordinate?
    var validDrops = [Coordinate]()
    func gestureRecognized(sender: UIPanGestureRecognizer!) {
        let location = sender.locationInView(boardView)
        let coordinate = coordinateFromPoint(location)
        switch(sender.state) {
        case .Began:
            if let piece = board[coordinate] {
                if piece.color != board.nextTurn {
                    return
                }
                draggingPiece = piece
                draggingPieceView = pieceViews[coordinate]
                dragStartCoordinate = coordinate

                validDrops = board.validMovesFrom(coordinate)
                var viewsToHighlight = [GridSquareView]()
                for dropCoordinate in validDrops {
                    if let gridCell = boardGrid[dropCoordinate] {
                        viewsToHighlight.append(gridCell)
                    }
                }
                highlightedViews = viewsToHighlight
            }
        case .Changed:
            if let viewToMove = draggingPieceView {
                viewToMove.center = location
            }
        case .Ended:
            if let viewToMove = draggingPieceView {
                let velocity = CGVector(point: sender.velocityInView(boardView))

                let startCoordinate = dragStartCoordinate!

                if board.canMoveFrom(startCoordinate, to: coordinate) {
                    // Make the move, let the board tell us what happened
                    board.movePiece(draggingPiece!, fromCoordinate: startCoordinate, toCoordinate: coordinate)
                } else {
                    // Snap back
                    let animations = {
                        self.positionViewInGrid(viewToMove, atCoordinate: coordinate)
                    }

                    UIView.animateWithDuration(0.2, delay: 0.0, usingSpringWithDamping: 100.0, initialSpringVelocity: velocity.magnitude, options: nil, animations: animations, completion: nil)
                }
                draggingPiece = nil
                draggingPieceView = nil
                dragStartCoordinate = nil
                highlightedViews = []
                validDrops = []
            }
        default:
            break
        }
    }

    func boardDidMovePiece(piece: Piece, fromCoordinate: Coordinate, toCoordinate: Coordinate) {
        if let pieceView = pieceViews.removeValueForKey(fromCoordinate) {
            pieceViews[toCoordinate] = pieceView
            let animations = {
                self.positionViewInGrid(pieceView, atCoordinate: toCoordinate)
            }
            UIView.animateWithDuration(0.2, delay: 0.0, usingSpringWithDamping: 100.0, initialSpringVelocity: 0.0, options: nil, animations: animations, completion: nil)
            allMoves.append(Move(piece: piece, capturedPiece: nil, from: fromCoordinate, to: toCoordinate))
            collectionView.insertItemsAtIndexPaths([NSIndexPath(forItem: allMoves.count - 1, inSection: 0)])
        }
    }

    func boardDidPromotePiece(piece: Piece, onCoordinate: Coordinate) {
        pieceViews[onCoordinate]!.text = piece.label
        updateScores()
    }

    func boardWillRemovePieceAfterCapture(piece: Piece, fromCoordinate: Coordinate) {
        pieceViews[fromCoordinate]!.removeFromSuperview()
    }

    func boardDidRemovePieceAfterCapture(piece: Piece, fromCoordinate: Coordinate) {
        var move = allMoves.last!
        move.capturedPiece = piece
        allMoves[allMoves.count - 1] = move
        collectionView.reloadItemsAtIndexPaths([NSIndexPath(forItem: allMoves.count - 1, inSection: 0)])
        updateScores()
    }

    var highlightedViews: [GridSquareView] = [] {
        didSet {
            for view in oldValue {
                view.layer.borderWidth = 0.0
            }
            for view in highlightedViews {
                view.layer.borderWidth = gridSize / 20.0
            }
        }
    }

    private func coordinateFromPoint(point: CGPoint) -> Coordinate {
        return Coordinate(row: Int(point.y / gridSize), col: Int(point.x / gridSize))
    }

    private func positionViewInGrid(subview: UIView, atCoordinate coordinate: Coordinate) {
        subview.frame = CGRect(
            x: CGFloat(coordinate.col) * gridSize,
            y: CGFloat(coordinate.row) * gridSize,
            width: gridSize,
            height: gridSize
        )
    }

    private var boardGrid = [Coordinate:GridSquareView]()
    private func createBoardGrid() {
        for row in 0..<8 {
            for col in 0..<8 {
                let coordinate = Coordinate(row: row, col: col)
                let tileView = GridSquareView()
                tileView.backgroundColor = (row + col) % 2 == 0 ? UIColor.whiteColor() : UIColor.lightGrayColor()
                tileView.layer.borderColor = (row + col) % 2 == 0 ? UIColor.darkGrayColor().CGColor : UIColor.blackColor().CGColor
                boardView.addSubview(tileView)
                boardGrid[coordinate] = tileView
                positionViewInGrid(tileView, atCoordinate: coordinate)
            }
        }
    }

    private var pieceViews = [Coordinate:PieceView]()
    private var board = Board()
    private func setInitialLayout() {
        for view in pieceViews.values {
            view.removeFromSuperview()
        }
        pieceViews = [Coordinate:PieceView]()

        for (coordinate, piece) in board.pieceStorage {
            let pieceView = UILabel()
            pieceView.text = piece.label
            pieceView.textAlignment = .Center
            pieceView.font = UIFont.boldSystemFontOfSize(gridSize)
            boardView.addSubview(pieceView)
            positionViewInGrid(pieceView, atCoordinate: coordinate)
            pieceViews[coordinate] = pieceView
        }
    }
}
