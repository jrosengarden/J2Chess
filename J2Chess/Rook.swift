//
//  Rook.swift
//  JeffChess
//
//  Created by Jeff Rosengarden on 11/18/20.
//

import UIKit

class Rook: UIChessPiece {
    
    var didMove:Bool = false        // track if Rook has moved (for castling)
    
    init(frame:CGRect, color: UIColor, vc: ViewController) {
        super.init(frame: frame)
        
        if color == #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1) {
            self.text = "♜"
        } else {
            self.text = "♖"
        }
        
        self.isOpaque = false
        self.textColor = color
        self.isUserInteractionEnabled = true
        self.textAlignment = .center
        self.font = self.font.withSize(PIECE_SIZE)
        
        vc.chessPieces.append(self)
        vc.view.addSubview(self)
    }

    func doesMoveSeemFine(fromIndex source: BoardIndex, toIndex dest: BoardIndex) -> Bool {
        
        if source.row == dest.row || source.col == dest.col {
            return true
        }
        
        return false
    }

    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }

}
