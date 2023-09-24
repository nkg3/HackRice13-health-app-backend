//
//  Reporter.swift
//  Hackrice 13 app
//
//  Created by Nik Gautam on 9/23/23.
//

import Foundation

class Reporter: ObservableObject {
    
    
    func reportItem(report reportData: ReportData, url address: String) {
        guard let url = URL(string: address)
        else {
            print("[ERROR] URL error")
            return
        }

        if let body = try? JSONEncoder().encode(reportData) {
            print(String(data: body, encoding: .utf8)!)
            
            var request = URLRequest(url: url)
            
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = body
            
            
            
            let task = URLSession.shared.dataTask(with: request) {data, _, error in
                guard let data = data, error == nil else {
                    return
                }
            }
            task.resume()
        }
        
    }
}
