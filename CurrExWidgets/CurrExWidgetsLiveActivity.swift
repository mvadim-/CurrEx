//
//  CurrExWidgetsLiveActivity.swift
//  CurrExWidgets
//
//  Created by Vadym Maslov on 06.03.2025.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct CurrExWidgetsAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct CurrExWidgetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CurrExWidgetsAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension CurrExWidgetsAttributes {
    fileprivate static var preview: CurrExWidgetsAttributes {
        CurrExWidgetsAttributes(name: "World")
    }
}

extension CurrExWidgetsAttributes.ContentState {
    fileprivate static var smiley: CurrExWidgetsAttributes.ContentState {
        CurrExWidgetsAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: CurrExWidgetsAttributes.ContentState {
         CurrExWidgetsAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: CurrExWidgetsAttributes.preview) {
   CurrExWidgetsLiveActivity()
} contentStates: {
    CurrExWidgetsAttributes.ContentState.smiley
    CurrExWidgetsAttributes.ContentState.starEyes
}
