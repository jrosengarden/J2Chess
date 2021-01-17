//
//  Knight.swift
//  JeffChess
//
//  Created by Jeff Rosengarden on 11/18/20.
//

import UIKit

class Knight: UIChessPiece {
    
    init(frame:CGRect, color: UIColor, vc: ViewController) {
        super.init(frame: frame)
        
        // tag code:  1st Position = type of piece (1:Pawn, 2:Knight, 3:Bishop, 4:Rook, 5:Queen, 6:King)
        //            2nd Position = color of piece (0:White, 1:Black)
        
        if color == #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1) {
            self.text = "♞"
            self.tag = 21
        } else {
            self.text = "♘"
            self.tag = 20
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
        
        let rowsMoved = abs(dest.row - source.row)
        let colsMoved = abs(dest.col - source.col)
        
        if rowsMoved == 1 && colsMoved == 2 || rowsMoved == 2 && colsMoved == 1 {
            return true
        }
        
        return false
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }

}
