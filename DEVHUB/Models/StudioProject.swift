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
        .init(id:"familjen",name:"Familjen",subtitle:"En gemensam plats för familjens vardag.",platform:"iOS",category:"Lifestyle",repository:"fam",progress:0.45,status:.active,symbol:"house.fill",accent:"8B7CFF",nextMilestone:"Familjekalender och delade listor"),
        .init(id:"antikspanaren",name:"Antikspanaren",subtitle:"Hitta, bevaka och upptäck antikviteter.",platform:"iOS",category:"Marketplace",repository:"vill",progress:0.35,status:.active,symbol:"sparkles",accent:"45C6D9",nextMilestone:"Datakällor och bevakningar"),
        .init(id:"regnvakt",name:"Regnvakt",subtitle:"Väder, varningar och radar i en samlad upplevelse.",platform:"iOS",category:"Weather",repository:"project-orbit",progress:0.72,status:.active,symbol:"cloud.bolt.rain.fill",accent:"398BFF",nextMilestone:"Stabil SMHI-varningsmotor"),
        .init(id:"hemma",name:"Hemma",subtitle:"Smarta hemmet samlat i en native Apple-app.",platform:"iOS",category:"Home",repository:"hem",progress:0.50,status:.active,symbol:"house.fill",accent:"568AE8",nextMilestone:"HomeKit och grundläggande rumsvy"),
        .init(id:"devhub",name:"DEVHUB",subtitle:"Kontrollrummet för alla dina appprojekt och AI-utveckling.",platform:"iOS · iPadOS",category:"Developer Tools",repository:"devh",progress:0.35,status:.active,symbol:"command",accent:"7164F2",nextMilestone:"Färdig AI-assistent och GitHub-arbetsflöde")
    ]
}
