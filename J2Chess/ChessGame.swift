//
//  ChessGame.swift
//  JeffChess
//
//  Created by Jeff Rosengarden on 11/18/20.
//

import UIKit

class ChessGame: NSObject {
    
    var theChessBoard: ChessBoard!
    var isWhiteTurn:Bool = true                 // variable to track which color's turn it is
    
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
    
    // check for two specific conditions: 1. Is the move on the board
    //                                    2. Is it that color's turn?
    // if those two checks are passed then return TRUE/FALSE from the isNormalMoveValid function.
    func isMoveValid(piece: UIChessPiece, fromIndex sourceIndex: BoardIndex, toIndex destIndex: BoardIndex) -> Bool {
        
        guard isMoveOnBoard(forPieceFrom: sourceIndex, thatGoesTo: destIndex) else {
            print("MOVE IS NOT ON BOARD")
            return false
        }
        
        guard isTurnColor(sameAsPiece: piece) else {
            print("WRONG TURN")
            return false
        }
               
        return isNormalMoveValid(forPiece: piece, fromIndex: sourceIndex, toIndex: destIndex)
    }
    
    
    // this function will be the heart & soul of the chess logic engine to insure a move is valid
    // before allowing it to be considered by the chess engine.
    // two basic checks are done first: 1) moving the piece onto it's own square
    //                                  2) trying to attack one of it's own pieces
    func isNormalMoveValid(forPiece piece: UIChessPiece, fromIndex source: BoardIndex, toIndex dest: BoardIndex) -> Bool {
        
        guard source != dest else {
            print ("MOVING PIECE ON ITS CURRENT POSITION")
            return false
        }
 
        guard !isAttackingAlliedPiece(sourceChessPiece: piece, destIndex: dest) else {
                print("ATTACKING ALLIED PIECE")
                return false
                }
        
        return true
    }
    
    // function to flip value of isWhiteTurn
    // if true flip to false
    // if flase flip to true
    func nextTurn() {
        isWhiteTurn = !isWhiteTurn
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
    
    // function to determine if the color of the piece being moved
    // is the color of who's turn it currently is
    func isTurnColor(sameAsPiece piece: UIChessPiece) -> Bool {
        
        if piece.color == #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1) {
            if !isWhiteTurn {
                return true
            }
        } else {
            if isWhiteTurn {
                return true
                
            }
        }
        return false
    }
    
  
    // function to determine if the piece being attacked is the same color
    // as the piece doing the attacking
    func isAttackingAlliedPiece(sourceChessPiece: UIChessPiece, destIndex: BoardIndex) -> Bool {
        
        // get the piece that is at the destination square
        let destPiece: Piece = theChessBoard.board[destIndex.row][destIndex.col]
        
        // if moving to a square containing a dummy piece then we're not
        // attacking a piece of the same color so return false
        guard !(destPiece is Dummy) else {
            return false
        }
        
        //  need to typecast the destPiece to a UIChessPiece so we can get the
        //  color of the piece on the destination square
        let destChessPiece = destPiece as! UIChessPiece
        
        // if the two pieces are the same color return true, else return false
        return (destChessPiece.color == sourceChessPiece.color)
        
    }
    
    
}
