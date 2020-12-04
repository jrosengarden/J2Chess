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
    var moveCount:Int?                          // track move count for move display
    var firstHalfMove:String?                   // save current move until opponent moves
    var pieceToRemove:Piece?                    // global variable for piece (if any) at dest square
    
    init(viewController: ViewController) {
        theChessBoard = ChessBoard.init(viewController: viewController)
        moveCount = 1
        firstHalfMove = ""
    }
    
    func move(piece chessPieceToMove: UIChessPiece, fromIndex sourceIndex: BoardIndex, toIndex destIndex: BoardIndex, toOrigin destOrigin: CGPoint) {
    
        // get initial chess piece frame
        let initialChessPieceFrame = chessPieceToMove.frame
    
        // remove piece at destination
        pieceToRemove = theChessBoard.board[destIndex.row][destIndex.col]
        theChessBoard.remove(piece: pieceToRemove!)
        
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
    // everytime it's white's turn increase the move count
    func nextTurn() {
        isWhiteTurn = !isWhiteTurn
        if isWhiteTurn {
            moveCount! += 1
        }
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
        var capture:String?
        
        // set capture string to "x" if the target square was not empty (Dummy)
        if pieceToRemove is Dummy {
            capture = ""
        } else {
            capture = "x"
        }
        
        // set thePiece value based on class of piece
        if (chessPieceToMove is Pawn) {
            thePiece = ""
        }
        if (chessPieceToMove is Rook) {
            thePiece = "R"
        }
        if (chessPieceToMove is Knight) {
            thePiece = "N"
        }
        if (chessPieceToMove is Bishop) {
            thePiece = "B"
        }
        if (chessPieceToMove is Queen) {
            thePiece = "Q"
        }
        if (chessPieceToMove is King) {
            thePiece = "K"
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
            algebraicSourcePosition = "a" + String(correction!)
        case 1:
            algebraicSourcePosition = "b" + String(correction!)
        case 2:
            algebraicSourcePosition = "c" + String(correction!)
        case 3:
            algebraicSourcePosition = "d" + String(correction!)
        case 4:
            algebraicSourcePosition = "e" + String(correction!)
        case 5:
            algebraicSourcePosition = "f" + String(correction!)
        case 6:
            algebraicSourcePosition = "g" + String(correction!)
        default:
            algebraicSourcePosition = "h" + String(correction!)
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
            algebraicDestPosition = "a" + String(correction!)
        case 1:
            algebraicDestPosition = "b" + String(correction!)
        case 2:
            algebraicDestPosition = "c" + String(correction!)
        case 3:
            algebraicDestPosition = "d" + String(correction!)
        case 4:
            algebraicDestPosition = "e" + String(correction!)
        case 5:
            algebraicDestPosition = "f" + String(correction!)
        case 6:
            algebraicDestPosition = "g" + String(correction!)
        default:
            algebraicDestPosition = "h" + String(correction!)
        }
        
        // if capture was made by pawn alter the algebraicDestPosition string accordingly
        if capture == "x" && thePiece == "" {
            algebraicDestPosition = (algebraicSourcePosition?.prefix(1))! + "x" + algebraicDestPosition!
            capture = ""
        }
        
        // if it was black's turn it's time to update the dispMove label
        // if it was white's turn then save the move to firstHalfMove
        if !(isWhiteTurn) {
            // display move, in algebraic notation, on display
            theChessBoard.vc.dispMove.text! = firstHalfMove!
            theChessBoard.vc.dispMove.text! +=  " \(thePiece ?? "")"
            theChessBoard.vc.dispMove.text! += capture!
            //theChessBoard.vc.dispMove.text! += "\(algebraicSourcePosition ?? "")"
            theChessBoard.vc.dispMove.text! += "\(algebraicDestPosition ?? "")"
            theChessBoard.vc.dispMove.textColor = isWhiteTurn ? #colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 1) : #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
            
            // debugging
            print (theChessBoard.vc.dispMove.text!)
            
        } else {
            firstHalfMove! = "\(moveCount ?? 0): \(thePiece ?? "")"
            firstHalfMove! += capture!
            //firstHalfMove! += "\(algebraicSourcePosition ?? "")"
            firstHalfMove! += "\(algebraicDestPosition ?? "")"
        }
        
    }
    
    
}
