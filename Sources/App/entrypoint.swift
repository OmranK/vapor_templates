import Vapor
import Logging
import NIOCore
import NIOPosix
{{#fluent}}import NIOSSL
import Fluent
import Fluent{{fluent.db.module}}Driver{{/fluent}}
{{#leaf}}import Leaf{{/leaf}}

@main
enum Entrypoint {
    static func main() async throws {
        var env = try Environment.detect()
        try LoggingSystem.bootstrap(from: &env)
        
        let app = try await Application.make(env)
        
        do {
            try await configure(app)
            try await app.execute()
        } catch {
            app.logger.report(error: error)
            try? await app.asyncShutdown()
            throw error
        }
        try await app.asyncShutdown()
    }
}

public func configure(_ app: Application) async throws {
    
    {{#fluent}}{{#fluent.db.is_postgres}}app.databases.use(DatabaseConfigurationFactory.postgres(configuration: .init(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? SQLPostgresConfiguration.ianaPortNumber,
        username: Environment.get("DATABASE_USERNAME") ?? "vapor_username",
        password: Environment.get("DATABASE_PASSWORD") ?? "vapor_password",
        database: Environment.get("DATABASE_NAME") ?? "vapor_database",
        tls: .prefer(try .init(configuration: .clientDefault)))
    ), as: .psql){{/fluent.db.is_postgres}}{{#fluent.db.is_mysql}}app.databases.use(DatabaseConfigurationFactory.mysql(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? MySQLConfiguration.ianaPortNumber,
        username: Environment.get("DATABASE_USERNAME") ?? "vapor_username",
        password: Environment.get("DATABASE_PASSWORD") ?? "vapor_password",
        database: Environment.get("DATABASE_NAME") ?? "vapor_database"
    ), as: .mysql){{/fluent.db.is_mysql}}{{#fluent.db.is_sqlite}}app.databases.use(DatabaseConfigurationFactory.sqlite(.file("db.sqlite")), as: .sqlite){{/fluent.db.is_sqlite}}

    app.migrations.add(CreateTodo()){{/fluent}}{{#leaf}}

    app.views.use(.leaf){{/leaf}}

    // register routes
    try routes(app)
}
