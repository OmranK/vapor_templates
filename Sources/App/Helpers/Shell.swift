import Foundation

enum Shell {
    static func run(_ command: String) throws -> (output: Data?, error: Data?) {
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", String(format:"%@", command)]
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        process.environment = ["PATH": "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"]
        try process.run()
        process.waitUntilExit()
        let outputData = try outputPipe.fileHandleForReading.readToEnd()
        let errorData = try errorPipe.fileHandleForReading.readToEnd()
        return (outputData, errorData)
        
    }
}
