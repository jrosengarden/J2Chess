//
//  ChessGame.swift
//  JeffChess
//
//  Created by Jeff Rosengarden on 11/18/20.
//

import UIKit

class ChessGame: NSObject {
    
    var theChessBoard: ChessBoard!
    
    init(viewController: ViewController) {
        theChessBoard = ChessBoard.init(viewController: viewController)
    }
}
