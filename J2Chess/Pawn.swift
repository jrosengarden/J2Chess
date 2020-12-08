//
//  Pawn.swift
//  JeffChess
//
//  Created by Jeff Rosengarden on 11/18/20.
//

import UIKit

class Pawn: UIChessPiece {
    
    var hasAdvancedByTwo: Bool = false
    
    init(frame:CGRect, color: UIColor, vc: ViewController) {
        super.init(frame: frame)
        
        if color == #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1) {
            self.text = "♟︎"
        } else {
            self.text = "♙"
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
        // remember board index:
        //      row starts at 0 from the top and 7 at the bottom
        //      col starts at 0 from the left and 7 at the far right
        
        // check advance by 2
        if source.col == dest.col {
            if (source.row == 1 && dest.row == 3 && color == #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)) || (source.row == 6 && dest.row == 4 && color == #colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 1) ) {
                hasAdvancedByTwo = true
                return true
            }
        }
        
        hasAdvancedByTwo = false
        
        // check advance by 1
        var moveForward = 0
        
        if color == #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1) {
            moveForward = 1
        } else {
            moveForward = -1
        }
        
        if dest.row == source.row + moveForward {
            // check for movement; diagonal left, straight ahead, diagonal right
            if (dest.col == source.col - 1) || (dest.col == source.col) || (dest.col == source.col + 1) {
                return true
            }
        }
        
        return false
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }

}
