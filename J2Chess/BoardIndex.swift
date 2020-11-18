//
//  BoardIndex.swift
//  JeffChess
//
//  Created by Jeff Rosengarden on 11/18/20.
//


struct BoardIndex: Equatable {
    
    var row: Int
    var col: Int
    
    init(row: Int, col: Int) {
        self.row = row
        self.col = col
    }
    
    static func == (lhs: BoardIndex, rhs: BoardIndex) -> Bool {
        return (lhs.row == rhs.row && lhs.col == rhs.col)
    }
}
