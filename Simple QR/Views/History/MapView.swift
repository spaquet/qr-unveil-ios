//
//  MapView.swift
//  QR Unveil
//
//  Created by Stéphane PAQUET on 4/3/25.
//

import SwiftUI
import MapKit
import SwiftData

struct MapView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \LocationModel.createdAt, order: .reverse) private var locations: [LocationModel]
    
    @State private var position: MapCameraPosition = .automatic
    @State private var selectedItem: String? = nil
    @State private var selectedMarkerLocation: LocationModel?
    @State private var showingQRDetail = false
    @State private var showingQRList = false
    
    // Filter states
    @State private var regionFilter: String = "All"
    @State private var countryFilter: String = "All"
    @State private var stateFilter: String = "All"
    @State private var timeFilter: String = "All Time"
    
    // Available region filters
    private let regions = ["All", "Europe", "North America", "South America", "Asia", "Africa", "Oceania"]
    
    // Available country filters (updated dynamically)
    @State private var countries: [String] = ["All"]
    
    // Available state/province filters (updated dynamically)
    @State private var states: [String] = ["All"]
    
    // Time period filters
    private let timePeriods = ["All Time", "Today", "Past 3 Days", "Past Week", "Past Month", "Past 3 Months"]
    
    // MARK: - Computed Properties
    
    // Filtered locations based on selected filters
    private var filteredLocations: [LocationModel] {
        var result = locations
        
        // Apply time filter
        if timeFilter != "All Time" {
            let calendar = Calendar.current
            let now = Date()
            var filterDate = now
            
            switch timeFilter {
            case "Today":
                filterDate = calendar.startOfDay(for: now)
            case "Past 3 Days":
                filterDate = calendar.date(byAdding: .day, value: -3, to: now) ?? now
            case "Past Week":
                filterDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
            case "Past Month":
                filterDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
            case "Past 3 Months":
                filterDate = calendar.date(byAdding: .month, value: -3, to: now) ?? now
            default:
                break
            }
            
            result = result.filter { $0.createdAt >= filterDate }
        }
        
        // Apply geographic filters
        // In a real implementation, you would need to use the address property
        // and parse it to extract country/region/state information
        if regionFilter != "All" || countryFilter != "All" || stateFilter != "All" {
            result = result.filter { location in
                guard let address = location.address else { return false }
                
                let matchesRegion = regionFilter == "All" ||
                    matchesRegionFilter(address: address, region: regionFilter)
                    
                let matchesCountry = countryFilter == "All" ||
                    matchesCountryFilter(address: address, country: countryFilter)
                    
                let matchesState = stateFilter == "All" ||
                    matchesStateFilter(address: address, state: stateFilter)
                
                return matchesRegion && matchesCountry && matchesState
            }
        }
        
        return result
    }
    
    // Groups locations by coordinates to handle multiple QR codes in one location
    private var groupedLocations: [LocationGroup] {
        var groups: [String: LocationGroup] = [:]
        
        for location in filteredLocations {
            // Create a key based on rounded coordinates to group nearby pins
            // The precision can be adjusted based on how close pins should be to be considered the same location
            let key = "\(round(location.latitude * 1000) / 1000),\(round(location.longitude * 1000) / 1000)"
            
            if var group = groups[key] {
                group.locations.append(location)
                groups[key] = group
            } else {
                groups[key] = LocationGroup(
                    id: key,
                    latitude: location.latitude,
                    longitude: location.longitude,
                    locations: [location]
                )
            }
        }
        
        return Array(groups.values)
    }
    
    // MARK: - View Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Filters View
            filtersView
                .padding(.top, 8)
            
            // Map View
            mapView
        }
        .navigationTitle("QR Map")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingQRDetail) {
            if let location = selectedMarkerLocation, let qrCode = location.qrCode {
                QRDetailView(qrCode: qrCode)
            }
        }
        .sheet(isPresented: $showingQRList) {
            let selectedGroup = groupedLocations.first(where: { $0.id == selectedItem })
            if let group = selectedGroup {
                QRCodeListView(locations: group.locations)
            }
        }
    }
    
    // MARK: - Subviews
    
    // Filters view component
    private var filtersView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                // Region Filter
                Menu {
                    Picker("Region", selection: $regionFilter) {
                        ForEach(regions, id: \.self) { region in
                            Text(region).tag(region)
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "globe")
                        Text(regionFilter == "All" ? "Region" : regionFilter)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
                .onChange(of: regionFilter) {
                    updateCountriesForRegion()
                    countryFilter = "All"
                    stateFilter = "All"
                }
                
                // Country Filter (shown only when region is selected)
                if regionFilter != "All" {
                    Menu {
                        Picker("Country", selection: $countryFilter) {
                            ForEach(countries, id: \.self) { country in
                                Text(country).tag(country)
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "flag")
                            Text(countryFilter == "All" ? "Country" : countryFilter)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .onChange(of: countryFilter) {
                        updateStatesForCountry()
                        stateFilter = "All"
                    }
                }
                
                // State/Province Filter (shown for large countries)
                if ["United States", "China", "Russia", "Australia", "Canada", "Brazil", "India"].contains(countryFilter) {
                    Menu {
                        Picker("State", selection: $stateFilter) {
                            ForEach(states, id: \.self) { state in
                                Text(state).tag(state)
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "mappin.and.ellipse")
                            Text(stateFilter == "All" ? "State" : stateFilter)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                
                Divider()
                    .frame(height: 24)
                    .padding(.horizontal, 4)
                
                // Time Filter
                Menu {
                    Picker("Time", selection: $timeFilter) {
                        ForEach(timePeriods, id: \.self) { period in
                            Text(period).tag(period)
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "calendar")
                        Text(timeFilter == "All Time" ? "Time" : timeFilter)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(UIColor.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.gray.opacity(0.2)),
            alignment: .bottom
        )
    }
    
    // Map view component
    private var mapView: some View {
        Map(position: $position, selection: $selectedItem) {
            ForEach(groupedLocations) { group in
                Marker(group.count > 1 ? "\(group.count)" : "", coordinate: group.coordinate)
                    .tint(markerColor(for: group))
                    .tag(group.id)
            }
        }
        .mapControls {
            MapCompass()
            MapScaleView()
            MapUserLocationButton()
        }
        .onChange(of: selectedItem) { oldValue, newValue in
            guard let selectedId = newValue else { return }
            if let selectedGroup = groupedLocations.first(where: { $0.id == selectedId }) {
                if selectedGroup.locations.count == 1 {
                    // Single QR code at this location
                    if let location = selectedGroup.locations.first {
                        selectedMarkerLocation = location
                        showingQRDetail = true
                    }
                } else {
                    // Multiple QR codes - show list
                    showingQRList = true
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    // Returns a color for a marker based on the number of locations and their types
    private func markerColor(for group: LocationGroup) -> Color {
        if group.count > 1 {
            return .red // Multiple QR codes
        } else if let qrCode = group.locations.first?.qrCode {
            // Color based on QR code type
            switch qrCode.qrType {
            case "url": return .blue
            case "wifi": return .orange
            case "vcard": return .green
            case "email": return .purple
            case "phone": return .indigo
            default: return .blue
            }
        } else {
            return .blue // Default
        }
    }
    
    // Updates available countries based on selected region
    private func updateCountriesForRegion() {
        switch regionFilter {
        case "Europe":
            countries = ["All", "France", "Germany", "United Kingdom", "Spain", "Italy",
                        "Netherlands", "Belgium", "Switzerland", "Austria", "Sweden",
                        "Norway", "Denmark", "Finland", "Ireland", "Portugal", "Greece"]
        case "North America":
            countries = ["All", "United States", "Canada", "Mexico"]
        case "South America":
            countries = ["All", "Brazil", "Argentina", "Colombia", "Chile", "Peru", "Venezuela"]
        case "Asia":
            countries = ["All", "China", "Japan", "South Korea", "India", "Thailand",
                        "Vietnam", "Indonesia", "Malaysia", "Singapore", "Philippines"]
        case "Africa":
            countries = ["All", "South Africa", "Egypt", "Morocco", "Kenya", "Nigeria",
                        "Ghana", "Ethiopia", "Tanzania", "Algeria", "Tunisia"]
        case "Oceania":
            countries = ["All", "Australia", "New Zealand", "Fiji", "Papua New Guinea"]
        default:
            countries = ["All"]
        }
    }
    
    // Updates available states based on selected country
    private func updateStatesForCountry() {
        switch countryFilter {
        case "United States":
            states = ["All", "Alabama", "Alaska", "Arizona", "Arkansas", "California",
                     "Colorado", "Connecticut", "Delaware", "Florida", "Georgia", "Hawaii",
                     "Idaho", "Illinois", "Indiana", "Iowa", "Kansas", "Kentucky", "Louisiana",
                     "Maine", "Maryland", "Massachusetts", "Michigan", "Minnesota", "Mississippi",
                     "Missouri", "Montana", "Nebraska", "Nevada", "New Hampshire", "New Jersey",
                     "New Mexico", "New York", "North Carolina", "North Dakota", "Ohio", "Oklahoma",
                     "Oregon", "Pennsylvania", "Rhode Island", "South Carolina", "South Dakota",
                     "Tennessee", "Texas", "Utah", "Vermont", "Virginia", "Washington",
                     "West Virginia", "Wisconsin", "Wyoming"]
        case "Australia":
            states = ["All", "New South Wales", "Victoria", "Queensland", "Western Australia",
                     "South Australia", "Tasmania", "Australian Capital Territory", "Northern Territory"]
        case "Canada":
            states = ["All", "Ontario", "Quebec", "British Columbia", "Alberta", "Manitoba",
                     "Saskatchewan", "Nova Scotia", "New Brunswick", "Newfoundland and Labrador",
                     "Prince Edward Island", "Northwest Territories", "Yukon", "Nunavut"]
        case "China":
            states = ["All", "Beijing", "Shanghai", "Guangdong", "Shenzhen", "Tianjin",
                     "Hong Kong", "Macau", "Sichuan", "Yunnan", "Fujian", "Zhejiang", "Jiangsu"]
        case "Brazil":
            states = ["All", "São Paulo", "Rio de Janeiro", "Minas Gerais", "Bahia",
                     "Rio Grande do Sul", "Paraná", "Pernambuco", "Ceará", "Pará"]
        case "India":
            states = ["All", "Maharashtra", "Tamil Nadu", "Karnataka", "Delhi", "Telangana",
                     "Uttar Pradesh", "West Bengal", "Gujarat", "Rajasthan", "Kerala"]
        default:
            states = ["All"]
        }
    }
    
    // Checks if the address contains the specified region
    private func matchesRegionFilter(address: String, region: String) -> Bool {
        // This is a simplified implementation
        // In a real app, you'd want more sophisticated region matching
        
        // Map regions to common terms that might appear in addresses
        let regionTerms: [String: [String]] = [
            "Europe": ["Europe", "EU", "European"],
            "North America": ["North America", "USA", "Canada", "Mexico", "United States"],
            "South America": ["South America", "Brazil", "Argentina", "Colombia", "Chile"],
            "Asia": ["Asia", "China", "Japan", "Korea", "India", "Thailand", "Indonesia"],
            "Africa": ["Africa", "South Africa", "Egypt", "Morocco", "Kenya", "Nigeria"],
            "Oceania": ["Oceania", "Australia", "New Zealand", "Pacific"]
        ]
        
        // Check if any terms for this region appear in the address
        if let terms = regionTerms[region] {
            for term in terms {
                if address.contains(term) {
                    return true
                }
            }
        }
        
        return false
    }
    
    // Checks if the address contains the specified country
    private func matchesCountryFilter(address: String, country: String) -> Bool {
        // Simple implementation - check if the country name appears in the address
        return address.contains(country)
    }
    
    // Checks if the address contains the specified state
    private func matchesStateFilter(address: String, state: String) -> Bool {
        // Simple implementation - check if the state name appears in the address
        return address.contains(state)
    }
}

// MARK: - Supporting Types

// Helper struct to group QR code locations
struct LocationGroup: Identifiable {
    var id: String
    var latitude: Double
    var longitude: Double
    var locations: [LocationModel]
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var count: Int {
        locations.count
    }
}

// View to display a list of QR codes at a single location
struct QRCodeListView: View {
    let locations: [LocationModel]
    
    var body: some View {
        List {
            ForEach(locations) { location in
                if let qrCode = location.qrCode {
                    NavigationLink(destination: QRDetailView(qrCode: qrCode)) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                // QR code type icon
                                Image(systemName: qrTypeIcon(qrCode.qrType))
                                    .foregroundColor(qrTypeColor(qrCode.qrType))
                                    .frame(width: 24, height: 24)
                                
                                // QR code content
                                Text(qrCode.label ?? qrCode.formattedContent())
                                    .fontWeight(.medium)
                            }
                            
                            // Address
                            HStack {
                                Image(systemName: "location.circle")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(location.formattedAddress())
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            // Date
                            HStack {
                                Image(systemName: "calendar")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text("Scanned on \(formatDate(location.createdAt))")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("QR Codes at Location")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // Format date for display
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // Get icon for QR code type
    private func qrTypeIcon(_ type: String) -> String {
        switch type {
        case "url": return "link"
        case "phone": return "phone.fill"
        case "email": return "envelope.fill"
        case "wifi": return "wifi"
        case "vcard": return "person.crop.square.fill"
        case "location": return "mappin.and.ellipse"
        case "sms": return "message.fill"
        default: return "doc.text.fill"
        }
    }
    
    // Get color for QR code type
    private func qrTypeColor(_ type: String) -> Color {
        switch type {
        case "url": return .blue
        case "phone": return .green
        case "email": return .purple
        case "wifi": return .orange
        case "vcard": return .indigo
        case "location": return .red
        case "sms": return .pink
        default: return .gray
        }
    }
}

#Preview {
    MapView()
}
