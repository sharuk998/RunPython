//
//  ContentView.swift
//  RunPython
//
//  Created by PureLogics-2259 on 17/06/2025.
//

import SwiftUI

struct ContentView: View {
    
    init() {
        
        guard let stdLibPath = Bundle.main.path(forResource: "python-stdlib", ofType: nil) else { return }
        
        guard let libDynloadPath = Bundle.main.path(forResource: "python-stdlib/lib-dynload", ofType: nil) else { return }
        
        guard let iLeapLib = Bundle.main.path(forResource: "iLEAPP", ofType: nil) else { return }
        
        setenv("PYTHONHOME", stdLibPath, 1)
        setenv("PYTHONPATH", "\(stdLibPath):\(libDynloadPath):\(iLeapLib):\(iLeapLib)/venv/lib/python3.12/site-packages", 1)
        
        Py_Initialize()
        
        let pyVersionScript = """
            import sys
            print(f"Python version: {sys.version}")
            """
        PyRun_SimpleString(pyVersionScript)
        
        runIleapp(inputPath: "/Users/purelogics-2259/Developer/iphone-11-backup", outputPath: "/Users/purelogics-2259/Developer/iLeappOutput")
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
