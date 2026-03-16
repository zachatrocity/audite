import SwiftUI

struct SettingsView: View {
    @AppStorage("outputFolder") private var outputFolder: String = ""
    @AppStorage("filenameTemplate") private var filenameTemplate: String = "{{date}} {{title}}"
    @AppStorage("calendarEnabled") private var calendarEnabled: Bool = true

    var body: some View {
        Form {
            TextField("Output Folder", text: $outputFolder)
            TextField("Filename Template", text: $filenameTemplate)
            Toggle("Apple Calendar Integration", isOn: $calendarEnabled)
        }
        .padding()
        .frame(width: 420)
    }
}
