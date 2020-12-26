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
    var winner: String?                         // set by didSomeBodyWin() function
    
    var moveCount:Int?                          // track move count for move display
    var firstHalfMove:String?                   // save current move until opponent moves
    var pieceToRemove:Piece?                    // global variable for piece (if any) at dest square
    
    var castleNotation:String = ""              // global variable to hold castling notation

    
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
                        return
                    }
                    
                }
            }
        }
        
        // attack undefended white piece, if there is no check on black king
        if getPlayerChecked() == nil {
            if didAttackUndefendedPiece() {
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
            }
            
            // undo move
            theChessBoard.board[sourceIndex.row][sourceIndex.col] = theChessBoard.board[randDestIndex.row][randDestIndex.col]
            theChessBoard.board[randDestIndex.row][randDestIndex.col] = pieceTaken
            
            // try best move if any good one
            if didBestMoveForAI(forScoreOver: 2) {
                return
            }
            
            move(piece: chessPieceToMove, fromIndex: sourceIndex, toIndex: randDestIndex, toOrigin: destOrigin)
            
            // AI made the move for Black so update the dispMove label with Black's move
            theChessBoard.vc.dispMove.text = calcAlgebraicNotation(piece: chessPieceToMove, fromIndex: sourceIndex, toIndex: randDestIndex)
            
            moveFound = true
        }
    }
    
    func didBestMoveForAI(forScoreOver limit: Int) -> Bool {
        return false
    }
    
    func didAttackUndefendedPiece() ->Bool {
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
                    
                    if chessPiece.color == #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1) {
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
        

        // suppress the message if the AI is making moves since it tests many possibilities
        // that generate the messages
        guard source != dest else {
            if isWhiteTurn || !theChessBoard.vc.isAgainstAI {
                theChessBoard.vc.dispMove.text = "MOVING PIECE ON ITS OWN POSITION"
            }
            theChessBoard.vc.dispMove.textColor = isWhiteTurn ? #colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 1) : #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
            print (theChessBoard.vc.dispMove.text!)
            return false
        }
 
        // suppress the message if the AI is making moves since it tests many possibilities
        // that generate the messages
        guard !isAttackingAlliedPiece(sourceChessPiece: piece, destIndex: dest) else {
            if isWhiteTurn || !theChessBoard.vc.isAgainstAI {
                theChessBoard.vc.dispMove.text = "ATTACKING YOUR OWN PIECE"
            }
                theChessBoard.vc.dispMove.textColor = isWhiteTurn ? #colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 1) : #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
                print(theChessBoard.vc.dispMove.text!)
                return false
                }

        
        switch piece {
        case is Pawn:
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
                    return true
                }
            // if pawn advanced by 1
            // insure there is no chess piece in the dest square
            } else {
                // if the dest square is a dummy then we have a good move
                if theChessBoard.board[dest.row][dest.col] is Dummy {
                    return true
                }
            }
        } else {
        // attacking some piece (changing column to the left or right)
        // insure the dest square is NOT a Dummy (actually has a chess piece on it)
            if !(theChessBoard.board[dest.row][dest.col] is Dummy) {
                return true
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
    
    // check to insure squares king is passing over on the castle move are clear (Dummy)
    func castlePathIsClear(fromIndex source: BoardIndex, toIndex dest: BoardIndex) -> Bool {
        
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
                return false
            }
            nextCol += increaseCol
        }
        
        
        return true
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
                            print ("castling to white queen side rook")
                            // need to move white queen rook from row = 7,col = 0 to row = 7,col = 3
                            let rookDestOrigin = ChessBoard.getFrame(forRow: 7, forCol: 3).origin
                            let rookSourceIndex = theChessBoard.getIndex(forChessPiece: theChessBoard.whiteQueenRook)!
                            let rookDestIndex = BoardIndex(row: 7, col: 3)
                            move(piece: theChessBoard.whiteQueenRook, fromIndex: rookSourceIndex, toIndex: rookDestIndex, toOrigin: rookDestOrigin)
                            self.castleNotation = "0-0-0"
                            retVal = true
                        }
                    }
                    if dest.col == 6 {
                        if theChessBoard.whiteKingRook.didMove == false {
                            if !castlePathIsClear(fromIndex: source, toIndex: dest) {
                                return false    // bail out immediately if path isn't clear
                            }
                            print ("castling to white king side rook")
                            // need to move white king rook from row = 7,col = 7 to row = 7,col = 5
                            let rookDestOrigin = ChessBoard.getFrame(forRow: 7, forCol: 5).origin
                            let rookSourceIndex = theChessBoard.getIndex(forChessPiece: theChessBoard.whiteKingRook)!
                            let rookDestIndex = BoardIndex(row: 7, col: 5)
                            move(piece: theChessBoard.whiteKingRook, fromIndex: rookSourceIndex, toIndex: rookDestIndex, toOrigin: rookDestOrigin)
                            self.castleNotation = "0-0"
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
                            print ("castling to black queen side rook")
                            // need to move black queen rook from row = 0,col = 0 to row = 0,col = 3
                            let rookDestOrigin = ChessBoard.getFrame(forRow: 0, forCol: 3).origin
                            let rookSourceIndex = theChessBoard.getIndex(forChessPiece: theChessBoard.blackQueenRook)!
                            let rookDestIndex = BoardIndex(row: 0, col: 3)
                            move(piece: theChessBoard.blackQueenRook, fromIndex: rookSourceIndex, toIndex: rookDestIndex, toOrigin: rookDestOrigin)
                            self.castleNotation = "0-0-0"
                            retVal = true
                        }
                    }
                    if dest.col == 6 {
                        if theChessBoard.blackKingRook.didMove == false {
                            if !castlePathIsClear(fromIndex: source, toIndex: dest) {
                                return false    // bail out immediately if path isn't clear
                            }
                            print ("castling to black king side rook")
                            // need to move black king side rook from row = 0,col=7 to row = 0,col = 5
                            let rookDestOrigin = ChessBoard.getFrame(forRow: 0, forCol: 5).origin
                            let rookSourceIndex = theChessBoard.getIndex(forChessPiece: theChessBoard.blackKingRook)!
                            let rookDestIndex = BoardIndex(row: 0, col: 5)
                            move(piece: theChessBoard.blackKingRook, fromIndex: rookSourceIndex, toIndex: rookDestIndex, toOrigin: rookDestOrigin)
                            self.castleNotation = "0-0"
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
    func calcAlgebraicNotation(piece chessPieceToMove: UIChessPiece, fromIndex sourceIndex: BoardIndex, toIndex destIndex: BoardIndex) -> String {
        
        var algebraicSourcePosition:String?         // std chess notation for source position
        var algebraicDestPosition:String?           // std chess notation for destination position
        var conversion:Int?                         // conversion value (boardIndex to std chess)
        var thisPiece:String?                       // std chess id of piece being moved
        var captureMade:Bool                        // true if capture being made false if not
        var moveText:String?                        // string containing std chess notation of
                                                    // both halfs of current move - returned to caller
        
        // set capture string to "x" if the target square was not empty (Dummy)
        // note:  pieceToRemove is a global variable for this class (ChessGame.swift)
        if pieceToRemove is Dummy {
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
        

        // convert sourceIndex.row to algebraic notation value
        switch sourceIndex.row {
        case 7:
            conversion = 1
        case 6:
            conversion = 2
        case 5:
            conversion = 3
        case 4:
            conversion = 4
        case 3:
            conversion = 5
        case 2:
            conversion = 6
        case 1:
            conversion = 7
        default:
            conversion = 8
        }
        
        // set final source position to algebraic notation
        switch sourceIndex.col {
        case 0:
            algebraicSourcePosition = "a" + String(conversion!)
        case 1:
            algebraicSourcePosition = "b" + String(conversion!)
        case 2:
            algebraicSourcePosition = "c" + String(conversion!)
        case 3:
            algebraicSourcePosition = "d" + String(conversion!)
        case 4:
            algebraicSourcePosition = "e" + String(conversion!)
        case 5:
            algebraicSourcePosition = "f" + String(conversion!)
        case 6:
            algebraicSourcePosition = "g" + String(conversion!)
        default:
            algebraicSourcePosition = "h" + String(conversion!)
        }

        
        // convert destIndex.row to algebraic notation value
        switch destIndex.row {
        case 7:
            conversion = 1
        case 6:
            conversion = 2
        case 5:
            conversion = 3
        case 4:
            conversion = 4
        case 3:
            conversion = 5
        case 2:
            conversion = 6
        case 1:
            conversion = 7
        default:
            conversion = 8
        }
        
        // set final destination position to algebraic notation
        switch destIndex.col {
        case 0:
            algebraicDestPosition = "a" + String(conversion!)
        case 1:
            algebraicDestPosition = "b" + String(conversion!)
        case 2:
            algebraicDestPosition = "c" + String(conversion!)
        case 3:
            algebraicDestPosition = "d" + String(conversion!)
        case 4:
            algebraicDestPosition = "e" + String(conversion!)
        case 5:
            algebraicDestPosition = "f" + String(conversion!)
        case 6:
            algebraicDestPosition = "g" + String(conversion!)
        default:
            algebraicDestPosition = "h" + String(conversion!)
        }
        
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
                if theChessBoard.vc.lblDisplayCheckOUTLET.text == "White is in check!" {
                    moveText! += "+"
                }
            } else {
                moveText! += " " + self.castleNotation
                self.castleNotation = ""
            }
        } else {
            if self.castleNotation == "" {
                firstHalfMove! = "\(moveCount ?? 0): \(thisPiece ?? "")"
                firstHalfMove! += captureMade ? "x" : ""
                //firstHalfMove! += "\(algebraicSourcePosition ?? "")"
                firstHalfMove! += "\(algebraicDestPosition ?? "")"
                if theChessBoard.vc.lblDisplayCheckOUTLET.text == "Black is in check!" {
                    firstHalfMove! += "+"
                }
            } else {
                firstHalfMove! = self.castleNotation + " "
                self.castleNotation = ""
            }
        }
        
        return !(isWhiteTurn) ? moveText! : ""
    }
    
    
}
