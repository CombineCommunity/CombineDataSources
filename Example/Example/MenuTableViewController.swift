//
//  MenuTableViewController.swift
//  Example
//
//  Created by Marin Todorov on 8/13/19.
//  Copyright © 2019 Underplot ltd. All rights reserved.
//

import UIKit

class MenuTableViewController: UITableViewController {
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    let rowIndex = (sender as! UITableViewCell).tag
    (segue.destination as! ViewController).demo = Demo(rawValue: rowIndex)!
  }
}
