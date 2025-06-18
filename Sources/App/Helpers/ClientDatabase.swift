import Vapor
import Fluent

@MainActor
struct ClientDatabase: Codable {
    
    static var all: [ClientDatabase] = []
    static var clientsFilePath = "./.clients"
    
    let name: String
    let identifier: String
    
    var id: DatabaseID {
        get { return DatabaseID(string: identifier) }
    }
    
    func db(for request: Request) -> (any Database)? {
        return request.db(id)
    }
    
    static func writeDBs() throws {
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(all)
        try jsonData.write(to: URL(fileURLWithPath: clientsFilePath))
    }
    
    static func readDBs() async throws {
        let fileURL = URL(fileURLWithPath: clientsFilePath)
        let jsonData = try Data(contentsOf: fileURL)
        if let clientDBs = try? JSONDecoder().decode([ClientDatabase].self, from: jsonData) {
            all = clientDBs
        } else {
            let defaultClient = ClientDatabase(name: "demo1", identifier: "demo1")
            try await create(defaultClient)
        }
    }
    
    static func match(for identifier: String) -> ClientDatabase? {
        guard let match = all.first(where: { $0.identifier == identifier }) else { return nil }
        return match
    }

    static func exists(for identifier: String) -> Bool {
        return all.first(where: { $0.identifier == identifier }) != nil
    }
    
    static func create(_ newClientDB: ClientDatabase) async throws {
        if Environment.DBType == .Postgres {
            try await initializePostgresDB(named: newClientDB.identifier)
        } else if Environment.DBType == .MySQL {
            try await initializeMySQLDB(named: newClientDB.identifier)
        } else {
            try await initializeSQLiteDB(named: newClientDB.identifier)
        }
        all.append(newClientDB)
        try writeDBs()
    }
    
    private static func initializePostgresDB(named name: String) async throws {
        let command = "docker exec \(Environment.DatabaseType.Postgres.rawValue) psql -U vapor_username -d postgres -c \"CREATE DATABASE \(name);\""
        let (outputData, errorData) = try Shell.run(command)
        
        guard let outputData = outputData, let consoleOutput = String(data: outputData, encoding: .utf8) else {
            guard let errorData = errorData, let consoleError = String(data: errorData, encoding: .utf8) else {
                throw Abort(.failedDependency)
            }
            var errorReason = "Failed to initialize Postgres database. "
            if consoleError != "" { errorReason.append("Console Error - [\(consoleError)]") }
            throw (Abort(.failedDependency, reason:  errorReason))
        }
        
        guard consoleOutput.contains("CREATE DATABASE") else {
            var errorReason = "Failed to initialize Postgres database. "
            if consoleOutput != "" { errorReason.append("Console Message - [\(consoleOutput)]") }
            throw (Abort(.failedDependency, reason:  errorReason))
        }
        
        return
    }
    
    private static func initializeMySQLDB(named name: String) async throws {}
    private static func initializeSQLiteDB(named name: String) async throws {}
}
