//
//  StartScreen.swift
//  JeffChess
//
//  Created by Jeff Rosengarden on 11/18/20.
//

import UIKit


class StartScreen: UIViewController {
    
    override func viewDidLoad() {
    
        // navbar configuration
        self.navigationController!.navigationBar.barStyle = .black
        self.navigationController?.navigationBar.barTintColor = UIColor.systemGray4

        
        self.navigationController!.navigationBar.isTranslucent = false
        self.navigationController!.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        self.navigationController!.navigationBar.tintColor = #colorLiteral(red: 0.2934360504, green: 0.6425268054, blue: 0.7267915606, alpha: 1)

        self.navigationItem.title = "End game and return to main menu"
       
        // hide navbar on initial screen
        self.navigationItem.titleView = UIView()

    }
    
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
                
        let destVC = segue.destination as! ViewController
        
        if segue.identifier == "singleplayer" {
            destVC.isAgainstAI = true
        }
        
        if segue.identifier == "multiplayer" {
            destVC.isAgainstAI = false
        }
        
    }
    
    @IBAction func unwind(seque: UIStoryboardSegue) {
        
    }
    
}
