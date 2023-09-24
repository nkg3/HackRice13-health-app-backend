//
//  LocationView.swift
//  Hackrice 13 app
//
//  Created by Bill Rui on 9/23/23.
//

import SwiftUI
import MapKit

struct LocationView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var storeList: StoreList
    @ObservedObject var selectedItems: ItemList
    @ObservedObject var locationManager: LocationManager
    @Binding var lat: Double
    @Binding var long: Double
    @Binding var selectedLat: Double
    @Binding var selectedLong: Double
    @Binding var displayingLocView: Bool
    @State private var region: MKCoordinateRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 0, longitude: 0), span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1))
    @State private var buttonPress: Bool = false
    @State private var annotations: [InterestPoint] = [InterestPoint(name: "", coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0))]
    @State private var scale = 1.0

    var body: some View {
        VStack{
            NavigationView{
                if storeList.isEmpty(){
                    Text("Loading your best possible route...")
                } else {
                    Form {
                        ForEach(storeList.stores, id: \.self) { store in
                            let distance: Double = calculateDistance(from: Location(latitude: lat, longitude: long),
                                                                     to: Location(latitude: store.lat, longitude: store.long))
                            
                            let displayText = store.name + "\n" + store.vicinity + "     " + String(format:"%.2f", distance) + "miles"
                            Button (action: {
                                selectedLat = store.lat
                                selectedLong = store.long
                                buttonPress = true
                            }) {
                                Text(displayText)
                                    .foregroundColor(colorScheme == .dark ? .white : .black)
                            }
                            .scaleEffect(scale)
                            .animation(.bouncy, value: scale)
                        }
                    }
                }
                
            }
            .padding(.top, 1)
            .onAppear {
                displayingLocView = true
                if let location = locationManager.location {
                    lat = location.coordinate.latitude
                    long = location.coordinate.longitude
                }
                storeList.postItemList(items: selectedItems, url: post_list_url, lat: lat, long: long)
                region.center = CLLocationCoordinate2D(latitude: lat, longitude: long)
                selectedItems.clearList()
            }
            
            Spacer()
            
            NavigationView {
                MapView(
                    user_lat: $lat,
                    user_long: $long,
                    selectedLat: $selectedLat,
                    selectedLong: $selectedLong,
                    region: $region,
                    buttonPress: $buttonPress,
                    storeList: storeList
                )
            }
            .padding(.horizontal)
            .cornerRadius(10)
        }
        
    }
}

struct MapView: View {
    @Binding var user_lat: Double
    @Binding var user_long: Double
    @Binding var selectedLat: Double
    @Binding var selectedLong: Double
    @Binding var region: MKCoordinateRegion
    @Binding var buttonPress: Bool
    @ObservedObject var storeList: StoreList
    @State private var showAll = false
    
    private var annotationItems: [InterestPoint] {
        if showAll {
            var ret:[InterestPoint] = []
            for store in storeList.stores {
                ret.append(InterestPoint(name: "location", coordinate: CLLocationCoordinate2D(latitude: store.lat, longitude: store.long)))
            }
            return ret
        }
        else if buttonPress {
            buttonPress = false
            return [InterestPoint(name: "selected store", coordinate: CLLocationCoordinate2D(latitude: selectedLat, longitude: selectedLong))]
        } else {
            return []
        }
    }
    
    var body: some View {
        VStack{
            var buttonText = showAll ? "Show selected" : "Show all"
            Button(buttonText) {
                showAll = showAll ? false : true
            }
            .foregroundColor(.blue)
            .padding(.vertical, 10.0)
            .cornerRadius(0)
            .frame(width: 400, height: 20)
            
            Map(coordinateRegion: $region, annotationItems: annotationItems) {
                MapPin(coordinate: $0.coordinate)
            }
            .frame(width: 400, height: 250)
            .cornerRadius(10)
            //        .onChange(of: buttonPress) { newVal in
            //            annotations = [InterestPoint(name: "selected store", coordinate: CLLocationCoordinate2D(latitude: selectedLat, longitude: selectedLong))]
            //        }
        }
    }
        
}


struct Location {
    var latitude: Double
    var longitude: Double
}

struct InterestPoint: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
}

func calculateDistance(from source: Location, to destination: Location) -> Double {
    let earthRadius: Double = 6371 // Earth's radius in kilometers
    
    // Convert latitude and longitude from degrees to radians
    let sourceLatRad = source.latitude * .pi / 180.0
    let sourceLonRad = source.longitude * .pi / 180.0
    let destLatRad = destination.latitude * .pi / 180.0
    let destLonRad = destination.longitude * .pi / 180.0
    
    // Haversine formula
    let dLat = destLatRad - sourceLatRad
    let dLon = destLonRad - sourceLonRad
    let a = sin(dLat/2) * sin(dLat/2) + cos(sourceLatRad) * cos(destLatRad) * sin(dLon/2) * sin(dLon/2)
    let c = 2 * atan2(sqrt(a), sqrt(1-a))
    
    // Calculate the distance
    let distance = earthRadius * c
    return distance / 1.6
}

//#Preview {
//    LocationView(storeList: StoreList(), selectedItems: ItemList(), locationManager: LocationManager())
//}
