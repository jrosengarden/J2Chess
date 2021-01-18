//
//  NotationViewController.swift
//  J2Chess
//
//  Created by Jeff Rosengarden on 12/29/20.
//

import UIKit

class NotationViewController: UIViewController {

    @IBOutlet weak var txtGameMoves: UITextView!
    @IBOutlet weak var AIFeedBack: UISwitch!
    @IBOutlet weak var AIFeedBackLabel: UILabel!
    
    // handle back to the parent (calling) view controller
    var hndParent:ViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view
        
        // make AIFeedBackVisible UISwitch smaller
        AIFeedBack.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        
        if hndParent?.isAgainstAI == true {
            AIFeedBack.isHidden = false
            AIFeedBackLabel.isHidden = false
        } else {
            AIFeedBack.isHidden = true
            AIFeedBackLabel.isHidden = true
        }
        
        // set UISwitch position
        if appSettings.AIFeedBackVisible == true{
            AIFeedBack.isOn = true
        } else {
            AIFeedBack.isOn = false
        }
        
        // load the textfield (txtGameMoves) with the game moves
        AIFeedBackChanged(self)
        
    }
    
    @IBAction func AIFeedBackChanged(_ sender: Any) {
        
        if AIFeedBack.isOn {
            AIFeedBackLabel.text = "AI FeedBack is On"
            txtGameMoves.text = hndParent?.myChessGame.gameMoves2.joined(separator: "\n")
            appSettings.AIFeedBackVisible = true
        } else {
            AIFeedBackLabel.text = "AI FeedBack is Off"
            txtGameMoves.text = hndParent?.myChessGame.gameMoves.joined(separator: "\n")
            appSettings.AIFeedBackVisible = false
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
