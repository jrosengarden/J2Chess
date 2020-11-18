//
//  ExtensionUIChessPiece.swift
//  JeffChess
//
//  Created by Jeff Rosengarden on 11/18/20.
//

import UIKit

typealias UIChessPiece = UILabel

extension UIChessPiece: Piece {
    
    var x: CGFloat {
        get{
            return self.frame.origin.x
        }
        set {
            self.frame.origin.x = newValue
        }
    }
    
    var y: CGFloat {
        get{
            return self.frame.origin.y
        }
        set {
            self.frame.origin.y = newValue
        }
    }
    
    var color: UIColor {
        get {
            return self.textColor
        }
    }
}
