//
//  SearchView.swift
//  Hackrice 13 app
//
//  Created by Bill Rui on 9/22/23.
//

import SwiftUI

//let get_list_url: String = "http://localhost:3000/api/data"
let post_list_url: String = "https://hackrice14.azurewebsites.net/api/GetRoute"
let gmap_url: String = "https://hackrice14.azurewebsites.net/api/gmap"
let report_url: String = "https://hackrice14.azurewebsites.net/api/submitItem"

struct SearchView: View {
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var itemNotFound = false
    @State var displayingLocView = false
    @State private var filteredList: [String] = []
    @State private var isPresentingReportView = false
    @State var lat: Double = 0
    @State var long: Double = 0
    @State var reportItem: ReportData = ReportData(item: listOfItems[0].name, qty: 0, place_id: "")
    @State var selectedLatLoc: Double = 0
    @State var selectedLongLoc: Double = 0
    @StateObject var selectedItems: ItemList = ItemList()
    @StateObject var itemList = availableItems
    @StateObject var storeList = StoreList()
    @StateObject var locationManager = LocationManager()
    @StateObject var nearbyStoresList = StoreList()
    @StateObject var reporter = Reporter()
    
    var body: some View {
        VStack{
            NavigationView {
                VStack {
                    SearchBar(searchText: $searchText,
                              isSearching: $isSearching,
                              selectedItems: selectedItems,
                              itemList: itemList,
                              itemNotFound: $itemNotFound)
                    
                    if isSearching {
                        Form {
                            ForEach(filteredList, id: \.self) { item in
                                Button(action: {
                                    searchText = ""
                                    isSearching = false
                                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                    var found: Bool = false
                                    for itemx in itemList.items {
                                        if itemx.name == item {
                                            selectedItems.addItem(item: itemx)
                                            found = true
                                        }
                                    }
                                    
                                    if !found {
                                        itemNotFound = true
                                    }
                                }) { Text(item) }
                            }
                        }
                        .padding(.bottom, 14.0)
                    }
                    
                    
                    Text("Selected items")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .padding(.top, 30.0)
                    
                    List {
                        ForEach(selectedItems.getItemNames(), id: \.self) { item in
                            Text(item)
                        }
                    }

                        
                    HStack{
                        NavigationLink(destination: LocationView(
                            storeList: storeList,
                            selectedItems: selectedItems,
                            locationManager: locationManager,
                            lat:$lat,
                            long:$long,
                            selectedLat: $selectedLatLoc,
                            selectedLong: $selectedLongLoc,
                            displayingLocView: $displayingLocView
                            )) {
                            Text("Look for my items")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(10)
                        }
                        .padding()
                        
//                        NavigationLink(destination: {}) {
//                            Text("Report stock")
//                                .foregroundColor(.white)
//                                .padding()
//                                .background(Color.blue)
//                                .cornerRadius(10)
//                        }
                        Button("Report stock") {
                            isPresentingReportView = true
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(10)
                    }
                }
                .ignoresSafeArea(.keyboard)
                .navigationTitle("Search for items")
//                .onAppear{ itemList.getList(address: get_list_url) }  // query for list
                .onAppear{ storeList.clearList() }
            }
            .sheet(isPresented: $isPresentingReportView) {
                NavigationStack {
                    ReportView(
                        storeList: nearbyStoresList,
                        locationManager: locationManager,
                        lat:$lat,
                        long:$long,
                        reportItem: $reportItem
                    )
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Cancel") {
                                    isPresentingReportView = false
                                    reportItem.item=listOfItems[0].name
                                    reportItem.place_id=""
                                    reportItem.qty=0
                                }
                            }
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") {
                                    isPresentingReportView = false
                                    reporter.reportItem(report: reportItem, url: report_url)
                                    reportItem.item=listOfItems[0].name
                                    reportItem.place_id=""
                                    reportItem.qty=0
                                    
                                }
                            }
                        }
                }
            }
            .onChange(of: searchText) { newVal in
                filteredList = itemList.getItemNames().filter{ name in
                    return name.contains(try! Regex(newVal).ignoresCase())
                }
            }
            .onAppear {
                filteredList = itemList.getItemNames()
            }
            
            Spacer()
            
            
        }
        .ignoresSafeArea(.keyboard)
    }
}

struct SearchBar: View {
    @Binding var searchText: String
    @Binding var isSearching: Bool
    @ObservedObject var selectedItems: ItemList
    @ObservedObject var itemList: ItemList
    @Binding var itemNotFound: Bool
    
    var body: some View {
        HStack {
            TextField("Start typing to search", text: $searchText)
                .padding(8)
                .background(Color(.systemGray5))
                .cornerRadius(10)
                .padding(.horizontal, 10)
                .onTapGesture {
                    isSearching = true
                }
                .onSubmit {
                    var found: Bool = false
                    for item in itemList.items {
                        if item.name == searchText {
                            selectedItems.addItem(item: item)
                            found = true
                            isSearching = false
                            searchText = ""
                        }
                    }
                    
                    if !found {
                        itemNotFound = true
                    }
                }
                .alert("Item not found", isPresented: $itemNotFound) {
                    Button("Dismiss", role: .cancel) { }
                }
            
            if isSearching {
                Button(action: {
                    searchText = ""
                    isSearching = false
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }) {
                    Text("Cancel")
                }
                .padding(.trailing, 10)
                .transition(.move(edge: .trailing))
                .animation(.default)
            }
        }
    }
}

#Preview {
    SearchView()
}
