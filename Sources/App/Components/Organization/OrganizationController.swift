import Vapor

struct OrganizationController: RouteCollection {
    
    let application: Application
    
    init(for application: Application) {
        self.application = application
    }
    
    func boot(routes: any RoutesBuilder) throws {
        let organization = routes.grouped("organization")
        organization.post(use: create)
    }
    
    func create(req: Request) async throws -> String {
        let newClientDB = try req.content.decode(ClientDatabase.self)
        guard await !ClientDatabase.exists(for: newClientDB.identifier) else {
            throw Abort(.conflict, reason: "Chosen identifier is already in use.")
        }
        try await ClientDatabase.create(newClientDB)
        try await registerDB(newClientDB, to: application)
        try await registerMigrations(for: newClientDB.id, to: application)
        return ""
    }
}
