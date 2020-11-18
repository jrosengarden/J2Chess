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
        
    }
    
    func drag(piece: UIChessPiece, usingGestureRecognizer gestureRecognizer: UIPanGestureRecognizer) {
        
        let translation = gestureRecognizer.translation(in: view)
        
        piece.center = CGPoint(x: translation.x + piece.center.x, y: translation.y + piece.center.y)
        
        gestureRecognizer.setTranslation(CGPoint.zero, in: view)
    }


}

