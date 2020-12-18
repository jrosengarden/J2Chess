//
//  ViewController.swift
//  JeffChess
//
//  Created by Jeff Rosengarden on 11/18/20.
//

import UIKit

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
    
    // set in StartScreen.swift class based on which button was pressed
    // if playing computer set to true, if playing another human set to false
    var isAgainstAI: Bool!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        chessPieces = []
        myChessGame = ChessGame.init(viewController: self)
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        pieceDragged = touches.first!.view as? UIChessPiece
        
        if pieceDragged != nil {
            sourceOrigin = pieceDragged.frame.origin
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if pieceDragged != nil {
            drag(piece: pieceDragged, usingGestureRecognizer: panOUTLET)
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
                
                // move is valid so move the piece
                myChessGame.move(piece: pieceDragged, fromIndex: sourceIndex, toIndex: destIndex, toOrigin: destOrigin)
                
                // display checks if there are any
                displayCheck()
                
                // show move, in algebraic notation, on screen
                displayMove(fromSourceSquare: sourceIndex, toDestSquare: destIndex)

                // check if game is over and call displayWinner() if it is
                if myChessGame.isGameOver() {
                    displayWinner()
                    return
                }
                
                // flip value of isWhiteTurn
                myChessGame.nextTurn()
                
                // update screen with which color's turn it is
                updateTurnOnScreen()
            } else {
                // move isn't valid so return dragged piece to it's origin
                pieceDragged.frame.origin = sourceOrigin
            }
            
        }
    }
    
    func displayCheck() {
        let playerChecked = myChessGame.getPlayerChecked()
        
        if playerChecked != nil {
            lblDisplayCheckOUTLET.text = playerChecked! + " is in check!"
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
    
    func displayMove(fromSourceSquare: BoardIndex, toDestSquare: BoardIndex) {
        self.dispMove.text = myChessGame.calcAlgebraicNotation(piece: pieceDragged, fromIndex: fromSourceSquare, toIndex: toDestSquare)
        // debugging
        if self.dispMove.text != "" {
            print (self.dispMove.text!)
        }


    }


}

