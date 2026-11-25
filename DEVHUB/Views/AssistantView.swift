import SwiftUI

struct AssistantView: View {
    @State private var draft = ""
    private let suggestions = [
        ("magnifyingglass","Granska ett projekt"),
        ("hammer","Felsök senaste bygget"),
        ("list.bullet.clipboard","Planera nästa steg"),
        ("arrow.triangle.branch","Förbered en GitHub-ändring")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment:.leading,spacing:22) {
                VStack(alignment:.leading,spacing:8) {
                    HStack(spacing:8) {
                        Image(systemName:"sparkles").foregroundStyle(StudioTheme.accent)
                        Text("DEVHUB ASSISTENT").font(.system(size:10,weight:.bold)).tracking(1.4).foregroundStyle(StudioTheme.muted)
                    }
                    Text("Vad ska vi bygga idag?").font(.system(size:28,weight:.bold,design:.rounded)).foregroundStyle(StudioTheme.text)
                    Text("En AI-kollega för dina appar, kodbaser och byggen.").font(.subheadline).foregroundStyle(StudioTheme.secondaryText)
                }

                HStack(spacing:10) {
                    Image(systemName:"lock.shield").font(.title3).foregroundStyle(StudioTheme.accent)
                    VStack(alignment:.leading,spacing:3) {
                        Text("Säker anslutning förbereds").font(.subheadline.weight(.semibold)).foregroundStyle(StudioTheme.text)
                        Text("AI-motorn och GitHub-kopplingen aktiveras via en säker server. Inga API-nycklar sparas i appen.").font(.caption).foregroundStyle(StudioTheme.secondaryText)
                    }
                }.padding(14).frame(maxWidth:.infinity,alignment:.leading).background(StudioTheme.surface,in:RoundedRectangle(cornerRadius:14)).overlay(RoundedRectangle(cornerRadius:14).stroke(StudioTheme.border,lineWidth:1))

                VStack(alignment:.leading,spacing:12) {
                    SectionHeading(eyebrow:"SNABBSTART",title:"Vad vill du göra?")
                    ForEach(suggestions,id:\.1) { item in
                        HStack(spacing:12) {
                            Image(systemName:item.0).foregroundStyle(StudioTheme.accent).frame(width:34,height:34).background(StudioTheme.elevated,in:RoundedRectangle(cornerRadius:10))
                            Text(item.1).font(.subheadline.weight(.medium)).foregroundStyle(StudioTheme.text)
                            Spacer()
                            Image(systemName:"arrow.up.right").font(.caption).foregroundStyle(StudioTheme.muted)
                        }.padding(12).background(StudioTheme.surface,in:RoundedRectangle(cornerRadius:12)).overlay(RoundedRectangle(cornerRadius:12).stroke(StudioTheme.border,lineWidth:1))
                    }
                }

                VStack(alignment:.leading,spacing:8) {
                    SectionHeading(eyebrow:"SÅ KOMMER DEN ATT FUNGERA",title:"Du beskriver – assistenten utför")
                    Text("Den ska kunna läsa projekt och kod, analysera fel i GitHub Actions, föreslå ändringar, skapa issues och förbereda commits eller pull requests. Skrivningar till GitHub och andra känsliga åtgärder kräver ditt godkännande.").font(.subheadline).foregroundStyle(StudioTheme.secondaryText).lineSpacing(4)
                }
            }.padding(18).frame(maxWidth:760).frame(maxWidth:.infinity,alignment:.topLeading)
        }.background(StudioTheme.background).navigationTitle("Assistent").navigationBarTitleDisplayMode(.inline)
    }
}