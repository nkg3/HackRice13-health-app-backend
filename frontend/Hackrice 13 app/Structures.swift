//
//  Item.swift
//  Hackrice 13 app
//
//  Created by Bill Rui on 9/23/23.
//

import Foundation

struct Item: Codable, Hashable, Identifiable{
    var id: String
    var name: String
}

struct Store: Codable, Hashable{
    var id: String
    var name: String
    var long: Double
    var lat: Double
    var vicinity: String
}

extension Store {
    static var emptyStore: Store {
        Store(id: "nullstorid", name: "None", long: 0.0, lat: 0.0, vicinity: "")
        }
}

struct SearchRequest: Codable, Hashable{
    var items: [String]
    var lat: Double
    var long: Double
}

struct StoresRequest: Codable, Hashable{
    var lat: Double
    var long: Double
}

struct StoresListResult: Codable, Hashable {
    var results: [Store]
}

struct ReportData: Codable, Hashable {
    var item: String
    var qty: Int
    var place_id: String
}
let listOfItems: [Item] = [Item(id: "000", name: "Narcan"), Item(id: "001", name: "Masks"), Item(id: "002", name: "Flu vaccine")]
let availableItems: ItemList = ItemList(itemList: listOfItems)
