//
//  ContentView.swift
//  RunPython
//
//  Created by PureLogics-2259 on 17/06/2025.
//

import SwiftUI
import UniformTypeIdentifiers
import Darwin

class ViewModel: ObservableObject {
    @Published var inputPath: String = ""
    @Published var outputPath: String = ""
    @Published var isRunning: Bool = false
    @Published var logText: String = ""
    
    @Published var progress = 0.0
    @Published var progressText: String = ""
    
    var process = Process()
    
    func runIleappInBackground() {
        DispatchQueue.main.async {
            self.isRunning = true
            self.logText = "▶️ iLEAPP started..."
        }
        
        process.executableURL = Bundle.main.url(forResource: "iLEAPP/dist/ileapp", withExtension: nil)
        process.arguments = ["-t", "itunes", "-i", inputPath, "-o", outputPath]
        
        // Optional: capture logs
        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = outputPipe
        // Observe logs
        let outputHandler = outputPipe.fileHandleForReading
        outputHandler.waitForDataInBackgroundAndNotify()
        
        var dataObserver: NSObjectProtocol!
        let notificationCenter = NotificationCenter.default
        let dataNotificationName = NSNotification.Name.NSFileHandleDataAvailable
        dataObserver = notificationCenter.addObserver(forName: dataNotificationName, object: outputHandler, queue: nil) {  notification in
            let data = outputHandler.availableData
            guard data.count > 0 else {
                notificationCenter.removeObserver(dataObserver!)
                return
            }
            if let line = String(data: data, encoding: .utf8) {
                self.updateProgress(from: line)
                
                print("Output -> \(line)")
                DispatchQueue.main.async {
                    self.logText = self.logText + line
                }
            }
            outputHandler.waitForDataInBackgroundAndNotify()
        }
        // Process termination callback
        process.terminationHandler = { proc in
            let output = String(data: outputPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            
            DispatchQueue.main.async {
                self.isRunning = false
                self.logText += "\n✅ iLEAPP finished (exit code: \(proc.terminationStatus))\n\(output)"
            }
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try self.process.run()
            } catch {
                DispatchQueue.main.async {
                    self.isRunning = false
                    self.logText += "\n❌ Error: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func updateProgress(from line: String) {
        // Use regex to match all patterns like: [123/427]
        let pattern = #"\[(\d+)/(\d+)\]"#
        let regex = try? NSRegularExpression(pattern: pattern)

        let matches = regex?.matches(in: line, range: NSRange(line.startIndex..., in: line)) ?? []

        guard let lastMatch = matches.last else { return }

        // Extract numbers from the last match
        if let currentRange = Range(lastMatch.range(at: 1), in: line),
           let totalRange = Range(lastMatch.range(at: 2), in: line),
           let current = Int(line[currentRange]),
           let total = Int(line[totalRange]),
           total > 0
        {
            DispatchQueue.main.async {
                self.progress = Double(current) / Double(total)
                self.progressText = "\(current)/\(total)"
            }
        }
    }


}

struct ContentView: View {
    
    @StateObject var vm = ViewModel()
    
    init() {}

    
    var body: some View {
        VStack(spacing: 20) {
            GroupBox(label: Text("Input Directory")) {
                HStack {
                    Text(vm.inputPath.isEmpty ? "No folder selected" : vm.inputPath)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                    Button("Select") {
                        selectDirectory { path in
                            if let path = path {
                                vm.inputPath = path
                            }
                        }
                    }
                }
            }
            
            GroupBox(label: Text("Output Directory")) {
                HStack {
                    Text(vm.outputPath.isEmpty ? "No folder selected" : vm.outputPath)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                    Button("Select") {
                        selectDirectory { path in
                            if let path = path {
                                vm.outputPath = path
                            }
                        }
                    }
                }
            }
            
            if vm.isRunning {
                VStack(alignment: .leading) {
                    ProgressView(value: vm.progress)
                        .progressViewStyle(.linear)
                    Text("Progress: \(vm.progressText)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.vertical)
            }

            Button {
                guard !vm.inputPath.isEmpty && !vm.outputPath.isEmpty else { return }
                vm.runIleappInBackground()
            } label: {
                Text(vm.isRunning ? "Running..." : "Start iLEAPP")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(vm.isRunning || vm.inputPath.isEmpty || vm.outputPath.isEmpty)
            
            Button {
                vm.process.terminate()
            } label: {
                Text("Cancel")
                    .frame(maxWidth: .infinity)
            }
            
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(vm.logText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .id("bottom")
                    }
                    .padding()
                }
                .frame(height: 250)
                .onChange(of: vm.logText) {
                    withAnimation {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
            }

            
            Spacer()
        }
        .padding()
        .frame(width: 600)
    }
    
    private func selectDirectory(completion: @escaping (String?) -> Void) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.begin { response in
            if response == .OK {
                completion(panel.url?.path)
            } else {
                completion(nil)
            }
        }
    }
    
}

#Preview {
    ContentView()
}
