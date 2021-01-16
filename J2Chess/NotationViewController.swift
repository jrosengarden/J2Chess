//
//  NotationViewController.swift
//  J2Chess
//
//  Created by Jeff Rosengarden on 12/29/20.
//

import UIKit

class NotationViewController: UIViewController {

    @IBOutlet weak var txtGameMoves: UITextView!
    
    // handle back to the parent (calling) view controller
    var hndParent:ViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view
        
        // load the textfield (txtGameMoves) with the game moves
        if hndParent!.AIFeedBackVisible.isOn {
            txtGameMoves.text = hndParent?.myChessGame.gameMoves2.joined(separator: "\n")
        } else {
            txtGameMoves.text = hndParent?.myChessGame.gameMoves.joined(separator: "\n")
        }
        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
