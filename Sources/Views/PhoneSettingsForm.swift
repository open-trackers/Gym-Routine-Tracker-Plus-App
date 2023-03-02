//
//  PhoneSettingsForm.swift
//
// Copyright 2023  OpenAlloc LLC
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import os
import SwiftUI

import GroutLib
import GroutUI

struct PhoneSettingsForm: View {
    @EnvironmentObject private var router: GroutRouter

    // MARK: - Views

    var body: some View {
        SettingsForm {
            ColorSettings()

            ExportSettings()

            Button(action: {
                router.path.append(GroutRoute.about)
            }) {
                Text("About \(appName)")
            }
        }
    }

    // MARK: - Properties

    private var appName: String {
        Bundle.main.appName ?? "unknown"
    }
}

struct PhoneSettingsForm_Previews: PreviewProvider {
    static var previews: some View {
        PhoneSettingsForm()
    }
}
