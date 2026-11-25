import SwiftUI
struct OverviewView: View {
    let projects:[StudioProject]
    let onSelect:(StudioProject)->Void
    private let columns=[GridItem(.flexible(),spacing:12),GridItem(.flexible(),spacing:12)]
    var body:some View {
        ScrollView {
            VStack(alignment:.leading,spacing:24) {
                VStack(alignment:.leading,spacing:7) {
                    Text(Date.now.formatted(.dateTime.weekday(.wide).day().month(.wide))).font(.caption.weight(.semibold)).tracking(1.2).foregroundStyle(StudioTheme.muted)
                    Text("Bygg något fantastiskt.").font(.system(size:30,weight:.bold,design:.rounded)).foregroundStyle(.white)
                    Text("Här är läget i din utvecklingsstudio.").font(.subheadline).foregroundStyle(StudioTheme.muted)
                }
                LazyVGrid(columns:columns,spacing:12) {
                    MetricCard(title:"AKTIVA PROJEKT",value:"\(projects.filter{$0.status == .active}.count)",note:"Pågående utveckling",symbol:"square.stack.3d.up")
                    MetricCard(title:"ÖPPNA UPPGIFTER",value:"—",note:"Koppla uppgiftshantering",symbol:"checklist")
                    MetricCard(title:"INTÄKTER / MÅNAD",value:"0 kr",note:"Ingen betalningskälla ansluten",symbol:"arrow.up.right")
                    MetricCard(title:"SENASTE RELEASE",value:"—",note:"Anslut GitHub",symbol:"shippingbox")
                }
                HStack { SectionHeading(eyebrow:"YOUR WORKSPACE",title:"Projektöversikt"); Spacer(); NavigationLink("Alla projekt"){ProjectListView(projects:projects,onSelect:onSelect)}.font(.caption.weight(.semibold)).tint(StudioTheme.lime) }
                LazyVGrid(columns:columns,spacing:12) {
                    ForEach(projects.prefix(6)){ project in Button{onSelect(project)}label:{ProjectCard(project:project)}.buttonStyle(.plain) }
                }
                SectionHeading(eyebrow:"LATEST",title:"Senaste aktivitet")
                IntegrationEmptyState()
            }.padding(18).frame(maxWidth:900).frame(maxWidth:.infinity)
        }.background(StudioTheme.background).navigationTitle("DEVHUB").navigationBarTitleDisplayMode(.inline)
    }
}
struct MetricCard:View {
    let title:String;let value:String;let note:String;let symbol:String
    var body:some View {
        VStack(alignment:.leading,spacing:11){
            HStack{Text(title).font(.system(size:9,weight:.bold)).tracking(0.7).foregroundStyle(StudioTheme.muted);Spacer(minLength:2);Image(systemName:symbol).foregroundStyle(StudioTheme.lime)}
            Text(value).font(.system(size:27,weight:.bold,design:.rounded)).foregroundStyle(.white)
            Text(note).font(.system(size:10)).foregroundStyle(StudioTheme.muted).lineLimit(2)
        }.padding(14).frame(maxWidth:.infinity,alignment:.leading).background(StudioTheme.surface,in:RoundedRectangle(cornerRadius:14)).overlay(RoundedRectangle(cornerRadius:14).stroke(StudioTheme.border,lineWidth:1))
    }
}
struct SectionHeading:View {
    let eyebrow:String;let title:String
    var body:some View{VStack(alignment:.leading,spacing:5){Text(eyebrow).font(.system(size:9,weight:.bold)).tracking(1.5).foregroundStyle(StudioTheme.muted);Text(title).font(.system(size:19,weight:.bold,design:.rounded)).foregroundStyle(.white)}}
}
struct IntegrationEmptyState:View {
    var body:some View{VStack(spacing:9){Image(systemName:"arrow.triangle.branch").font(.title2).foregroundStyle(StudioTheme.lime);Text("Aktivitetsflödet väntar").font(.subheadline.weight(.semibold));Text("Anslut GitHub för att visa commits, pull requests, issues och releaser.").font(.caption).foregroundStyle(StudioTheme.muted).multilineTextAlignment(.center)}.frame(maxWidth:.infinity).padding(25).background(StudioTheme.surface,in:RoundedRectangle(cornerRadius:14))}
}
