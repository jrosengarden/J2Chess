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
    
    var pieceDragged: UIChessPiece!
    var sourceOrigin: CGPoint!
    var destOrigin: CGPoint!
    static var SPACE_FROM_LEFT_EDGE: Int = 27
    static var SPACE_FROM_TOP_EDGE: Int = 173
    static var TILE_SIZE: Int = 40
    var myChessGame: ChessGame!
    var chessPieces: [UIChessPiece]!
    
    
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
            
            let sourceIndex = BoardIndex(row: 0, col: 0)
            let destIndex = BoardIndex(row: 0, col: 0)
            
            if myChessGame.isMoveValid(piece: pieceDragged, fromIndex: sourceIndex, toIndex: destIndex){
                pieceDragged.frame.origin = destOrigin
            } else {
                pieceDragged.frame.origin = sourceOrigin
            }
            
        }
    }
    
    func drag(piece: UIChessPiece, usingGestureRecognizer gestureRecognizer: UIPanGestureRecognizer) {
        
        let translation = gestureRecognizer.translation(in: view)
        
        piece.center = CGPoint(x: translation.x + piece.center.x, y: translation.y + piece.center.y)
        
        gestureRecognizer.setTranslation(CGPoint.zero, in: view)
    }


}

