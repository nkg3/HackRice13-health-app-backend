//
//  ItemList.swift
//  Hackrice 13 app
//
//  Created by Bill Rui on 9/23/23.
//

import Foundation

class ItemList: ObservableObject {
    @Published var items: [Item]
    
    init() {
        self.items = []
    }
    
    convenience init(itemList: [Item]) {
        self.init()
        self.items = itemList
    }

    
    func getList (address: String) {
        guard let url = URL(string: address)
        else {
            print ("[ERROR] URL error")
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil
            else {
                print ("[ERROR] http request error \(error?.localizedDescription)")
                return
            }
            
            do {
                let item = try JSONDecoder().decode([Item].self, from: data)
                DispatchQueue.main.async{ self.items = item }
            } catch {
                print("[ERROR] Error decoding JSON: \(error)")
            }
        }
        
        task.resume()
    }

    
    func getItemNames () -> [String] {
        var ret_val: [String] = []
        for cur_item in items {
            ret_val.append(cur_item.name)
        }
        
        return ret_val
    }
    
    func addItem (item: Item) {
        self.items.append(item)
    }
    
    func clearList () {
        self.items = []
    }
    
}
