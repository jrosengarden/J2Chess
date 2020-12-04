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
            theChessBoard.vc.dispMove.text = "MOVE IS NOT ON BOARD"
            theChessBoard.vc.dispMove.textColor = isWhiteTurn ? #colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 1) : #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
            print(theChessBoard.vc.dispMove.text!)
            return false
        }
        
        guard isTurnColor(sameAsPiece: piece) else {
            theChessBoard.vc.dispMove.text = "NOT"
            theChessBoard.vc.dispMove.text! += isWhiteTurn ? " BLACK'S TURN" : " WHITE'S TURN"
            theChessBoard.vc.dispMove.textColor = isWhiteTurn ? #colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 1) : #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
            print(theChessBoard.vc.dispMove.text!)
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
            theChessBoard.vc.dispMove.text = "MOVING PIECE ON ITS OWN POSITION"
            theChessBoard.vc.dispMove.textColor = isWhiteTurn ? #colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 1) : #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
            print (theChessBoard.vc.dispMove.text!)
            return false
        }
 
        guard !isAttackingAlliedPiece(sourceChessPiece: piece, destIndex: dest) else {
                theChessBoard.vc.dispMove.text = "ATTACKING YOUR OWN PIECE"
                theChessBoard.vc.dispMove.textColor = isWhiteTurn ? #colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 1) : #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
                print(theChessBoard.vc.dispMove.text!)
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
    
    
    // insure the move being made is actually on the board
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
    
    
    // calculate the algebraic notation version of the move then display it
    func showMove(piece chessPieceToMove: UIChessPiece, fromIndex sourceIndex: BoardIndex, toIndex destIndex: BoardIndex) {
        
        var algebraicSourcePosition:String?
        var algebraicDestPosition:String?
        var correction:Int?
        var thePiece:String?
        
        // set thePiece value based on current color moving and class of piece
        if (chessPieceToMove is Pawn) {
            thePiece = isWhiteTurn ? "White Pawn" : "Black Pawn"
        }
        if (chessPieceToMove is Rook) {
            thePiece = isWhiteTurn ? "White Rook" : "Black Rook"
        }
        if (chessPieceToMove is Knight) {
            thePiece = isWhiteTurn ? "White Knight" : "Black Knight"
        }
        if (chessPieceToMove is Bishop) {
            thePiece = isWhiteTurn ? "White Bishop" : "Black Bishop"
        }
        if (chessPieceToMove is Queen) {
            thePiece = isWhiteTurn ? "White Queen" : "Black Queen"
        }
        if (chessPieceToMove is King) {
            thePiece = isWhiteTurn ? "White King" : "Black King"
        }
        

        // convert sourceIndex.row to algebraic notation value
        switch sourceIndex.row {
        case 7:
            correction = 1
        case 6:
            correction = 2
        case 5:
            correction = 3
        case 4:
            correction = 4
        case 3:
            correction = 5
        case 2:
            correction = 6
        case 1:
            correction = 7
        default:
            correction = 8
        }
        
        // set final source position to algebraic notation
        switch sourceIndex.col {
        case 0:
            algebraicSourcePosition = "A" + String(correction!)
        case 1:
            algebraicSourcePosition = "B" + String(correction!)
        case 2:
            algebraicSourcePosition = "C" + String(correction!)
        case 3:
            algebraicSourcePosition = "D" + String(correction!)
        case 4:
            algebraicSourcePosition = "E" + String(correction!)
        case 5:
            algebraicSourcePosition = "F" + String(correction!)
        case 6:
            algebraicSourcePosition = "G" + String(correction!)
        default:
            algebraicSourcePosition = "H" + String(correction!)
        }
        
        // convert destIndex.row to algebraic notation value
        switch destIndex.row {
        case 7:
            correction = 1
        case 6:
            correction = 2
        case 5:
            correction = 3
        case 4:
            correction = 4
        case 3:
            correction = 5
        case 2:
            correction = 6
        case 1:
            correction = 7
        default:
            correction = 8
        }
        
        // set final destination position to algebraic notation
        switch destIndex.col {
        case 0:
            algebraicDestPosition = "A" + String(correction!)
        case 1:
            algebraicDestPosition = "B" + String(correction!)
        case 2:
            algebraicDestPosition = "C" + String(correction!)
        case 3:
            algebraicDestPosition = "D" + String(correction!)
        case 4:
            algebraicDestPosition = "E" + String(correction!)
        case 5:
            algebraicDestPosition = "F" + String(correction!)
        case 6:
            algebraicDestPosition = "G" + String(correction!)
        default:
            algebraicDestPosition = "H" + String(correction!)
        }
        
        // display move, in algebraic notation, on display
        theChessBoard.vc.dispMove.text! =  "Moving \(thePiece ?? "") "
        theChessBoard.vc.dispMove.text! += "from \(algebraicSourcePosition ?? "") "
        theChessBoard.vc.dispMove.text! += "to \(algebraicDestPosition ?? "")"
        theChessBoard.vc.dispMove.textColor = isWhiteTurn ? #colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 1) : #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        
        
        // debugging
        print (theChessBoard.vc.dispMove.text!)
    }
    
    
}
