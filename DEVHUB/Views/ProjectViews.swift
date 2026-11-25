import SwiftUI
struct ProjectCard:View {
    let project:StudioProject
    var body:some View {
        VStack(alignment:.leading,spacing:11){
            HStack{Image(systemName:project.symbol).font(.headline).foregroundStyle(Color(hex:project.accent)).frame(width:34,height:34).background(Color(hex:project.accent).opacity(0.13),in:RoundedRectangle(cornerRadius:10));Spacer();Text(project.status.rawValue).font(.system(size:9,weight:.medium)).foregroundStyle(StudioTheme.lime)}
            Text(project.name).font(.system(size:15,weight:.bold,design:.rounded)).foregroundStyle(.white)
            Text(project.subtitle).font(.system(size:10)).foregroundStyle(StudioTheme.muted).lineLimit(2).multilineTextAlignment(.leading)
            HStack{Text("\(project.platform) · \(project.category)");Spacer();Text("\(Int(project.progress*100))%").foregroundStyle(.white)}.font(.system(size:9)).foregroundStyle(StudioTheme.muted)
            ProgressView(value:project.progress).tint(StudioTheme.lime)
            Text(project.repository).font(.system(size:9,design:.monospaced)).foregroundStyle(StudioTheme.muted).lineLimit(1)
        }.padding(13).frame(maxWidth:.infinity,alignment:.leading).background(StudioTheme.surface,in:RoundedRectangle(cornerRadius:14)).overlay(RoundedRectangle(cornerRadius:14).stroke(StudioTheme.border,lineWidth:1))
    }
}
struct ProjectListView:View {
    let projects:[StudioProject];let onSelect:(StudioProject)->Void
    var body:some View{
        List(projects){project in Button{onSelect(project)}label:{HStack(spacing:12){Image(systemName:project.symbol).foregroundStyle(Color(hex:project.accent)).frame(width:38,height:38).background(StudioTheme.elevated,in:RoundedRectangle(cornerRadius:10));VStack(alignment:.leading,spacing:4){Text(project.name).font(.headline).foregroundStyle(.white);Text(project.repository).font(.caption).foregroundStyle(StudioTheme.muted)};Spacer();Text("\(Int(project.progress*100))%").font(.caption.monospacedDigit()).foregroundStyle(StudioTheme.lime)}}.listRowBackground(StudioTheme.surface)}
        .scrollContentBackground(.hidden).background(StudioTheme.background).navigationTitle("Projekt")
    }
}
struct ProjectDetailView:View {
    let project:StudioProject
    var body:some View{
        ScrollView{VStack(alignment:.leading,spacing:20){ProjectCard(project:project);SectionHeading(eyebrow:"NEXT MILESTONE",title:project.nextMilestone);VStack(alignment:.leading,spacing:9){Label("GitHub-repository",systemImage:"chevron.left.forwardslash.chevron.right").font(.headline);Text("72cbbw422f-alt/\(project.repository)").font(.system(.body,design:.monospaced)).foregroundStyle(StudioTheme.muted);Link("Öppna på GitHub",destination:URL(string:"https://github.com/72cbbw422f-alt/\(project.repository)")!).font(.subheadline.weight(.semibold)).tint(StudioTheme.lime)}.padding(16).frame(maxWidth:.infinity,alignment:.leading).background(StudioTheme.surface,in:RoundedRectangle(cornerRadius:14));IntegrationEmptyState()}.padding(18)}.background(StudioTheme.background).navigationTitle(project.name).navigationBarTitleDisplayMode(.inline)
    }
}
