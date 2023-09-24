//
//  ReportView.swift
//  Hackrice 13 app
//
//  Created by Nik Gautam on 9/23/23.
//

import SwiftUI

struct ReportView: View {
    @ObservedObject var storeList: StoreList
    @ObservedObject var locationManager: LocationManager
    @Binding var lat: Double
    @Binding var long: Double
    @Binding var reportItem: ReportData
    
    @State private var selectedStore: Store = Store.emptyStore
    @State var isEditMode: EditMode = .inactive
    
    
    
    var body: some View {
        Form {
            Section(header: Text("Item Details")) {
                Picker(selection: $reportItem.item, label: Text("Item")) {
                    ForEach(listOfItems, id: \.id){item in
                        Text(item.name).tag(item.name)
                    }
                }
            }
            Section(header: Text("Quantity")) {
                TextField("Quantity", value: $reportItem.qty, format: .number)
                    .keyboardType(.numberPad)
            }
            Section(header: Text("Store")) {
                Picker("Stores", selection: $reportItem.place_id) {
                    ForEach(storeList.stores, id: \.self) { store in
                        let distance: Double = calculateDistance(from: Location(latitude: lat, longitude: long),
                                                                 to: Location(latitude: store.lat, longitude: store.long))
                        
                        var displayText = store.name + "\n" + store.vicinity + "     " + String(format:"%.2f", distance) + "miles"
                        Text(displayText).tag(store.id)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            }
        }
        .onAppear() {
            if let location = locationManager.location {
                lat = location.coordinate.latitude
                long = location.coordinate.longitude
                } else {
                }
            storeList.getNearbyStoreList(url: gmap_url, lat: lat, long: long)
        }
    }
}

//#Preview {
//    ReportView()
//}
