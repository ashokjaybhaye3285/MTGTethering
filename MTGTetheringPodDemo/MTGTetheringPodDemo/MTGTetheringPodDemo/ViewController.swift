//
//  ViewController.swift
//  MTGTetheringPodDemo
//
//  Created by Sitter Nicholas J on 6/13/16.
//  Copyright © 2016 Sitter Nicholas J. All rights reserved.
//

import UIKit

import JDMTGTethering

class ViewController: UIViewController {

    @IBAction func buttonPressed(sender: AnyObject) {
        JDMTGTethering.launch(self, theme: themeSelector.selectedSegmentIndex == 0 ? .Ag : .CandF)
    }
    
    @IBOutlet weak var themeSelector: UISegmentedControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

