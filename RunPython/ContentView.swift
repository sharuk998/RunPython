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
    
    func runIleappInBackground() {
        let process = Process()
        process.executableURL = Bundle.main.url(forResource: "iLEAPP/dist/ileapp", withExtension: nil)
        process.arguments = ["-t", "itunes", "-i", inputPath, "-o", outputPath]

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        // abc
        do {
            try process.run()
            
            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            
            process.waitUntilExit()
            
            let output = String(data: outputData, encoding: .utf8) ?? ""
            let error = String(data: errorData, encoding: .utf8) ?? ""
            
            print("Output: \(output)")
            print("Error: \(error)")
            print("Exit code: \(process.terminationStatus)")
            logText = "Output: \(output) \n Error: \(error) \n Exit code: \(process.terminationStatus)"
        } catch {
            print("Error running process: \(error)")
            logText = "Error running process: \(error)"
        }
    }
//    {
//        isRunning = true
//        logText = "runIleappInBackground start"
//        
//        let ileappPath = "\(Bundle.main.resourcePath!)/iLEAPP/ileapp.py"
//        if !FileManager.default.fileExists(atPath: ileappPath) {
//            print("\n❌ ileapp.py not found at path: \(ileappPath)")
//            logText += "\n❌ ileapp.py not found at path: \(ileappPath)"
//        } else {
//            print("\n✅ ileapp.py exists.")
//            logText += "\n✅ ileapp.py exists."
//        }
//
//        pythonQueue.sync {
//            
////            let gstate = PyGILState_Ensure()
////
////            let argvList = [
////                "ileapp.py",
////                "-t", "itunes",
////                "-i", self.inputPath,
////                "-o", self.outputPath
////            ]
////            let argvCode = "import sys; sys.argv = \(argvList)"
////            PyRun_SimpleString(argvCode)
////            
////            let runCode = """
////                import ileapp
////                ileapp.main()
////                """
////            PyRun_SimpleString(runCode)
////            if PyErr_Occurred() != nil {
////                PyErr_Print()
////            }
////            
////            PyGILState_Release(gstate)  // Release GIL
//
//            let ileappPath = "\(Bundle.main.resourcePath!)/iLEAPP/ileapp.py"
//            let input = self.inputPath
//            let output = self.outputPath
//
//            let setupAndRun = """
//            import sys, traceback
//            try:
//                sys.argv = ['ileapp.py', '-t', 'itunes', '-i', '\(input)', '-o', '\(output)']
//                exec(open('\(ileappPath)').read())
//            except Exception:
//                with open('/tmp/ileapp_error.txt', 'w') as f:
//                    traceback.print_exc(file=f)
//            """
//
//            PyRun_SimpleString(setupAndRun)
//
//            // Read Python error log
//            let errorLog = try? String(contentsOfFile: "/tmp/ileapp_error.txt")
//
//            DispatchQueue.main.async {
//                self.isRunning = false
//                self.logText = "runIleappInBackground end\n\n\(errorLog ?? "")"
//            }
//        }
//    }
    
    func loadStartupLog() {
        let supportPath = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let logPath = supportPath.appendingPathComponent("RunPython/startup_log.txt")

        if let log = try? String(contentsOf: logPath) {
            DispatchQueue.main.async {
                self.logText = log
            }
        } else {
            self.logText = "Log file not found."
        }
    }
}

struct ContentView: View {
    
    @StateObject var vm = ViewModel()
    
    init() {
//        guard let bundlePath = Bundle.main.resourcePath else { return }
//        let bundlePath1 = Bundle.main.bundlePath
//
//        let stdLibPath = bundlePath + "/python-stdlib"
//        let libDynloadPath = stdLibPath + "/lib-dynload"
//        let iLeapLib = bundlePath + "/iLEAPP"
//        let sitePackages = iLeapLib + "/venv/lib/python3.12/site-packages"
//        let dyldPath = bundlePath1 + "/Contents/Resources/Python.framework/Versions/3.12/Python"
//        
//        setenv("PYTHONHOME", stdLibPath, 1)
//        setenv("PYTHONPATH", "\(stdLibPath):\(libDynloadPath):\(iLeapLib):\(sitePackages)", 1)
//        setenv("DYLD_LIBRARY_PATH", dyldPath, 1)
//        
//        dlopen(dyldPath, RTLD_GLOBAL | RTLD_LAZY)
//        
//        if dlopen(dyldPath, RTLD_GLOBAL | RTLD_LAZY) == nil {
//            let err = String(cString: dlerror())
//            print("❌ dlopen failed: \(err)")
//        }
//
//        Py_Initialize()
//        
//        // Redirect stdout to a file or buffer you can read
//        let captureLog = """
//        import sys, os
//        import io
//
//        log = io.StringIO()
//        sys.stdout = log
//        sys.stderr = log
//
//        print("Python version:", sys.version)
//        print("PYTHONHOME =", os.environ.get("PYTHONHOME"))
//        print("PYTHONPATH =", os.environ.get("PYTHONPATH"))
//        print("sys.path =", sys.path)
//
//        os.makedirs(os.path.expanduser('~/Library/Application Support/RunPython'), exist_ok=True)
//        with open(os.path.expanduser('~/Library/Application Support/RunPython/startup_log.txt'), 'w') as f:
//            f.write(log.getvalue())
//        """
//        PyRun_SimpleString(captureLog)
    }

    
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
            
            Button(action: {
                guard !vm.inputPath.isEmpty && !vm.outputPath.isEmpty else { return }
                vm.runIleappInBackground()
            }) {
                Text(vm.isRunning ? "Running..." : "Start iLEAPP")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(vm.isRunning || vm.inputPath.isEmpty || vm.outputPath.isEmpty)
            
            ScrollView {
                Text(vm.logText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .frame(height: 250)
            
            Spacer()
        }
        .padding()
        .frame(width: 600)
        .onAppear {
            vm.loadStartupLog()
        }
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
