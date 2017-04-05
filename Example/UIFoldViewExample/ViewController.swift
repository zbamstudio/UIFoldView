//
//  ViewController.swift
//  UIFoldViewExample
//
//  Created by Emrah Ozer on 05/04/2017.
//  Copyright © 2017 Emrah Ozer. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 500))
        let gradient = CAGradientLayer()
        gradient.frame = view.bounds
        gradient.colors = [UIColor.red.cgColor, UIColor.black.cgColor]
        view.layer.insertSublayer(gradient, at: 0)
        
        let foldView = FoldView(fromView: view, jointCount: 4, foldDirection: FoldDirection.topToBottom)
        foldView.angle             = 0
        foldView.unfoldLength      = 400
        
        self.view.addSubview(foldView)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

