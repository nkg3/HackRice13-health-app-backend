import UIKit

var greeting = "Hello, playground"

var item: Item = Item(
    id : "000",
    name : "drug1"
)

let instance = ItemList()


Task{
    instance.postList(address: "http://localhost:3000/api/postdata")
}


