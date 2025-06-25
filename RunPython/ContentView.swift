//
//  ContentView.swift
//  RunPython
//
//  Created by PureLogics-2259 on 17/06/2025.
//

import SwiftUI

struct ContentView: View {
    
    init() {
        
        
        do {
//            guard let pythonLib = Bundle.main.path(forResource: "Python.framework", ofType: nil) else { return }
            
            guard let stdLibPath = Bundle.main.path(forResource: "python-stdlib", ofType: nil) else { return }
            
            guard let libDynloadPath = Bundle.main.path(forResource: "python-stdlib/lib-dynload", ofType: nil) else { return }
//
//            guard let smallPythonLib = Bundle.main.path(forResource: "SmallPythonLib", ofType: nil) else { return }
//
//            // /Users/purelogics-2259/Developer/RunPython/Python.framework/Python
//            PythonLibrary.useLibrary(at: "\(pythonLib)/Python")
//            try PythonLibrary.loadLibrary()
            
            guard let iLeapLib = Bundle.main.path(forResource: "iLEAPP", ofType: nil) else { return }

//
            setenv("PYTHONHOME", stdLibPath, 1)
            setenv("PYTHONPATH", "\(stdLibPath):\(libDynloadPath):\(iLeapLib):\(iLeapLib)/venv/lib/python3.12/site-packages", 1)
//
//            
//            let sys = Python.import("sys")
//            print("Python Version: \(sys.version_info.major).\(sys.version_info.minor)")
//            print("Python Encoding: \(sys.getdefaultencoding().upper())")
//            print("Python Path: \(sys.path)")
//            
//            let requests = Python.import("requests")
//            print(requests.get)       // should be <function get ...>

//            let main = Python.import("main")
//
//            print(main)
//            let result = main.get_crypto_prices()
//            print(result)
            
//            runMacAPTWithProcess(outputPath: "/output", target: "/")
            
            Py_Initialize()
            
            let pyVersionScript = """
            import sys
            print(f"Python version: {sys.version}")
            """
            PyRun_SimpleString(pyVersionScript)

            runIleapp(inputPath: "/Users/purelogics-2259/Developer/iphone-11-backup", outputPath: "/Users/purelogics-2259/Developer/iLeappOutput")
            
        } catch {
            print("Error \(error)")
        }
        
        
    }
            
    func runIleapp(inputPath: String, outputPath: String) {
        // Build the argument list
        let argvList = [
            "ileapp.py",
            "-t", "itunes",
            "-i", inputPath,
            "-o", outputPath
        ]
        let argvCode = "import sys; sys.argv = \(argvList)"
        PyRun_SimpleString(argvCode)

        // Import and call the main() method
        let runCode = """
        import ileapp
        ileapp.main()
        """
        PyRun_SimpleString(runCode)
    }


    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
