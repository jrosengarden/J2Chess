//
//  StartScreen.swift
//  JeffChess
//
//  Created by Jeff Rosengarden on 11/18/20.
//

import UIKit


class StartScreen: UIViewController {
    
    override func viewDidLoad() {
            
        super.viewDidLoad()
        
        // remove navBar borders (so they are invisible)
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for:.default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.layoutIfNeeded()
        
        // set navBar title
        self.navigationItem.title = "End game"
       
        // hide navbar on initial screen
        self.navigationItem.titleView = UIView()

    }
   
    
    // just before transition to ViewController.swift (main chess game screen)
    // set the isAgainstAI variable
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
                
        let destVC = segue.destination as! ViewController
        
        if segue.identifier == "singleplayer" {
            destVC.isAgainstAI = true
        }
        
        if segue.identifier == "multiplayer" {
            destVC.isAgainstAI = false
        }
        
        // app-wide settings in appSettings
        
        // default setting of UISwitch (AIFeedBack) on NotationViewController
        appSettings.AIFeedBackVisible = false
        
        // default setting for AIScoreLimit (for calculating best move scores)
        appSettings.AIScoreLimit = 3
        
    }
    
    // this seque allows return to start screen by naming it's identified as "backToMainMenu"
    @IBAction func unwind(seque: UIStoryboardSegue) {
        
    }
    
}
