//
//  ChessBoard.swift
//  JeffChess
//
//  Created by Jeff Rosengarden on 11/18/20.
//

import UIKit

class ChessBoard: NSObject {
    
    var board: [[Piece]]!
    var vc: ViewController!
    let ROWS = 8
    let COLS = 8
    var whiteKing: King!
    var blackKing: King!
    

    static func getFrame(forRow row: Int, forCol col: Int) -> CGRect {
        
        let x = CGFloat(ViewController.SPACE_FROM_LEFT_EDGE + col * ViewController.TILE_SIZE)
        let y = CGFloat(ViewController.SPACE_FROM_TOP_EDGE + row * ViewController.TILE_SIZE)
        
        return CGRect(origin: CGPoint(x: x, y: y), size: CGSize(width: ViewController.TILE_SIZE, height: ViewController.TILE_SIZE))
    }
    
    init(viewController: ViewController) {
        
        vc = viewController
        
        //initialize the board matrix with dummies
        let oneRowOfBoard = Array(repeating: Dummy(), count: COLS)
        board = Array(repeating: oneRowOfBoard, count: ROWS)
        
        for row in 0..<ROWS {
            for col in 0..<COLS {
                switch row {
                case 0:
                    switch col {
                    case 0:
                        board[row][col] = Rook(frame: ChessBoard.getFrame(forRow: row, forCol: col), color:#colorLiteral(red: 0, green: 0, blue: 0, alpha: 1), vc: vc)
                    case 1:
                        board[row][col] = Knight(frame: ChessBoard.getFrame(forRow: row, forCol: col), color:#colorLiteral(red: 0, green: 0, blue: 0, alpha: 1), vc: vc)
                    case 2:
                        board[row][col] = Bishop(frame: ChessBoard.getFrame(forRow: row, forCol: col), color:#colorLiteral(red: 0, green: 0, blue: 0, alpha: 1), vc: vc)
                    case 3:
                        board[row][col] = Queen(frame: ChessBoard.getFrame(forRow: row, forCol: col), color:#colorLiteral(red: 0, green: 0, blue: 0, alpha: 1), vc: vc)
                    case 4:
                        board[row][col] = King(frame: ChessBoard.getFrame(forRow: row, forCol: col), color:#colorLiteral(red: 0, green: 0, blue: 0, alpha: 1), vc: vc)
                    case 5:
                        board[row][col] = Bishop(frame: ChessBoard.getFrame(forRow: row, forCol: col), color:#colorLiteral(red: 0, green: 0, blue: 0, alpha: 1), vc: vc)
                    case 6:
                        board[row][col] = Knight(frame: ChessBoard.getFrame(forRow: row, forCol: col), color:#colorLiteral(red: 0, green: 0, blue: 0, alpha: 1), vc: vc)
                    default:
                        board[row][col] = Rook(frame: ChessBoard.getFrame(forRow: row, forCol: col), color:#colorLiteral(red: 0, green: 0, blue: 0, alpha: 1), vc: vc)
                    }
                case 1:
                    board[row][col] = Pawn(frame: ChessBoard.getFrame(forRow: row, forCol: col), color:#colorLiteral(red: 0, green: 0, blue: 0, alpha: 1), vc: vc)
                case 6:
                    board[row][col] = Pawn(frame: ChessBoard.getFrame(forRow: row, forCol: col), color:#colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 1), vc: vc)
                case 7:
                    switch col {
                    case 0:
                        board[row][col] = Rook(frame: ChessBoard.getFrame(forRow: row, forCol: col), color:#colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 1), vc: vc)
                    case 1:
                        board[row][col] = Knight(frame: ChessBoard.getFrame(forRow: row, forCol: col), color:#colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 1), vc: vc)
                    case 2:
                        board[row][col] = Bishop(frame: ChessBoard.getFrame(forRow: row, forCol: col), color:#colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 1), vc: vc)
                    case 3:
                        board[row][col] = Queen(frame: ChessBoard.getFrame(forRow: row, forCol: col), color:#colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 1), vc: vc)
                    case 4:
                        board[row][col] = King(frame: ChessBoard.getFrame(forRow: row, forCol: col), color:#colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 1), vc: vc)
                    case 5:
                        board[row][col] = Bishop(frame: ChessBoard.getFrame(forRow: row, forCol: col), color:#colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 1), vc: vc)
                    case 6:
                        board[row][col] = Knight(frame: ChessBoard.getFrame(forRow: row, forCol: col), color:#colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 1), vc: vc)
                    default:
                        board[row][col] = Rook(frame: ChessBoard.getFrame(forRow: row, forCol: col), color:#colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 1), vc: vc)
                    }
                default:
                    board[row][col] = Dummy(frame: ChessBoard.getFrame(forRow: row, forCol: col))
                }
            }
        }
    }
}
