import Vapor

extension Environment {
    static let DBHost = Environment.get("DATABASE_HOST") ?? "localhost"
    static let DBPort = Environment.get("DATABASE_PORT").flatMap(Int.init(_:))
    static let DBUsername = Environment.get("DATABASE_USERNAME") ?? "vapor_username"
    static let DBPassword = Environment.get("DATABASE_PASSWORD") ?? "vapor_password"
    static let DBType = DatabaseType(rawValue: Environment.get("DATABASE_PASSWORD") ?? "postgres")
}

extension Environment {
    enum DatabaseType: String {
        case Postgres = "postgres"
        case MySQL = "mysql"
        case SQLite = "sqlite"
    }
}
