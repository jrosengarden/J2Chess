//
//  ChessGame.swift
//  JeffChess
//
//  Created by Jeff Rosengarden on 11/18/20.
//

import UIKit

class ChessGame: NSObject {
    
    var theChessBoard: ChessBoard!
    
    init(viewController: ViewController) {
        theChessBoard = ChessBoard.init(viewController: viewController)
    }
    
    func move(piece chessPieceToMove: UIChessPiece, fromIndex sourceIndex: BoardIndex, toIndex destIndex: BoardIndex, toOrigin destOrigin: CGPoint) {
    
        // get initial chess piece frame
        let initialChessPieceFrame = chessPieceToMove.frame
    
        // remove piece at destination
        let pieceToRemove = theChessBoard.board[destIndex.row][destIndex.col]
        theChessBoard.remove(piece: pieceToRemove)
        
        //place the chess piece at destination
        theChessBoard.place(chessPiece: chessPieceToMove, toIndex: destIndex, toOrigin: destOrigin)
        
        // put a Dummy piece in the vacant source tile
        theChessBoard.board[sourceIndex.row][sourceIndex.col] = Dummy(frame: initialChessPieceFrame)
    }
    
    func isMoveValid(piece: UIChessPiece, fromIndex sourceIndex: BoardIndex, toIndex destIndex: BoardIndex) -> Bool {
        
        guard isMoveOnBoard(forPieceFrom: sourceIndex, thatGoesTo: destIndex) else {
            print("MOVE IS NOT ON BOARD")
            return false
        }
        return true
        
    }
    
    func isMoveOnBoard(forPieceFrom sourceIndex: BoardIndex, thatGoesTo destIndex: BoardIndex) -> Bool {
        
        if case 0..<theChessBoard.ROWS = sourceIndex.row {
            if case 0..<theChessBoard.COLS = sourceIndex.col {
                if case 0..<theChessBoard.ROWS = destIndex.row {
                    if case 0..<theChessBoard.COLS = destIndex.col {
                        return true
                    }
                }
            }
        }
        
        return false
    }
    
}
