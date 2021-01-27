//
//  ChessGame.swift
//  JeffChess
//
//  Created by Jeff Rosengarden on 11/18/20.
//

import UIKit
import AudioToolbox

class ChessGame: NSObject {
    
    var theChessBoard: ChessBoard!
    var isWhiteTurn:Bool = true                 // variable to track which color's turn it is
    var winner: String?                         // set by didSomeBodyWin() function
    
    var moveCount:Int?                          // track move count for move display
    var firstHalfMove:String?                   // save current move until opponent moves
    var pieceToRemove:Piece?                    // global variable for piece (if any) at dest square
    var enPassantPawn:Piece?                    // global variable to track enPassant pawn removal
    var castleNotation:String = ""              // global variable to hold castling notation
    var gameMoves:[String] = []                 // global variable to retain all game moves
    var gameMoves2:[String] = []                // global variable to retain all game moves
                                                // with AI comments
    
    var checkMateCondition:Bool = false         // checkmate exists
    
    
    init(viewController: ViewController) {
        theChessBoard = ChessBoard.init(viewController: viewController)
        moveCount = 1
        firstHalfMove = ""
        
        // on segue to chess board viewcontroller use the dispMove label to remind
        // the user what mode was selected (in case they accidentally selected wrong mode)
        theChessBoard.vc.dispMove.text = theChessBoard.vc.isAgainstAI ? "Single User Mode (You vs iPhone)" : "Multiplayer mode (You vs somebody else)"
        
    }
    
    func getArrayOfPossibleMoves(forPiece piece: UIChessPiece) -> [BoardIndex] {
       
        var arrayOfMoves: [BoardIndex] = []
        let source = theChessBoard.getIndex(forChessPiece: piece)!
        
        for row in 0..<theChessBoard.ROWS {
            for col in 0..<theChessBoard.COLS {
                
                let dest = BoardIndex(row: row, col: col)
                
                if isNormalMoveValid(forPiece: piece, fromIndex: source, toIndex: dest) {
                    arrayOfMoves.append(dest)
                }
            }
        }
        
        return arrayOfMoves
    }
    
    func makeAIMove() {
        
        // get the white king if possible
        if getPlayerChecked() == "White" {
            for aChessPiece in theChessBoard.vc.chessPieces {
                if aChessPiece.color == #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1) {
                    
                    guard let source = theChessBoard.getIndex(forChessPiece: aChessPiece) else {
                        continue
                    }
                    
                    guard let dest = theChessBoard.getIndex(forChessPiece: theChessBoard.whiteKing) else {
                        continue
                    }
                    
                    if isNormalMoveValid(forPiece: aChessPiece, fromIndex: source, toIndex: dest) {
                        move(piece: aChessPiece, fromIndex: source, toIndex: dest, toOrigin: theChessBoard.whiteKing.frame.origin)
                        // AI made the move for Black so update the dispMove label with Black's move
                        checkMateCondition = true
                        theChessBoard.vc.dispMove.text = calcAlgebraicNotation(piece: aChessPiece, fromIndex: source, toIndex: dest, mode: "Normal")
                        print("AI: ATTACKED WHITE KING")
                        return
                    }
                    
                }
            }
        }
        
        // attack undefended white piece, if there is no check on black king
        if getPlayerChecked() == nil {
            if didAttackUndefendedPiece() {
                print("AI: ATTACKED UNDEFENDED PIECE")
                return
            }
        }
        
        var moveFound:Bool = false
        var numberOfTriesToEscapeCheck:Int = 0
        
        searchForMoves: while moveFound == false {
            
            // get random piece
            let randChessPiecesArrayIndex = Int(arc4random_uniform(UInt32(theChessBoard.vc.chessPieces.count)))
            let chessPieceToMove = theChessBoard.vc.chessPieces[randChessPiecesArrayIndex]
            
            guard chessPieceToMove.color == #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1) else {
                continue searchForMoves
            }
            
            // get random move
            let movesArray = getArrayOfPossibleMoves(forPiece: chessPieceToMove)
            guard movesArray.isEmpty == false else {
                continue searchForMoves
            }
            
            let randMovesArrayIndex = Int(arc4random_uniform(UInt32(movesArray.count)))
            let randDestIndex = movesArray[randMovesArrayIndex]
            let destOrigin = ChessBoard.getFrame(forRow: randDestIndex.row, forCol: randDestIndex.col).origin
            
            guard let sourceIndex = theChessBoard.getIndex(forChessPiece: chessPieceToMove) else {
                continue searchForMoves
            }
            
            // simulate the move on board matrix
            let pieceTaken = theChessBoard.board[randDestIndex.row][randDestIndex.col]
            theChessBoard.board[randDestIndex.row][randDestIndex.col] = theChessBoard.board[sourceIndex.row][sourceIndex.col]
            theChessBoard.board[sourceIndex.row][sourceIndex.col] = Dummy()
            
            if numberOfTriesToEscapeCheck < 1000 {
                guard getPlayerChecked() != "Black" else {
                    // undo move
                    theChessBoard.board[sourceIndex.row][sourceIndex.col] = theChessBoard.board[randDestIndex.row][randDestIndex.col]
                    theChessBoard.board[randDestIndex.row][randDestIndex.col] = pieceTaken
                    
                    numberOfTriesToEscapeCheck += 1
                    continue searchForMoves
                }
            } else {
                // tried 1000 moves so it has to be checkmate
                print ("CheckMate")
                
                // remove the black king so the rest of the code works 'naturally'
                theChessBoard.remove(piece: theChessBoard.blackKing)
                
                // update the NotationViewController with the last move
                firstHalfMove! = firstHalfMove!.replacingOccurrences(of: "+", with: "#")
                gameMoves.append(firstHalfMove!)
                gameMoves2.append(firstHalfMove!)
                
                // hard exit due to checkmate
                break
            }
            
            // undo move
            theChessBoard.board[sourceIndex.row][sourceIndex.col] = theChessBoard.board[randDestIndex.row][randDestIndex.col]
            theChessBoard.board[randDestIndex.row][randDestIndex.col] = pieceTaken
            
            // try best move if any good one
            if didBestMoveForAI(forScoreOver: appSettings.AIScoreLimit!) {
                print("AI: DID MAKE BEST MOVE")
                
                return
            }
            
            // insure contemplated moved doesn't leave black in check
            if doesMoveClearCheck(piece: chessPieceToMove, fromIndex: sourceIndex, toIndex: randDestIndex) {

                // make the AI move
                if numberOfTriesToEscapeCheck == 0 || numberOfTriesToEscapeCheck == 1000 {
                    print("AI: MADE SIMPLE RANDOM MOVE")
                    theChessBoard.vc.AIFeedBack = "AI: Simple Random Move"
                } else {
                    print("AI: MADE RANDOM MOVE TO ESCAPE CHECK")
                    theChessBoard.vc.AIFeedBack = "AI: Escaped Check"
                }
                
                makeAIMoveAndUpdateNotation(chessPieceToMove: chessPieceToMove, sourceIndex: sourceIndex, destIndex: randDestIndex, destOrigin: destOrigin)
                
                
                moveFound = true
            } else {
                moveFound = false
            }
        }
    }
    
    func makeAIMoveAndUpdateNotation(chessPieceToMove: UIChessPiece, sourceIndex: BoardIndex, destIndex: BoardIndex, destOrigin: CGPoint ) {
        
        move(piece: chessPieceToMove, fromIndex: sourceIndex, toIndex: destIndex, toOrigin: destOrigin)
        
        // AI made a move - see if a pawn promotion should occur
        if theChessBoard.vc.shouldPromotePawn() {
            theChessBoard.vc.promote(pawn: getPawnToBePromoted()!, into: "Queen")
        }
        
        // AI made the move for Black so update the dispMove label with Black's move
        theChessBoard.vc.dispMove.text = calcAlgebraicNotation(piece: chessPieceToMove, fromIndex: sourceIndex, toIndex: destIndex, mode: "Normal")
        
        // for visual clarity turn black piece just moved to red and set
        // ViewController variable "chessPieceToSetBackToBlack" to this chess piece
        // so it can immediately be turned back to black when the player touches to screen
        chessPieceToMove.textColor = .red
        theChessBoard.vc.chessPieceToSetBackToBlack = chessPieceToMove
        
    }
    
    func getScoreForLocation(ofPiece aChessPiece: UIChessPiece) -> Int {
        
        var locationScore:Int = 0
        
        guard let source = theChessBoard.getIndex(forChessPiece: aChessPiece) else {
            return 0
        }
        
        for row in 0..<theChessBoard.ROWS {
            for col in 0..<theChessBoard.COLS {
                
                let dest = BoardIndex(row: row, col: col)
                
                
                // only increase locationScore if dest has a white chess piece on it
                // and black has a legal move to capture that piece
                // chess piece on dest guaranteed to be white since canAttackAllies set to false
                // locationScore is increased by value of chess piece on dest
                // (Pawn=1, Knight=2, Bishop=3, Rook=4, Queen=5, King=6)
                // need to divide .tag value by 10 to drop off the 2nd digit (which is the color code)
                if theChessBoard.board[row][col] is UIChessPiece {
                    if isNormalMoveValid(forPiece: aChessPiece, fromIndex: source, toIndex: dest, canAttackAllies: false) {
                        locationScore += Int((theChessBoard.board[row][col] as? UIChessPiece)!.tag) / 10
                    }
                }
            }
        }
        // increase locationScore by appSettings.AIScoreLimit if it wasn't 0 to account
        // for a Pawn only being worth 1
        if locationScore > 0 {
            locationScore += appSettings.AIScoreLimit!
        }
        return locationScore
    }
    
    func didBestMoveForAI(forScoreOver limit: Int) -> Bool {
        
        guard getPlayerChecked() != "Black" else {
            return false
        }
        
        var bestNetScore:Int = -10
        var bestPiece:UIChessPiece!
        var bestDest:BoardIndex!
        var bestSource:BoardIndex!
        var bestOrigin:CGPoint!
        
        for aChessPiece in theChessBoard.vc.chessPieces {
            
            guard aChessPiece.color == #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1) else {
                continue
            }
            
            guard let source = theChessBoard.getIndex(forChessPiece: aChessPiece) else {
                continue
            }
            
            let actualLocationScore = getScoreForLocation(ofPiece: aChessPiece)
            let possibleDestinations = getArrayOfPossibleMoves(forPiece: aChessPiece)
            
            for dest in possibleDestinations {
                
                var nextLocationScore:Int = 0
                
                // simulate move
                let pieceTaken = theChessBoard.board[dest.row][dest.col]
                theChessBoard.board[dest.row][dest.col] = theChessBoard.board[source.row][source.col]
                theChessBoard.board[source.row][source.col] = Dummy()
                
                nextLocationScore = getScoreForLocation(ofPiece: aChessPiece)
                
                let netScore = nextLocationScore - actualLocationScore
                
                if netScore > bestNetScore {
                    bestNetScore = netScore
                    bestPiece = aChessPiece
                    bestDest = dest
                    bestSource = source
                    bestOrigin = ChessBoard.getFrame(forRow: bestDest.row, forCol: bestDest.col).origin
                }
                
                // undo move
                theChessBoard.board[source.row][source.col] = theChessBoard.board[dest.row][dest.col]
                theChessBoard.board[dest.row][dest.col] = pieceTaken
            }
        }
                
        if bestNetScore > limit {
            
            theChessBoard.vc.AIFeedBack = "AI: Made best move"
            theChessBoard.vc.AIFeedBack += "\n AI: Best Net Score: \(bestNetScore)"
            makeAIMoveAndUpdateNotation(chessPieceToMove: bestPiece, sourceIndex: bestSource, destIndex: bestDest, destOrigin: bestOrigin)
            
            print("AI: BEST NET SCORE: \(bestNetScore)")
            return true
        }
        
        
        return false
    }
    
    func didAttackUndefendedPiece() ->Bool {
        
        loopThatTraversesChessPieces: for attackingChessPiece in theChessBoard.vc.chessPieces {
            
            guard attackingChessPiece.color ==  #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)  else {
                continue loopThatTraversesChessPieces
            }
            
            guard let source = theChessBoard.getIndex(forChessPiece: attackingChessPiece) else {
                continue loopThatTraversesChessPieces
            }
            
            let possibleDestinations = getArrayOfPossibleMoves(forPiece: attackingChessPiece)
            
            searchForUndefendedWhitePieces: for attackedIndex in possibleDestinations {
                guard let attackedChessPiece = theChessBoard.board[attackedIndex.row][attackedIndex.col] as? UIChessPiece else {
                    continue searchForUndefendedWhitePieces
                }
                
                for row in 0..<theChessBoard.ROWS {
                    for col in 0..<theChessBoard.COLS {
                        
                        guard let defendingChessPiece = theChessBoard.board[row][col] as? UIChessPiece, defendingChessPiece.color == #colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 1) else {
                            continue
                        }
                        
                        let defendingIndex = BoardIndex(row: row, col: col)
                        
                        if isNormalMoveValid(forPiece: defendingChessPiece, fromIndex: defendingIndex, toIndex: attackedIndex, canAttackAllies: true) {
                            continue searchForUndefendedWhitePieces
                            
                        }
                    }
                }
                
                // need to record the attacked piece for calcAlgebraicNotation
                pieceToRemove = theChessBoard.board[attackedIndex.row][attackedIndex.col]
                theChessBoard.vc.AIFeedBack = "AI: took undefended piece"
                
                makeAIMoveAndUpdateNotation(chessPieceToMove: attackingChessPiece, sourceIndex: source, destIndex: attackedIndex, destOrigin: attackedChessPiece.frame.origin)
                
                return true
            }
        }
        
        return false
    }
    
    func getPawnToBePromoted() -> Pawn? {
        for chessPiece in theChessBoard.vc.chessPieces {
            if let pawn = chessPiece as? Pawn {
                let pawnIndex = ChessBoard.indexOf(origin: pawn.frame.origin)
                if pawnIndex.row == 0 || pawnIndex.row == 7 {
                    return pawn
                }
            }
        }
        
        return nil
    }
    
    func getPlayerChecked() -> String? {
        
        guard let whiteKingIndex = theChessBoard.getIndex(forChessPiece: theChessBoard.whiteKing)
        else {
            return nil
        }
        
        guard let blackKingIndex = theChessBoard.getIndex(forChessPiece: theChessBoard.blackKing)
        else {
            return nil
        }
        
        for row in 0..<theChessBoard.ROWS {
            for col in 0..<theChessBoard.COLS {
                if let chessPiece = theChessBoard.board[row][col] as? UIChessPiece {
                    
                    let chessPieceIndex = BoardIndex(row: row, col: col)
                    
                    if chessPiece.color == #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1) || chessPiece.color == .red {
                        if isNormalMoveValid(forPiece: chessPiece, fromIndex: chessPieceIndex, toIndex: whiteKingIndex) {
                            return "White"
                        }
                    } else {
                        if isNormalMoveValid(forPiece: chessPiece, fromIndex: chessPieceIndex, toIndex: blackKingIndex) {
                            return "Black"
                        }
                    }
                }
            }
        }
        return nil
    }
    
    // only returns true if one of the kings is no longer on the board
    func isGameOver() -> Bool {
        if didSomeBodyWin() {
            return true
        }
        return false
    }
    
    // decides winner by checking for each color's king
    func didSomeBodyWin() -> Bool {
        if !theChessBoard.vc.chessPieces.contains(theChessBoard.whiteKing) {
            winner = "Black"
            return true
        }
        if !theChessBoard.vc.chessPieces.contains(theChessBoard.blackKing) {
            winner = "White"
            return true
        }
        return false
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
            AudioServicesPlayAlertSoundWithCompletion(SystemSoundID(kSystemSoundID_Vibrate)) { }
            theChessBoard.vc.dispMove.textColor = isWhiteTurn ? #colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 1) : #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
            return false
        }
        
        guard isTurnColor(sameAsPiece: piece) else {
            theChessBoard.vc.dispMove.text = "NOT"
            theChessBoard.vc.dispMove.text! += isWhiteTurn ? " BLACK'S TURN" : " WHITE'S TURN"
            theChessBoard.vc.dispMove.textColor = isWhiteTurn ? #colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 1) : #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
            AudioServicesPlayAlertSoundWithCompletion(SystemSoundID(kSystemSoundID_Vibrate)) { }
            return false
        }
               
        return isNormalMoveValid(forPiece: piece, fromIndex: sourceIndex, toIndex: destIndex)
    }
    
    
    // this function will be the heart & soul of the chess logic engine to insure a move is valid
    // before allowing it to be considered by the chess engine.
    // two basic checks are done first: 1) moving the piece onto it's own square
    //                                  2) trying to attack one of it's own pieces
    
    // optional parameter of canAttackAllies is set to false by default.  Any call to this function
    // that sets this value to true will skip the guard statement that insures one color isn't
    // attacking itself.  This is only used when the AI is making a move for black and the AI is
    // testing all white pieces on the board to see if they are defended, or not.  To do this we
    // allow white to attack white during the testing in didAttackUndefendedPiece(..)
    func isNormalMoveValid(forPiece piece: UIChessPiece, fromIndex source: BoardIndex, toIndex dest: BoardIndex, canAttackAllies: Bool = false) -> Bool {
        

        // suppress the message if the AI is making moves since it tests many possibilities
        // that generate the messages
        guard source != dest else {
            if isWhiteTurn || !theChessBoard.vc.isAgainstAI {
                theChessBoard.vc.dispMove.text = "MOVING PIECE ON ITS OWN POSITION"
                AudioServicesPlayAlertSoundWithCompletion(SystemSoundID(kSystemSoundID_Vibrate)) { }
            }
            theChessBoard.vc.dispMove.textColor = isWhiteTurn ? #colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 1) : #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
            return false
        }
 
        if !canAttackAllies {
            // suppress the message if the AI is making moves since it tests many possibilities
            // that generate the messages
            guard !isAttackingAlliedPiece(sourceChessPiece: piece, destIndex: dest) else {
                if isWhiteTurn || !theChessBoard.vc.isAgainstAI {
                    theChessBoard.vc.dispMove.text = "ATTACKING YOUR OWN PIECE"
                    AudioServicesPlayAlertSoundWithCompletion(SystemSoundID(kSystemSoundID_Vibrate)) { }
                }
                theChessBoard.vc.dispMove.textColor = isWhiteTurn ? #colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 1) : #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
                return false
            }
        }

        var pieceMovedNotPawn:Bool = true
        
        switch piece {
        case is Pawn:
            pieceMovedNotPawn = false
            return isMoveValid(forPawn: piece as! Pawn, fromIndex: source, toIndex: dest)
        case is Rook, is Bishop, is Queen:
            return isMoveValid(forRookOrBishopOrQueen: piece, fromIndex: source, toIndex: dest)
        case is Knight:
            if !(piece as! Knight).doesMoveSeemFine(fromIndex: source, toIndex: dest) {
                return false
            }
            break
        case is King:
            return isMoveValid(forKing: piece as! King, fromIndex: source, toIndex: dest)
        default:
            break
        }
        
        // if the piece moved wasn't a pawn then zero out the valid en Passant string
        if pieceMovedNotPawn {
            if piece.color == #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1) {
                theChessBoard.vc.blackPawnForEnPassant = ""
            } else {
                theChessBoard.vc.whitePawnForEnPassant = ""
            }
        }
        
        return true
    }
    
    func isMoveValid(forPawn pawn: Pawn, fromIndex source: BoardIndex, toIndex dest: BoardIndex) -> Bool {
        
        // basic check of legal pawn movement (no consideration of board state)
        if !pawn.doesMoveSeemFine(fromIndex: source, toIndex: dest) {
            return false
        }
        
        // advanced check of legal pawn movement with full consideration of board state
        
        // no attack (remaining in same column)
        if source.col == dest.col {
            // if pawn advanced by 2
            // insure there were no chess pieces in the 1st square or the dest square
            if pawn.hasAdvancedByTwo {
                var moveForward = 0         // variable to check square pawn moved past
                
                // set moveForward based on color of moving piece
                if pawn.color == #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1) {
                    moveForward = 1
                } else {
                    moveForward = -1
                }
        
                // if the dest square is a Dummy and the square the pawn moved past is a dummy
                // then we have a good move
                if theChessBoard.board[dest.row][dest.col] is Dummy && theChessBoard.board[dest.row - moveForward][dest.col] is Dummy {
                    // update the en Passant string - this pawn subject to en Passant
                    if pawn.color == #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1) {
                        theChessBoard.vc.blackPawnForEnPassant = String(dest.row) + String(dest.col)
                    } else {
                        theChessBoard.vc.whitePawnForEnPassant = String(dest.row) + String(dest.col)
                    }
                    return true
                }
            // if pawn advanced by 1
            // insure there is no chess piece in the dest square
            } else {
                // if the dest square is a dummy then we have a good move
                if theChessBoard.board[dest.row][dest.col] is Dummy {
                    // update the en Passant string for - this pawn NOT subject to en Passant
                    if pawn.color == #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1) {
                        theChessBoard.vc.blackPawnForEnPassant = ""
                    } else {
                        theChessBoard.vc.whitePawnForEnPassant = ""
                    }
                    return true
                }
            }
        } else {
        // attacking some piece (changing column to the left or right)
        // insure the dest square is NOT a Dummy (actually has a chess piece on it)
            if !(theChessBoard.board[dest.row][dest.col] is Dummy) {
                return true
            } else {
                // the dest square IS a Dummy so handle possible en Passant move
                
                // set attackRow based on color of pawn
                var attackRow:Int = 0
                switch pawn.color {
                case #colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 1):
                    attackRow = 1
                case #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1):
                    attackRow = -1
                default:
                    break
                }
                
                
                // if there isn't a pawn behind dest then it isn't en Passant and it's an illegal move
                guard let attackPiece = theChessBoard.board[dest.row + attackRow][dest.col] as? Pawn else {
                    return false
                }
                
                // set default en Passant allowed to false
                var enPassantValid:Bool = false
                
                // make sure the piece being attacked JUST moved forward two squares
                if pawn.color == #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1) {
                    if theChessBoard.vc.whitePawnForEnPassant == String(dest.row + attackRow) + String(dest.col) {
                        enPassantValid = true
                    }
                } else {
                    if theChessBoard.vc.blackPawnForEnPassant == String(dest.row + attackRow) + String(dest.col) {
                        enPassantValid = true
                    }
                }
                
                // if en Passant is allowed then
                // also make sure there is a pawn behind dest so make sure it's the opponent color
                if attackPiece.color != pawn.color && enPassantValid {
                    // correct color so we have a valid en Passant move....almost
                    if (pawn.color == #colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 1) && dest.row == 2) || (pawn.color == #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1) && dest.row == 5) {
                        // dest.row is correct row so it's a legal en Passant move
                        // remove the attacked pawn and return true (legal move)
                        theChessBoard.remove(piece: attackPiece)
                        enPassantPawn = attackPiece
                        return true
                    } else {
                        // incorrect row for en Passant move so it's an illegal move
                        return false
                    }
                } else {
                    // incorrect color so not en Passant move and it's an illegal move
                    return false
                }
            }
            
        }
        
        // falling thru to this point means all of the checks failed so
        // it is definitely an illegal move from a legal chess move point of view
        // and/or from the state of the board (pieces in the way, nothing to attack, etc.)
        return false
    }
    
    func isMoveValid(forRookOrBishopOrQueen piece: UIChessPiece, fromIndex source: BoardIndex, toIndex dest: BoardIndex) -> Bool {
        
        switch piece {
        case is Rook:
            // basic check of legal rook movement (no consideration of board state)
            if !(piece as! Rook).doesMoveSeemFine(fromIndex: source, toIndex: dest) {
                return false
            }
        case is Bishop:
            // basic check of legal bishop movement (no consideration of board state)
            if !(piece as! Bishop).doesMoveSeemFine(fromIndex: source, toIndex: dest) {
                return false
            }
        default:
            // basic check of legal queen movement (no consideration of board state)
            if !(piece as! Queen).doesMoveSeemFine(fromIndex: source, toIndex: dest) {
                return false
            }
        }
        
        // advanced check for bishop/rook/queen
        var increaseRow:Int = 0
        
        // set what increaseRow is will be for each iteration
        if dest.row - source.row != 0 {
            increaseRow = (dest.row - source.row) / abs(dest.row - source.row)
        }
        
        var increaseCol:Int = 0
        
        // set what increaseCol will be for each iteration
        if dest.col - source.col != 0 {
            increaseCol = (dest.col - source.col) / abs(dest.col - source.col)
        }
        
        var nextRow:Int = source.row + increaseRow
        var nextCol:Int = source.col + increaseCol
        
        // check each square being passed over
        // if any square contains a chess piece then we're done
        // and the move will fail
        while nextRow != dest.row || nextCol != dest.col {
            if !(theChessBoard.board[nextRow][nextCol] is Dummy) {
                return false
            }
            
            nextRow += increaseRow
            nextCol += increaseCol
        }
        
        // if the piece is a Rook and the code gets here then the Rook has moved
        switch (piece) {
        case is Rook:
            (piece as! Rook).didMove = true
        default:
            break
        }
        
        return true
    }
    
    func doesMoveClearCheck(piece pieceDragged: UIChessPiece, fromIndex source: BoardIndex, toIndex dest: BoardIndex) -> Bool {
        
        // default return value of function is true - assume move does clear check
        var retVal:Bool = true
                
        // simulate the move on board matrix
        let pieceTaken = theChessBoard.board[dest.row][dest.col]
        theChessBoard.board[dest.row][dest.col] = theChessBoard.board[source.row][source.col]
        theChessBoard.board[source.row][source.col] = Dummy()
        
        // does check condition still exist and is it a valid check condition
        if (getPlayerChecked() == "Black" && !isWhiteTurn) || (getPlayerChecked() == "White" && isWhiteTurn) {
            retVal = false
        }
        
        // undo the move
        theChessBoard.board[source.row][source.col] = theChessBoard.board[dest.row][dest.col]
        theChessBoard.board[dest.row][dest.col] = pieceTaken
        
        if !retVal {
            theChessBoard.vc.dispMove.text = "Intended move leaves/puts King in check"
            AudioServicesPlayAlertSoundWithCompletion(SystemSoundID(kSystemSoundID_Vibrate)) { }
        }

        
        return retVal
    }
    
    // check to insure squares king is passing over on the castle move are clear (Dummy)
    func castlePathIsClear(fromIndex source: BoardIndex, toIndex dest: BoardIndex) -> Bool {
        
        // default return value - assume path is clear
        var retVal:Bool = true
        
        var increaseCol:Int = 0
        
        if dest.col > source.col {
            increaseCol = 1
        } else {
            increaseCol = -1
        }
        
        var nextCol:Int = source.col + increaseCol
        
        // check each square being passed over
        // if any square contains a chess piece then we're done
        // and the move will fail
        while nextCol != dest.col {
            if !(theChessBoard.board[source.row][nextCol] is Dummy) {
                retVal = false
            }
            nextCol += increaseCol
        }
        
        
        // if castling to queen side need to be sure knight square is a dummy
        if increaseCol == -1 {
            nextCol += increaseCol
            if !(theChessBoard.board[source.row][nextCol] is Dummy) {
                retVal = false
            }
        }
        
        if !retVal {
            theChessBoard.vc.dispMove.text = "Castling Path is not clear!!"
            AudioServicesPlayAlertSoundWithCompletion(SystemSoundID(kSystemSoundID_Vibrate)) { }
        }
        
        
        return retVal
    }
    
    // function to move the rook in a castling move after all checks for legality have been cleared
    func castle(toRow:Int, toCol:Int, theRook:Rook, notation:String) {
    
        let rookDestOrigin = ChessBoard.getFrame(forRow: toRow, forCol: toCol).origin
        let rookSourceIndex = theChessBoard.getIndex(forChessPiece: theRook)!
        let rookDestIndex = BoardIndex(row: toRow, col: toCol)
        move(piece: theRook, fromIndex: rookSourceIndex, toIndex: rookDestIndex, toOrigin: rookDestOrigin)
        self.castleNotation = notation
        
    }
    
    func isCastlingFromThruIntoCheck(forKing: King, forRook rook: Rook) -> Bool {
        
        // default value - assume king is not castling from/thru/into check
        var retVal: Bool = false
        var boardIndexToCheck = [BoardIndex]()      // array of BoardIndex to check
        var checkingPiecesOfColor: UIColor?         // color of pieces to see if they are checking
                                                    // any of the squares king is moving from-to
        
        if forKing == theChessBoard.whiteKing {
            checkingPiecesOfColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        } else {
            checkingPiecesOfColor = #colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 1)
        }
        
        // setup the array of boardIndexToCheck[] based on which rook the king is castling to
        switch rook {
        case theChessBoard.whiteQueenRook:      // white queen side castle 0-0-0
            boardIndexToCheck.append(BoardIndex(row: 7, col: 4))
            boardIndexToCheck.append(BoardIndex(row: 7, col: 3))
            boardIndexToCheck.append(BoardIndex(row: 7, col: 2))
            break
        case theChessBoard.whiteKingRook:       // white king side castle 0-0
            boardIndexToCheck.append(BoardIndex(row: 7, col: 4))
            boardIndexToCheck.append(BoardIndex(row: 7, col: 5))
            boardIndexToCheck.append(BoardIndex(row: 7, col: 6))
            break
        case theChessBoard.blackQueenRook:      // black queen side castle 0-0-0
            boardIndexToCheck.append(BoardIndex(row: 0, col: 4))
            boardIndexToCheck.append(BoardIndex(row: 0, col: 3))
            boardIndexToCheck.append(BoardIndex(row: 0, col: 2))
            break
        case theChessBoard.blackKingRook:       // black king side castle 0-0
            boardIndexToCheck.append(BoardIndex(row: 0, col: 4))
            boardIndexToCheck.append(BoardIndex(row: 0, col: 5))
            boardIndexToCheck.append(BoardIndex(row: 0, col: 6))
            break
        default:
            break
        }
        
        // check all pieces of the opposite color to see if they have, or could have, a check
        // on any of the squares the king is moving from-to
        for thisBoardIndex in boardIndexToCheck {
            for row in 0..<theChessBoard.ROWS {
                for col in 0..<theChessBoard.COLS {
                    if let chessPiece = theChessBoard.board[row][col] as? UIChessPiece {
                        
                        let chessPieceIndex = BoardIndex(row: row, col: col)
                        
                        if chessPiece.color == checkingPiecesOfColor {
                            if isNormalMoveValid(forPiece: chessPiece, fromIndex: chessPieceIndex, toIndex: thisBoardIndex) {
                                retVal = true      // found a piece that has/causes check during castle
                            }
                        }
                    }
                }
            }
        }
        
        if retVal {
            theChessBoard.vc.dispMove.text = "Castling from, thru, or into check!!"
            AudioServicesPlayAlertSoundWithCompletion(SystemSoundID(kSystemSoundID_Vibrate)) { }
        }
        
        return retVal
    }
    
    func isMoveValid(forKing king: King, fromIndex source: BoardIndex, toIndex dest: BoardIndex) -> Bool {
        
        // set the default return value of this function to false
        var retVal:Bool = false
    
        // basic check of legal king movement (no consideration of board state)
        if !(king.doesMoveSeemFine(fromIndex: source, toIndex: dest)) {
              
            // falling in here means the king.doesMoveSeemFine returned false
            // before letting this function return false lets check to see if it
            // was possibly a castling move (which would have failed the basic doesMoveSeemFine() function
            // if it is a castling move then deal with it, update the board, and update the move display
            switch king == theChessBoard.whiteKing {
            case true:  // is white king attempting to castle?
                if source.row == 7 && dest.row == 7 && abs(source.col - dest.col) == 2 && king.didMove == false {
                    if dest.col == 2 {
                        if theChessBoard.whiteQueenRook.didMove == false {
                            if !castlePathIsClear(fromIndex: source, toIndex: dest) {
                                return false    // bail out immediately if path isn't clear
                            }
                            if isCastlingFromThruIntoCheck(forKing: king, forRook: theChessBoard.whiteQueenRook) {
                                return false    // bail out immediately if castling from/thru/into check
                            }
                            print ("castling to white queen side rook")
                            // need to move white queen rook from row = 7,col = 0 to row = 7,col = 3
                            castle(toRow: 7, toCol: 3, theRook: theChessBoard.whiteQueenRook, notation: "0-0-0")
                            retVal = true
                        }
                    }
                    if dest.col == 6 {
                        if theChessBoard.whiteKingRook.didMove == false {
                            if !castlePathIsClear(fromIndex: source, toIndex: dest) {
                                return false    // bail out immediately if path isn't clear
                            }
                            if isCastlingFromThruIntoCheck(forKing: king, forRook: theChessBoard.whiteKingRook) {
                                return false    // bail out immediately if castling from/thru/into check
                            }
                            print ("castling to white king side rook")
                            // need to move white king rook from row = 7,col = 7 to row = 7,col = 5
                            castle(toRow: 7, toCol: 5, theRook: theChessBoard.whiteKingRook, notation: "0-0")
                            retVal = true
                        }
                    }
                }
                break
            default:    // is black king attempting to castle?
                if source.row == 0 && dest.row == 0 && abs(source.col - dest.col) == 2 && king.didMove == false {
                    if dest.col == 2 {
                        if theChessBoard.blackQueenRook.didMove == false {
                            if !castlePathIsClear(fromIndex: source, toIndex: dest) {
                                return false    // bail out immediately if path isn't clear
                            }
                            if isCastlingFromThruIntoCheck(forKing: king, forRook: theChessBoard.blackQueenRook) {
                                return false    // bail out immediately if castling from/thru/into check
                            }
                            print ("castling to black queen side rook")
                            // need to move black queen rook from row = 0,col = 0 to row = 0,col = 3
                            castle(toRow: 0, toCol: 3, theRook: theChessBoard.blackQueenRook, notation: "0-0-0")
                            retVal = true
                        }
                    }
                    if dest.col == 6 {
                        if theChessBoard.blackKingRook.didMove == false {
                            if !castlePathIsClear(fromIndex: source, toIndex: dest) {
                                return false    // bail out immediately if path isn't clear
                            }
                            if isCastlingFromThruIntoCheck(forKing: king, forRook: theChessBoard.blackKingRook) {
                                return false    // bail out immediately if castling from/thru/into check
                            }
                            print ("castling to black king side rook")
                            // need to move black king side rook from row = 0,col=7 to row = 0,col = 5
                            castle(toRow: 0, toCol: 5, theRook: theChessBoard.blackKingRook, notation: "0-0")
                            retVal = true
                        }
                    }
                }
                break
            }
            // end of check for castling move
            
            return retVal
        }
        
        // advanced check of legal king movement with full consideration of board state
        if isOpponentKing(nearKing: king, thatGoesTo: dest) {
            return false
        }
        
        // if the code gets here then the King has moved
        king.didMove = true
        return true
    }
    
    func isOpponentKing(nearKing movingKing: King, thatGoesTo destIndexOfMovingKing: BoardIndex) -> Bool {

        // which king is the current opponent king
        var theOpponentKing: King 
        
        if movingKing == theChessBoard.whiteKing {
            theOpponentKing = theChessBoard.blackKing
        } else {
            theOpponentKing = theChessBoard.whiteKing
        }
        
        // get index of opponent king
        var indexOfOppenentKing: BoardIndex!
        
        for row in 0..<theChessBoard.ROWS {
            for col in 0..<theChessBoard.COLS {
                if let aKing = theChessBoard.board[row][col] as? King, aKing == theOpponentKing {
                    indexOfOppenentKing = BoardIndex(row: row, col: col)
                }
            }
        }

        // compute absolute difference between kings
        let differenceInRows = abs(indexOfOppenentKing.row - destIndexOfMovingKing.row)
        let differenceInColsl = abs(indexOfOppenentKing.col - destIndexOfMovingKing.col)
        
        // if they're too close, move is invalid
        if case 0...1 = differenceInRows{
            if case 0...1 = differenceInColsl{
                return true
            }
        }
        
        return false
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
    
    
    // calculate the algebraic notation version of the move then return it to caller
    // std chess notation used is ranks:1 2 3 4 5 6 7 8 | files:a b c d e f g h | pieces:R N B Q K
    // mode can be "Normal" (both white & black move) or "WhiteOnly" (only white moves due to checkmate)
    func calcAlgebraicNotation(piece chessPieceToMove: UIChessPiece, fromIndex sourceIndex: BoardIndex, toIndex destIndex: BoardIndex, mode type:String) -> String {
        
        var algebraicSourcePosition:String?         // std chess notation for source position
        var algebraicDestPosition:String?           // std chess notation for destination position
        var conversion:Character?                   // conversion value (boardIndex to std chess)
        var thisPiece:String?                       // std chess id of piece being moved
        var captureMade:Bool                        // true if capture being made false if not
        var moveText:String?                        // string containing std chess notation of
                                                    // both halfs of current move - returned to caller
        var moveText2:String?                       // save as above but with
                                                    // std chss notation & AI Feedback comments
        
        let replacementText = "87654321"            // for conversion from board index to algebraic

        
        // set capture string to "x" if the target square was not empty (Dummy)
        // note:  pieceToRemove is a global variable for this class (ChessGame.swift)
        if pieceToRemove is Dummy && enPassantPawn == nil {
            captureMade = false
        } else {
            captureMade = true
        }
        
        // set thisPiece string value
        // to std chess notation id of piece
        if (chessPieceToMove is Pawn) {
            thisPiece = ""
        }
        if (chessPieceToMove is Rook) {
            thisPiece = "R"
        }
        if (chessPieceToMove is Knight) {
            thisPiece = "N"
        }
        if (chessPieceToMove is Bishop) {
            thisPiece = "B"
        }
        if (chessPieceToMove is Queen) {
            thisPiece = "Q"
        }
        if (chessPieceToMove is King) {
            thisPiece = "K"
        }
        
        // if another piece of the same type can move to
        // the same square need to differentiate piece
        // being moved notation in the following order of preference:
        // 1. add the file (col) of departure (if they differ)
        // 2. add the rank (row) of the departure (if files are same but ranks are different)
        // 3. add both the rank & file if neither, on it's own, can clearly differentiate (rare)
        // result is stored in addToNotation and then used further down this method
        var addToNotation:String = ""
        if !(chessPieceToMove is Pawn) && !(chessPieceToMove is King) {
            for row in 0..<theChessBoard.ROWS {
                for col in 0..<theChessBoard.COLS {
                    if let chessPiece = theChessBoard.board[row][col] as? UIChessPiece {
                        if chessPiece.color == chessPieceToMove.color && chessPiece.tag == chessPieceToMove.tag {
                            let chessPieceIndex = BoardIndex(row: row, col: col)
                            
                            // simulate move by removing the attacking piece at the destination
                            // and putting back the piece removed at the destination
                            let pieceTaken = theChessBoard.board[destIndex.row][destIndex.col]
                            if captureMade {
                                theChessBoard.board[destIndex.row][destIndex.col] = (pieceToRemove as? UIChessPiece)!
                            } else {
                                theChessBoard.board[destIndex.row][destIndex.col] = Dummy()
                            }
                            
                            // see if piece of same type can legally reach the same square
                            if isNormalMoveValid(forPiece: chessPiece, fromIndex: chessPieceIndex, toIndex: destIndex) {
                                if chessPieceIndex.row == destIndex.row {
                                    addToNotation += "R"
                                }
                                if chessPieceIndex.col == destIndex.col {
                                    if chessPieceIndex.col != sourceIndex.col {
                                        addToNotation += "R"
                                    } else {
                                        addToNotation += "C"
                                    }
                                }
                                // knight's require special handling
                                if chessPieceIndex.row == sourceIndex.row {
                                    addToNotation += "R"
                                } else if chessPieceIndex.col == sourceIndex.col {
                                    addToNotation += "C"
                                }
                            }
                            
                            // undo move by putting back the attacking piece at the destination
                            theChessBoard.board[destIndex.row][destIndex.col] = pieceTaken
                            
                            
                        }
                    }
                }
            }
        }
               
        // convert sourceIndex.row to algebraic notation value
        let characterIndex1 = replacementText.index(replacementText.startIndex, offsetBy: sourceIndex.row)
        conversion = replacementText[characterIndex1]
        
        // set final source position to algebraic notation using ASCII table value
        // 97 + 7 = 104 = h
        // 97 + 6 = 103 = g
        // .....
        // 97 + 0 = 97  = a
        algebraicSourcePosition = String(UnicodeScalar(UInt8(sourceIndex.col + 97)))
        
        // add appropriate notation to remove ambiguation due to like pieces on same col or row
        if addToNotation != "" {
            if addToNotation.contains("R") && addToNotation.contains("C") {
                thisPiece! +=  String(UnicodeScalar(UInt8(sourceIndex.col + 97))) + String(conversion!)
            } else if addToNotation.contains("C") {
                thisPiece! += String(conversion!)
            } else if addToNotation.contains("R") {
                thisPiece! += String(UnicodeScalar(UInt8(sourceIndex.col + 97)))
            }
        
    }

        // convert destIndex.row to algebraic notation value
        let characterIndex2 = replacementText.index(replacementText.startIndex, offsetBy: destIndex.row)
        conversion = replacementText[characterIndex2]
        
        // set final dest position to algebraic notation using ASCII table value
        // 97 + 7 = 104 = h
        // 97 + 6 = 103 = g
        // .....
        // 97 + 0 = 97  = a
        algebraicDestPosition = String(UnicodeScalar(UInt8(destIndex.col + 97))) + String(conversion!)
        
        // if capture was made by pawn alter the algebraicDestPosition string accordingly
        if captureMade && (chessPieceToMove is Pawn) {
            algebraicDestPosition = (algebraicSourcePosition?.prefix(1))! + "x" + algebraicDestPosition!
            captureMade = false
        }
        
        // if it was black's turn it's time to construct the move string
        // and return it to the calling function
        // if it was white's turn then save the move to firstHalfMove
        // and return nothing to the calling function
        if !(isWhiteTurn) {
            moveText = firstHalfMove!
            if self.castleNotation == "" {
                // generate text string in algebraic notation to return
                moveText! += " \(thisPiece ?? "")"
                moveText! += captureMade ? "x" : ""
                moveText! += "\(algebraicDestPosition ?? "")"
                if getPlayerChecked() == "White" {
                    moveText! += "+"
                }
            } else {
                moveText! += " " + self.castleNotation
                self.castleNotation = ""
            }
            if theChessBoard.vc.promotionType != "" {
                switch appSettings.promotionStyle {
                case "()":
                    moveText! += "(z)"
                default:
                    moveText! += "=z"
                }
                if theChessBoard.vc.promotionType.prefix(1) == "K" {
                    moveText! = moveText!.replacingOccurrences(of: "z", with: "N")
                    //moveText! += "=" + "N"
                } else {
                    moveText! = moveText!.replacingOccurrences(of: "z", with: theChessBoard.vc.promotionType.prefix(1))  
                }
            }
            if checkMateCondition  {
                moveText! = moveText!.replacingOccurrences(of: "+", with: "#")
            }
            
            if enPassantPawn != nil {
                moveText! += "ep"
            }
            // copy moveText to moveText2 and append AI feed back
            moveText2 = moveText! + "\n" + " " + theChessBoard.vc.AIFeedBack
            
            gameMoves.append(moveText!)         // append moveText to gameMoves[] array
            gameMoves2.append(moveText2!)       // append moveText2 to gameMoves2[] array
            
            // clear out AI Feedback for next move
            theChessBoard.vc.AIFeedBack = ""
        } else {
            firstHalfMove! = moveCount! < 10 ? " " : ""
            if self.castleNotation == "" {
                firstHalfMove! += "\(moveCount ?? 0): \(thisPiece ?? "")"
                firstHalfMove! += captureMade ? "x" : ""
                firstHalfMove! += "\(algebraicDestPosition ?? "")"
                if getPlayerChecked() == "Black" {
                    firstHalfMove! += "+"
                }
            } else {
                firstHalfMove! += "\(moveCount ?? 0): " + self.castleNotation + " "
                self.castleNotation = ""
            }
            if theChessBoard.vc.promotionType != "" {
                switch appSettings.promotionStyle {
                case "()":
                    firstHalfMove! += "(z)"
                default:
                    firstHalfMove! += "=z"
                }
                if theChessBoard.vc.promotionType.prefix(1) == "K" {
                    firstHalfMove! = firstHalfMove!.replacingOccurrences(of: "z", with: "N")
                    //moveText! += "=" + "N"
                } else {
                    firstHalfMove! = firstHalfMove!.replacingOccurrences(of: "z", with: theChessBoard.vc.promotionType.prefix(1))
                }
            }
            if enPassantPawn != nil {
                firstHalfMove! += "ep"
            }
            while firstHalfMove!.count < 10 {
                firstHalfMove! += " "
            }
            // White just won so update the gameMoves with the firstHalfMove!
            // since black won't be moving
            if type == "WhiteOnly" {
                if checkMateCondition  {
                    firstHalfMove! = firstHalfMove!.replacingOccurrences(of: "+", with: "#")
                }
                gameMoves.append(firstHalfMove!)
                gameMoves2.append(firstHalfMove!)
            }

        }
        // reset pawn promotionType
        theChessBoard.vc.promotionType = ""
        
        // reset enPassantPawn
        enPassantPawn = nil
        
        return !(isWhiteTurn) ? moveText! : ""
    }
    
    
}
