//
//  ViewController.swift
//  Sample-iOS
//
//  Created by Abdullah Selek on 21.03.18.
//  Copyright © 2018 Abdullah Selek. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    let session = URLSession.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        var request = URLRequest(url: URL(string: "http://127.0.0.1:8080/")!)
        request.httpMethod = "POST"
        request.httpBody = "Request Body".data(using: String.Encoding.utf8)!

        let task = session.dataTask(with: request, completionHandler: {(data, response, error) in
            if let error = error {
                print("Error: \(error.localizedDescription)")
            } else if let response = response {
                print("Response: \(response)")
            }
        })
        task.resume()
    }

}
