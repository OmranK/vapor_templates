import Vapor
import Logging
import NIOCore
import NIOPosix
{{#fluent}}
import NIOSSL
import Fluent
import Fluent{{fluent.db.module}}Driver
{{/fluent}}
{{#leaf}}
import Leaf
{{/leaf}}

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

private func configure(_ app: Application) async throws {
    {{#fluent}}
    try await ClientDatabase.readDBs()
    try await registerDBs(to: app)
    try await registerMigrations(to: app)
    {{/fluent}}
    {{#leaf}}
    app.views.use(.leaf)
    {{/leaf}}
    try routes(app)
}

{{#fluent}}
@MainActor
func registerDBs(to app: Application) throws {
    try ClientDatabase.all.forEach {
        try registerDB($0, to: app)
    }
}

@MainActor
func registerDB(_ db: ClientDatabase, to app: Application) throws {
    {{#fluent.db.is_postgres}}
    app.databases.use(try DatabaseConfigurationFactory.defaultPostgresConfiguration(for: db), as: db.id)
    {{/fluent.db.is_postgres}}
    {{#fluent.db.is_mysql}}
    app.databases.use(DatabaseConfigurationFactory.defaultMySQLConfiguration(for: db), as: db.id)
    {{/fluent.db.is_mysql}}
    {{#fluent.db.is_sqlite}}
    app.databases.use(DatabaseConfigurationFactory.sqlite(.file("db.sqlite")), as: db.id)
    {{/fluent.db.is_sqlite}}
}

@MainActor
func registerMigrations(for id: DatabaseID? = nil, to app: Application) async throws {
    if let id = id {
        registerMigrations(for: id)
    } else {
        ClientDatabase.all.forEach { registerMigrations(for: $0.id) }
    }
    
    try await app.autoMigrate()
    
    func registerMigrations(for id: DatabaseID) {
//        app.migrations.add(UserModelMigration(), to: id)
    }
}
{{/fluent}}

{{#fluent.db.is_postgres}}
extension DatabaseConfigurationFactory {
    fileprivate static func defaultPostgresConfiguration(for db: ClientDatabase) throws -> DatabaseConfigurationFactory {
        return DatabaseConfigurationFactory.postgres(configuration: try SQLPostgresConfiguration(for: db))
    }
}

extension SQLPostgresConfiguration {
    init(for db: ClientDatabase) throws {
        var tlsConfig = TLSConfiguration.clientDefault
        #if DEBUG
        tlsConfig.certificateVerification = .none
        #endif
        let configuration = PostgresConnection.Configuration(
            host: Environment.DBHost,
            port: Environment.DBPort ?? SQLPostgresConfiguration.ianaPortNumber,
            username: Environment.DBUsername,
            password: Environment.DBPassword,
            database: db.name,
            tls: .prefer(try .init(configuration: tlsConfig))
        )
        self.init(coreConfiguration: configuration)
    }
}
{{/fluent.db.is_postgres}}
{{#fluent.db.is_mysql}}
extension DatabaseConfigurationFactory {
    fileprivate static func defaultMySQLConfiguration(for db: ClientDatabase) -> DatabaseConfigurationFactory {
        return DatabaseConfigurationFactory.mysql(configuration: MySQLConfiguration(for: db))
    }
}

extension MySQLConfiguration {
    init(for db: ClientDatabase) {
        var tlsConfig = TLSConfiguration.clientDefault
        #if DEBUG
        tlsConfig.certificateVerification = .none
        #endif
        self.init(
            hostname: Environment.DBHost,
            port: Environment.DBPort ?? MySQLConfiguration.ianaPortNumber,
            username: Environment.DBUsername,
            password: Environment.DBPassword,
            database: db.name,
            tlsConfiguration: tlsConfig
        )
    }
}
{{/fluent.db.is_mysql}}
