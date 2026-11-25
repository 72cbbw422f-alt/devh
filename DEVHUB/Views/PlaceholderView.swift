import SwiftUI
struct PlaceholderView:View {
    let tab:StudioTab
    var body:some View{
        VStack(spacing:15){Image(systemName:tab.symbol).font(.system(size:34)).foregroundStyle(StudioTheme.lime);Text(tab.rawValue).font(.system(size:25,weight:.bold,design:.rounded));Text(description).font(.subheadline).foregroundStyle(StudioTheme.muted).multilineTextAlignment(.center).padding(.horizontal,35);Text("KOMMER I NÄSTA UTVECKLINGSSTEG").font(.system(size:9,weight:.bold)).tracking(1.5).foregroundStyle(StudioTheme.lime).padding(.top,8)}
        .frame(maxWidth:.infinity,maxHeight:.infinity).background(StudioTheme.background).navigationTitle(tab.rawValue)
    }
    private var description:String{
        switch tab{
        case .activity:"GitHub-aktivitet, commits, branches, pull requests och byggen."
        case .roadmap:"Milstolpar, planerade funktioner och prioriteringar för alla projekt."
        case .revenue:"Intäkter, abonnemang, kostnader och lönsamhet per projekt."
        case .analytics:"Användare, tillväxt och produktstatistik från dina anslutna tjänster."
        default:"Din utvecklingsstudio."
        }
    }
}
