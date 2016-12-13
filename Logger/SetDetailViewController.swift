//
//  SetDetailViewController.swift
//  Logger
//
//  Created by James Little on 11/1/16.
//  Copyright © 2016 edu.bowdoin.cs2505.little.ward. All rights reserved.
//

import UIKit

class SetDetailViewController: UITableViewController {
    
    var desc: String?
    var venue: String?
    let dateSlug = { () -> String in // should this be in the Set class?
        let now = Date()
        let calendar = Calendar(identifier: .gregorian)
        let month = calendar.component(.month, from: now)
        let day = calendar.component(.day, from: now)
        return "\(String(format: "%02d", month))_\(String(format: "%02d", day))"
    }()
    
    var set: Set?
    
    @IBAction func descriptionUpdate(_ sender: UITextField) {
        if let newDescription = sender.text {
            if newDescription != "" {
                desc = newDescription.lowercased().replacingOccurrences(of: " ", with: "_")
            } else {
                desc = nil
            }
        } else {
            desc = nil
        }
        updateHint()
    }
    
    @IBAction func venueUpdate(_ sender: UITextField) {
        if let newVenue = sender.text {
            if newVenue != "" {
                venue = newVenue.replacingOccurrences(of: " ", with: "")
            } else {
                venue = nil
            }
        } else {
            venue = nil
        }
        updateHint()
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath {
        case IndexPath(row: 0, section: 1): saveLog()
        case IndexPath(row: 0, section: 2): deleteLog()
        default: break // description and venue cells
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func saveLog() {
        if desc == nil || venue == nil {
            let errorAlert = UIAlertController(title: "Just one second!", message: "Please make sure that you've filled out the description and the venue so we can save your logs in the right place.", preferredStyle: .alert)
            errorAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(errorAlert, animated: true, completion: nil)
            return
        }
        
        let alert = UIAlertController(title: "Dover Credentials", message: "Please enter your Bowdoin username and password", preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.keyboardType = UIKeyboardType.asciiCapable
            textField.autocapitalizationType = UITextAutocapitalizationType.none
            textField.autocorrectionType = UITextAutocorrectionType.no
            textField.placeholder = "Username"
        }
        
        alert.addTextField { (textField) in
            textField.isSecureTextEntry = true
            textField.autocapitalizationType = UITextAutocapitalizationType.none
            textField.autocorrectionType = UITextAutocorrectionType.no
            textField.placeholder = "Password"
        }
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
            let usernameField = alert!.textFields![0]
            let passwordField = alert!.textFields![1]
            print("Text field: \(usernameField.text!); \(passwordField.text!)")
            
            self.uploadSet(username: usernameField.text!, password: passwordField.text!)
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func uploadSet(username: String, password: String) {
        let successfulSave = self.set?.saveToDover(username: username, password: password) ?? false
        
        if successfulSave {
            self.deleteLog()
        } else {
            let errorAlert = UIAlertController(title: "Something went wrong.", message: "Try to save again and double check your Bowdoin username and password. Make sure not to include the \"@bowdoin.edu part. If the problem persists try again later.", preferredStyle: .alert)
            errorAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(errorAlert, animated: true, completion: nil)
        }
    }
    
    func deleteLog() {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let context = delegate.persistentContainer.viewContext
        
        context.delete(set!)

        do {
            try context.save()
            _ = self.navigationController?.popToRootViewController(animated: true)
        } catch {
            print(error)
        }
    }
    
    func updateHint() {
        set?.venue = venue
        set?.scene = desc
        
        tableView.footerView(forSection: 1)?.textLabel?.text = "The set will be uploaded to:\nlogs/\(set!.makeFilePath())\n\nUploading a set to Dover deletes the set from the app."
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateHint()
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    
}
