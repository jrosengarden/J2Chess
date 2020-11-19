//
//  Piece.swift
//  JeffChess
//
//  Created by Jeff Rosengarden on 11/18/20.
//

import UIKit
var PIECE_SIZE: CGFloat = 52

protocol Piece {
    var x: CGFloat {get set}
    var y: CGFloat {get set}
}
