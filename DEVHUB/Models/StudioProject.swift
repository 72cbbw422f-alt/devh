import Foundation
enum ProjectStatus: String, CaseIterable, Identifiable {
    case active = "Pågår", planning = "Planeras", paused = "Pausad", released = "Släppt"
    var id: String { rawValue }
}
struct StudioProject: Identifiable, Hashable {
    let id: String
    var name: String
    var subtitle: String
    var platform: String
    var category: String
    var repository: String
    var progress: Double
    var status: ProjectStatus
    var symbol: String
    var accent: String
    var nextMilestone: String
    static let samples: [StudioProject] = [
        .init(id:"regnvakt",name:"Regnvakt",subtitle:"Väder, varningar och radar i en samlad upplevelse.",platform:"iOS",category:"Weather",repository:"project-orbit",progress:0.72,status:.active,symbol:"cloud.bolt.rain.fill",accent:"70B7F4",nextMilestone:"Stabil SMHI-varningsmotor"),
        .init(id:"vital",name:"VITAL",subtitle:"Personlig hälsa, återhämtning och smarta rapporter.",platform:"iOS",category:"Health",repository:"vit",progress:0.58,status:.active,symbol:"heart.text.square.fill",accent:"B6EF70",nextMilestone:"Dagliga rapporter och HealthKit"),
        .init(id:"familjen",name:"Familjen",subtitle:"En gemensam plats för familjens vardag.",platform:"iOS",category:"Lifestyle",repository:"fam",progress:0.45,status:.active,symbol:"house.fill",accent:"D8BC91",nextMilestone:"Familjekalender och delade listor"),
        .init(id:"antikspanaren",name:"Antikspanaren",subtitle:"Hitta, bevaka och upptäck antikviteter.",platform:"iOS",category:"Marketplace",repository:"vill",progress:0.35,status:.active,symbol:"sparkles",accent:"E59BB6",nextMilestone:"Datakällor och bevakningar"),
        .init(id:"bingelog",name:"BingeLog",subtitle:"Håll koll på filmer, serier och tittarhistorik.",platform:"iOS",category:"Entertainment",repository:"binge",progress:0.64,status:.active,symbol:"popcorn.fill",accent:"B9A0F2",nextMilestone:"Progress-lista och importflöde"),
        .init(id:"newsflow",name:"NEWSFLOW",subtitle:"RSS med en genuin native Apple-känsla.",platform:"iOS",category:"News",repository:"news",progress:0.40,status:.active,symbol:"newspaper.fill",accent:"82D0CA",nextMilestone:"OPML och flödeshantering"),
        .init(id:"nexus",name:"NEXUS",subtitle:"Samlad IPTV- och Jellyfin-upplevelse.",platform:"iOS · tvOS",category:"Media",repository:"nex",progress:0.30,status:.planning,symbol:"play.rectangle.fill",accent:"E6B86D",nextMilestone:"Uppspelning och bibliotek"),
        .init(id:"orbit",name:"ORBIT",subtitle:"En snabb och genomtänkt Reddit-klient.",platform:"iOS",category:"Social",repository:"orb",progress:0.50,status:.active,symbol:"circle.hexagongrid.fill",accent:"E89A72",nextMilestone:"Feed och sökfunktion")
    ]
}
