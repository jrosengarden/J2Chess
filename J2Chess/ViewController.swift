//
//  ViewController.swift
//  JeffChess
//
//  Created by Jeff Rosengarden on 11/18/20.
//

import UIKit
import AudioToolbox

// create instance of AppSettings that is available globally
let appSettings = AppSettings()

class ViewController: UIViewController {
    
    @IBOutlet weak var lblDisplayTurnOUTLET: UILabel!
    @IBOutlet weak var lblDisplayCheckOUTLET: UILabel!
    @IBOutlet var panOUTLET: UIPanGestureRecognizer!
    @IBOutlet weak var dispMove: UILabel!
    
    var pieceDragged: UIChessPiece!
    var sourceOrigin: CGPoint!
    var destOrigin: CGPoint!
    static var SPACE_FROM_LEFT_EDGE: Int = 28
    static var SPACE_FROM_TOP_EDGE: Int = 110
    static var TILE_SIZE: Int = 40
    var myChessGame: ChessGame!
    var chessPieces: [UIChessPiece]!
    var chessPieceToSetBackToBlack: UIChessPiece?       // current piece that was turned red for clarity
    var whitePawnForEnPassant:String = ""
    var blackPawnForEnPassant:String = ""
    var AIFeedBack:String = ""
    var promotionType:String = ""
    
    // set in StartScreen.swift class based on which button was pressed
    // if playing computer set to true, if playing another human set to false
    var isAgainstAI: Bool!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        chessPieces = []
        myChessGame = ChessGame.init(viewController: self)
        
        self.navigationItem.rightBarButtonItem?.title = "Review Game" + " >"

    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        pieceDragged = touches.first!.view as? UIChessPiece
        
        if pieceDragged != nil {
            chessPieceToSetBackToBlack?.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)  // set red piece back to black
            sourceOrigin = pieceDragged.frame.origin
            dispMove.text = ""
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if pieceDragged != nil {
            drag(piece: pieceDragged, usingGestureRecognizer: panOUTLET)
        }
    }
    
    // for some reason touchesCancelled(..) is sometimes being called instead of touchesEnded(..)
    // this was causing the chess piece to be dropped in some random position that screwed up
    // the chesspiece array, the board and the game.  By implementing this function when a
    // spurious call to touchesCancelled is made the chess piece will simply be put back on it's
    // original square.  The user will then be able to move the piece properly.
    // It seems that iOS is making some decision on how much of a movement is significant
    // and how much is insignificant and should result in a call to touchesCancelled(..)
    // NOTE:  It seems to be a function of possibly moving the finger too fast???
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if pieceDragged != nil {
            pieceDragged.frame.origin = sourceOrigin
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
      
        if pieceDragged != nil {
            
            // calc raw x & y location of where touch ended
            let touchLocation = touches.first!.location(in: view)
            var x   = Int(touchLocation.x)
            var y   = Int(touchLocation.y)
            
            // backout blank space above (y) and to the left (x) of the game board
            // so we are only working with the board coordinate system
            x -= ViewController.SPACE_FROM_LEFT_EDGE
            y -= ViewController.SPACE_FROM_TOP_EDGE
            
            // 1st part of either equation gives us the column or row # where touch ended (0-7)
            // 2nd part of either equation then gives us the exact coordinates (x & y)
            // by multiplying the calculated col/row number by the tile size
            x = (x / ViewController.TILE_SIZE) * ViewController.TILE_SIZE
            y = (y / ViewController.TILE_SIZE) * ViewController.TILE_SIZE
            
            // now add back the blank space above (y) and to the left (x) of the game board
            // so we finally have the actual screen coordinates of where the touch ended
            x += ViewController.SPACE_FROM_LEFT_EDGE
            y += ViewController.SPACE_FROM_TOP_EDGE
            
            // set destOrigin to our calc'd x & y coordinates as a CGPoint
            destOrigin = CGPoint(x: x, y: y)
            
            
            // convert the sourceOrigin and destOrigin from CGPoint's to
            // actual ChessBoard (x,y) coordinates
            let sourceIndex = ChessBoard.indexOf(origin: sourceOrigin)
            let destIndex = ChessBoard.indexOf(origin: destOrigin)
            
            if myChessGame.isMoveValid(piece: pieceDragged, fromIndex: sourceIndex, toIndex: destIndex){
                
                if myChessGame.getPlayerChecked() != nil && !myChessGame.doesMoveClearCheck(piece: pieceDragged, fromIndex: sourceIndex, toIndex: destIndex) {
                    
                    print("Move did not clear check")
                    // move isn't valid so return dragged piece to it's origin
                    pieceDragged.frame.origin = sourceOrigin
                    return
                }
                
                if !myChessGame.doesMoveClearCheck(piece: pieceDragged, fromIndex: sourceIndex, toIndex: destIndex) {
                    
                    print("Move puts King in check")
                    // move isn't valid so return dragged piece to it's origin
                    pieceDragged.frame.origin = sourceOrigin
                    return
                }
                
                
                // move is valid so move the piece
                myChessGame.move(piece: pieceDragged, fromIndex: sourceIndex, toIndex: destIndex, toOrigin: destOrigin)

                // check if game is over and call displayWinner() if it is
                if myChessGame.isGameOver() {
                    
                    // White just won game so make sure NotationViewController is updated with last move
                    // since it's only 1/2 move and black's move is what usually kicks off the update
                    myChessGame.checkMateCondition = true
                    _ = myChessGame.calcAlgebraicNotation(piece: pieceDragged, fromIndex: sourceIndex, toIndex: destIndex, mode: "WhiteOnly")
                   
                    displayWinner()
                    return
                }
                
                if shouldPromotePawn() {
                    promptForPawnPromotion()
                } else {
                    resumeGame()
                }
            } else {
                // move isn't valid so return dragged piece to it's origin
                pieceDragged.frame.origin = sourceOrigin
            }
            
        }
    }
    
    func resumeGame() {
        
        // display checks if there are any
        displayCheck()
        
        // show move, in algebraic notation, on screen
        displayMove()
        
        // flip value of isWhiteTurn
        myChessGame.nextTurn()
        
        // update screen with which color's turn it is
        updateTurnOnScreen()
        
        // make AI move, if necessary
        if isAgainstAI == true && !myChessGame.isWhiteTurn {
            
            
            // reset pieceToRemove (needed for calcAlgebraicNotation)
            myChessGame.pieceToRemove = Dummy()
            
            myChessGame.makeAIMove()
            print("AI: -----------------")
            
            if myChessGame.isGameOver() {
                displayWinner()
                return
            }
            
            /* following redacted due to changes made to ChessGame.swift
            if shouldPromotePawn() {
                promote(pawn: myChessGame.getPawnToBePromoted()!, into: "Queen")
            }
            */
            
            if myChessGame.getPlayerChecked() != "Black" {
                displayCheck()
            }
            myChessGame.nextTurn()
            updateTurnOnScreen()
        }
    }
    
    func promote(pawn pawnToBePromoted: Pawn, into pieceName: String) {
        
        var pawnColor:UIColor = .clear
        
        // pawnToBePromoted might still be red so change it to black before the promotion occurs
        if pawnToBePromoted.color == .red {
            pawnColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        } else {
            pawnColor = pawnToBePromoted.color
        }
        let pawnFrame = pawnToBePromoted.frame
        let pawnIndex = ChessBoard.indexOf(origin: pawnToBePromoted.frame.origin)
        
        myChessGame.theChessBoard.remove(piece: pawnToBePromoted)
        
        switch pieceName {
        case "Queen":
            myChessGame.theChessBoard.board[pawnIndex.row][pawnIndex.col] = Queen(frame: pawnFrame, color: pawnColor, vc: self)
        case "Knight":
            myChessGame.theChessBoard.board[pawnIndex.row][pawnIndex.col] = Knight(frame: pawnFrame, color: pawnColor, vc: self)
        case "Rook":
            myChessGame.theChessBoard.board[pawnIndex.row][pawnIndex.col] = Rook(frame: pawnFrame, color: pawnColor, vc: self)
        case "Bishop":
            myChessGame.theChessBoard.board[pawnIndex.row][pawnIndex.col] = Bishop(frame: pawnFrame, color: pawnColor, vc: self)
        default:
            break
        }
        
        promotionType = pieceName
    }
    
    func promptForPawnPromotion() {
        if let pawnToPromote = myChessGame.getPawnToBePromoted() {
            
            let box = UIAlertController(title: "Pawn Promotion", message: "Choose Piece", preferredStyle: UIAlertController.Style.alert)
            
            box.addAction(UIAlertAction(title: "Queen", style: UIAlertAction.Style.default, handler: { action in self.promote(pawn: pawnToPromote, into: action.title!)
                self.resumeGame()
            }))
            box.addAction(UIAlertAction(title: "Knight", style: UIAlertAction.Style.default, handler: { action in self.promote(pawn: pawnToPromote, into: action.title!)
                self.resumeGame()
            }))
            box.addAction(UIAlertAction(title: "Bishop", style: UIAlertAction.Style.default, handler: { action in self.promote(pawn: pawnToPromote, into: action.title!)
                self.resumeGame()
            }))
            box.addAction(UIAlertAction(title: "Rook", style: UIAlertAction.Style.default, handler: { action in self.promote(pawn: pawnToPromote, into: action.title!)
                self.resumeGame()
            }))
            
            self.present(box, animated: true, completion: nil)
        }
    }
    
    func shouldPromotePawn() -> Bool{
        return(myChessGame.getPawnToBePromoted() != nil)
    }
    
    func displayCheck() {
        let playerChecked = myChessGame.getPlayerChecked()
        
        if playerChecked != nil {
            lblDisplayCheckOUTLET.text = playerChecked! + " is in check!"
            AudioServicesPlayAlertSoundWithCompletion(SystemSoundID(kSystemSoundID_Vibrate)) { }
        } else {
            lblDisplayCheckOUTLET.text = ""
        }
    }
    
    // displays multi-choice alert to user due to game being over
    func displayWinner() {
        // set up main UIAlert
        let box = UIAlertController(title: "Game Over", message: "\(myChessGame.winner!) wins", preferredStyle: UIAlertController.Style.alert)
        // create a review board action
        box.addAction(UIAlertAction(title: "Review chess board", style: UIAlertAction.Style.default, handler:{
            action in
            // No action will just dismiss the alert
        }))
        // create a back to main menu action using the unwind seque
        box.addAction(UIAlertAction(title: "Back to main menu", style: UIAlertAction.Style.default, handler: {
            action in self.performSegue(withIdentifier: "backToMainMenu", sender: self)
        }))
        
        // create a rematch action
        box.addAction(UIAlertAction(title: "Rematch", style: UIAlertAction.Style.default, handler: {
            
            action in
            
            // clear screen, chess pieces array, and board matrix
            for chessPiece in self.chessPieces {
                self.myChessGame.theChessBoard.remove(piece: chessPiece)
            }
            
            // create new game
            self.myChessGame = ChessGame(viewController: self)
            
            // update labels with game status
            self.updateTurnOnScreen()
            self.lblDisplayCheckOUTLET.text = nil
            
        }))
        
        self.present(box, animated: true, completion: nil)
    }
    
    // update screen text & color 
    func updateTurnOnScreen() {
        lblDisplayTurnOUTLET.text = myChessGame.isWhiteTurn ? "White's turn" : "Black's turn"
        lblDisplayTurnOUTLET.textColor = myChessGame.isWhiteTurn ? #colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 1) : #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
    }
    
    func drag(piece: UIChessPiece, usingGestureRecognizer gestureRecognizer: UIPanGestureRecognizer) {
        
        let translation = gestureRecognizer.translation(in: view)
        
        piece.center = CGPoint(x: translation.x + piece.center.x, y: translation.y + piece.center.y)
        
        gestureRecognizer.setTranslation(CGPoint.zero, in: view)
    }
    
    func displayMove() {
        
        // NOTE:  this function is called twice in a human vs human game
        //        and myChessGame.calcAlgebraicNotation properly constructs
        //        the first half of the move text (white's move) and the
        //        second half of the move text (black's move).
        //
        //        This function is only being called once in a human vs iPhone game
        //        It is called after White make's a move only so the call to
        //        myChessGame.calcAlgebraicNotation only has a chance to construct
        //        the first half of the move (white's move).  Black's move is updated
        //        to the display label (dispMove) in myChessGame.makeAIMove once a
        //        legal move has been figured out and executed.
        
        // convert the sourceOrigin and destOrigin from CGPoint's to
        // actual ChessBoard (x,y) coordinates
        let sourceIndex = ChessBoard.indexOf(origin: sourceOrigin)
        let destIndex = ChessBoard.indexOf(origin: destOrigin)
        
        // insure chess notation text is black
        self.dispMove.textColor =  #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        
        // calculate and display chess notation
        self.dispMove.text = myChessGame.calcAlgebraicNotation(piece: pieceDragged, fromIndex: sourceIndex, toIndex: destIndex, mode: "Normal")
        // debugging
        if self.dispMove.text != "" {
            print (self.dispMove.text!)
        }


    }
    
    // set hndParent to this viewcontroller (self) if moving to NotationViewController
    // this will allow NotationViewController to update it's textfield (txtGameMoves) with
    // the gameMoves[] array from ChessGame.swift
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if let hndNotationViewController = segue.destination as? NotationViewController {
            hndNotationViewController.hndParent = self
        }
        
    }

}

