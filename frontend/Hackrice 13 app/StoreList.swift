//
//  LocationList.swift
//  Hackrice 13 app
//
//  Created by Bill Rui on 9/23/23.
//

import Foundation

class StoreList: ObservableObject {
    @Published var stores: [Store]
    
    init() {
        self.stores = []
    }
    
    func postItemList (items itemList: ItemList, url address: String, lat: Double, long: Double) {
        guard let url = URL(string: address)
        else {
            print("[ERROR] URL error")
            return
        }
        
//        let requestBody = SearchRequest(items: itemList.getItemNames(), lat: String(lat), long: String(long))
        let requestBody = SearchRequest(items: itemList.getItemNames(), lat: lat, long: long)
        print(requestBody)
        let body = try? JSONEncoder().encode(requestBody)
        var request = URLRequest(url: url)
        
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        
        print(body)
        
        let task = URLSession.shared.dataTask(with: request) {data, _, error in
            guard let data = data, error == nil else {
                return
            }
            do {
                let stores = try JSONDecoder().decode(StoresListResult.self, from: data)
                DispatchQueue.main.async{
                    self.stores = stores.results
                    self.trimList(keep: 10)
                }
            } catch {
                print("[ERROR] Error decoding JSON: \(error)")
            }
        }
        task.resume()
    }
    
    func isEmpty() -> Bool {
        if self.stores.count == 0 {
            return true
        } else {
            return false
        }
    }
    
    func getNearbyStoreList (url address: String, lat: Double, long: Double) {
        guard let url = URL(string: address)
        else {
            print("[ERROR] URL error")
            return
        }
        
//        let requestBody = SearchRequest(items: itemList.getItemNames(), lat: String(lat), long: String(long))
        let requestBody = StoresRequest(lat: lat, long: long)
        print(requestBody)
        let body = try? JSONEncoder().encode(requestBody)
        var request = URLRequest(url: url)
        
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        
        let task = URLSession.shared.dataTask(with: request) {data, _, error in
            guard let data = data, error == nil else {
                return
            }
            do {
                let stores = try JSONDecoder().decode(StoresListResult.self, from: data)
                DispatchQueue.main.async{ 
                    self.stores = stores.results
                    self.trimList(keep: 10)
                }
            } catch {
                print("[ERROR] Error decoding JSON: \(error)")
            }
        }
        task.resume()
    }
    
    
    func clearList() {
        self.stores = []
    }
    
    func trimList(keep: Int) {
        print(self.stores.count)
        if self.stores.count <= keep {
            return
        } else {
            while self.stores.count > keep {
                _ = self.stores.popLast()
            }
        }
    }
}
