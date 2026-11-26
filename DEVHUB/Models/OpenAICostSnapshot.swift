import Foundation

struct OpenAICostSnapshot: Decodable {
    struct DailyCost: Decodable, Identifiable {
        let date: String
        let costUSD: Double
        var id: String { date }
    }

    struct ProjectCost: Decodable, Identifiable {
        let projectID: String
        let costUSD: Double
        var id: String { projectID }
    }

    struct LineItemCost: Decodable, Identifiable {
        let name: String
        let costUSD: Double
        var id: String { name }
    }

    let updatedAt: String
    let monthStart: String
    let currency: String
    let monthToDateUSD: Double
    let daily: [DailyCost]
    let projects: [ProjectCost]
    let lineItems: [LineItemCost]
}
