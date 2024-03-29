//
//  WidgetGRTP.swift
//
// Copyright 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import SwiftUI
import WidgetKit

import GroutLib
import GroutUI

struct WidgetGRTP: Widget {
    let kind: String = "WidgetGRTP"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            WidgetView(entry: entry)
        }
        .configurationDisplayName("Gym Routines")
        .description("Time since last gym routine.")
        .supportedFamilies([.systemSmall])
    }
}

struct WidgetGRTP_Previews: PreviewProvider {
    static var previews: some View {
        let entry = WidgetEntry(name: "Back & Bicep", imageName: nil, timeInterval: 1000, color: nil)
        return WidgetView(entry: entry)
            .accentColor(.blue)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
