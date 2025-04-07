//
//  QRScannerWidgetConfiguration.swift
//  Simple QR
//
//  Created by Stéphane PAQUET on 4/7/25.
//

import WidgetKit
import SwiftUI
import Intents

// Define the entry type
struct SimpleEntry: TimelineEntry {
    let date: Date
}

// Provider to supply timeline entries
struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }
    
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        let entry = SimpleEntry(date: Date())
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let entries = [SimpleEntry(date: Date())]
        let timeline = Timeline(entries: entries, policy: .never)
        completion(timeline)
    }
}

// Widget entry view
struct QRScannerWidgetEntryView: View {
    var entry: SimpleEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "qrcode.viewfinder")
                    .font(.system(size: 20))
                    .widgetAccentable()
            }
            .widgetURL(URL(string: "qrunveil://scan"))
        default:
            Text("Unsupported")
        }
    }
}

// Main widget struct
struct QRScannerWidget: Widget {
    let kind: String = "com.qrunveil.qrscanner.widget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            QRScannerWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("QR Scanner")
        .description("Quick access to QR code scanning.")
        .supportedFamilies([.accessoryCircular])
    }
}
