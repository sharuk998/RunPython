//
//  ContentView.swift
//  RunPython
//
//  Created by PureLogics-2259 on 17/06/2025.
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var inputPath: String = ""
    @State private var outputPath: String = ""
    @State private var isRunning: Bool = false
    @State private var logText: String = ""
    let pythonQueue = DispatchQueue(label: "com.runpython.pythonQueue")

    init() {
        guard let stdLibPath = Bundle.main.path(forResource: "python-stdlib", ofType: nil),
              let libDynloadPath = Bundle.main.path(forResource: "python-stdlib/lib-dynload", ofType: nil),
              let iLeapLib = Bundle.main.path(forResource: "iLEAPP", ofType: nil) else { return }
        
        setenv("PYTHONHOME", stdLibPath, 1)
        setenv("PYTHONPATH", "\(stdLibPath):\(libDynloadPath):\(iLeapLib):\(iLeapLib)/venv/lib/python3.12/site-packages", 1)
        
        Py_Initialize()
        
        let pyVersionScript = """
            import sys
            print(f"Python version: {sys.version}")
            """
        PyRun_SimpleString(pyVersionScript)
    }
    
    func runIleappInBackground() {
        isRunning = true
        logText = ""
        
        pythonQueue.sync {
//            redirectPythonStdout { outputLine in
//                DispatchQueue.main.async {
//                    logText.append(contentsOf: outputLine + "\n")
//                }
//            }
            
            let gstate = PyGILState_Ensure()

            let argvList = [
                "ileapp.py",
                "-t", "itunes",
                "-i", inputPath,
                "-o", outputPath
            ]
            let argvCode = "import sys; sys.argv = \(argvList)"
            PyRun_SimpleString(argvCode)
            
            let runCode = """
                import ileapp
                ileapp.main()
                """
            PyRun_SimpleString(runCode)
            
            PyGILState_Release(gstate)  // Release GIL

            DispatchQueue.main.async {
                isRunning = false
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            GroupBox(label: Text("Input Directory")) {
                HStack {
                    Text(inputPath.isEmpty ? "No folder selected" : inputPath)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                    Button("Select") {
                        selectDirectory { path in
                            if let path = path {
                                inputPath = path
                            }
                        }
                    }
                }
            }
            
            GroupBox(label: Text("Output Directory")) {
                HStack {
                    Text(outputPath.isEmpty ? "No folder selected" : outputPath)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Spacer()
                    Button("Select") {
                        selectDirectory { path in
                            if let path = path {
                                outputPath = path
                            }
                        }
                    }
                }
            }
            
            Button(action: {
                guard !inputPath.isEmpty && !outputPath.isEmpty else { return }
                runIleappInBackground()
            }) {
                Text(isRunning ? "Running..." : "Start iLEAPP")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isRunning || inputPath.isEmpty || outputPath.isEmpty)
            
            ScrollView {
                Text(logText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .frame(height: 250)
            
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
    
    func redirectPythonStdout(onLine: @escaping (String) -> Void) {
        let pipe = Pipe()
        let fileHandle = pipe.fileHandleForReading
        dup2(pipe.fileHandleForWriting.fileDescriptor, fileno(stdout))
        dup2(pipe.fileHandleForWriting.fileDescriptor, fileno(stderr))
        
        fileHandle.readabilityHandler = { handle in
            let data = handle.availableData
            if let output = String(data: data, encoding: .utf8) {
                output.split(separator: "\n").forEach { line in
                    onLine(String(line))
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
