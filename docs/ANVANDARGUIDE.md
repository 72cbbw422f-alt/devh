# DEVHUB – användarguide

> Arbetsdokument. Uppdateras i takt med att funktionerna färdigställs och verifieras.

## 1. Vad DEVHUB gör

DEVHUB är en iOS-app där du kan skicka utvecklingsuppdrag till Byte, följa arbetet och granska kodförslag. Appen använder GitHub Actions för att köra arbetet. Dina uppdrag och deras status sparas lokalt i appens SwiftData-databas.

## 2. Innan du börjar

- Du behöver ett GitHub-token som appen kan använda för att läsa DEVHUB:s Actions-körningar.
- Tokenen sparas i iOS-nyckelringen på enheten.
- Appen visar instruktioner och en länk för att skapa token. Behörigheten som anges i appen är **Actions: Read and write** för DEVHUB-repot.
- En separat GitHub Secret, `PROJECTS_GITHUB_TOKEN`, används av arbetsflödet för att skriva till projekt. Den ska inte klistras in i appen eller delas med någon.

Spara aldrig token i ett vanligt meddelande, en skärmbild eller i ett projektuppdrag.

## 3. Arbetsinställningar

- **Snabbt svar:** enkla allmänna frågor. Projektet läses inte in.
- **Samarbeta:** fortsätt en tidigare Byte-konversation. Välj ett tidigare uppdrag och använd knappen för att återuppta samtalet.
- **Godkänn först:** Byte analyserar projektet och kan visa konkreta kodförslag som diff. Förslagen är förhandsvisningar; inget skickas för ändring förrän du uttryckligen godkänner.
- **Autopilot:** Byte analyserar uppdraget självständigt och föreslår nästa steg. Automatisk kodskrivning och PR-skapande är ännu inte aktiverat i detta läge.

Övriga inställningar:
- Automatiska byggningar och automatiska pull requests är ännu inte aktiverade i appen. Kodförslag kräver fortsatt uttryckligt godkännande.
- **Månatligt AI-budgetmål:** ett lokalt planeringsvärde i kronor. Det är inte en automatisk kostnadsspärr och stoppar inte AI-anrop. Kontrollera faktisk användning och kostnad i den tjänst som utför AI-arbetet.

## 4. Skicka ett uppdrag

1. Välj rätt projekt i listan.
2. Beskriv vad Byte ska undersöka eller göra. Skriv gärna vad som är fel, vad du vill uppnå och vad som inte får ändras.
3. Tryck på **Skicka till AI-assistenten**.
4. Följ statusen i **Bytes arbetskö**. Skicka inte samma uppdrag igen bara för att appen tar tid på sig.

## 5. Förstå arbetskön

- **Aktiva:** uppdrag som väntar eller körs.
- **PR väntar:** ett godkänt kodförslag skickas eller behandlas av GitHub.
- **Klara:** analysen eller kodförslagsflödet är färdigt.
- **Fel / Misslyckade:** ett arbetsflöde har rapporterat ett fel.

Du kan söka i uppdrag, filtrera på projekt och status samt uppdatera status manuellt. Appen kontrollerar väntande GitHub-flöden automatiskt ungefär var 60:e sekund när vyn är aktiv. I appen finns också en utfällbar förklaring under **Vad betyder statusarna?**.

Om appen visar timeout kan GitHub fortfarande arbeta. Kontrollera den befintliga GitHub-körningen innan du skickar samma uppdrag igen.

## 6. Kodförslag och godkännande

Ett kodförslag visas som en diff – en jämförelse som visar vilka rader som föreslås tas bort och läggas till.

- Läs uppdraget och förslaget innan du godkänner.
- Appen visar den granskade grundversionens korta commit-ID. Om projektets huvudgren har ändrats sedan analysen skapades ska förslaget inte kunna användas mot en annan version.
- Godkännande skapar en separat pull request. Den slås inte ihop automatiskt.
- GitHub kontrollerar grundversionen innan ändringen behandlas.
- Resultatet ska granskas i en separat pull request. En pull request (PR) är ett förslag till ändring som går att granska innan den förs in i projektets huvudgren.

Om ett försök misslyckas kan du få möjlighet att försöka skapa PR igen. Kontrollera alltid den befintliga GitHub-körningen innan du upprepar ett steg som kan ha skickats men där appen tappat kontakten.

## 7. Om något verkar ha fastnat

1. Vänta en stund och använd uppdateringsknappen i arbetskön.
2. Öppna GitHub-körningen om appen visar en länk.
3. Kontrollera om körningen fortfarande pågår eller har avslutats med fel.
4. Skicka inte ett nytt identiskt uppdrag innan du vet vad som hänt med det första.
5. Om GitHub nekar åtkomst: kontrollera token och dess Actions-behörighet.

Ett meddelande om timeout betyder inte automatiskt att GitHub-arbetet misslyckades. Det kan fortfarande köras i bakgrunden.

## 8. Viktigt om säkerhet

- Godkänn inte en diff du inte förstår eller inte avsåg att skapa.
- Dela inte GitHub-token eller hemligheter i uppdrag.
- Radering och överskrivning ska hanteras med extra försiktighet.
- Granska alltid pull request innan en ändring förs in i projektet.

## 9. Vad som återstår i guiden

Den slutliga genomgången ska kompletteras med skärmbilder och exakta steg för varje skärm när funktionerna och gränssnittet är färdigtestade. Guiden ska också skilja tydligt mellan funktioner som är klara, funktioner som är under utveckling och sådant användaren själv behöver göra.


### Om projektets kod har ändrats efter granskningen

När du godkänner ett kodförslag kontrollerar GitHub att projektets `main`-branch fortfarande motsvarar den grundversion som visas i DEVHUB. Om någon har hunnit ändra projektet sedan analysen gjordes stoppas förslaget av säkerhetsskäl. Skicka då inte samma diff igen. Kör en ny analys med Byte så att förslaget byggs mot den senaste koden och granska den nya diffen innan du godkänner.


### AI-användning i arbetskön

Arbetskön visar en summering av den användningsdata som sparats för uppdragen: registrerade in- och utgående token samt beräknad kostnad i USD. Summan omfattar bara uppdrag där användningsdata har hämtats och sparats i appen. Den är en uppskattning, inte en faktura, och ersätter inte kontroll av faktisk förbrukning hos AI-leverantören. Budgetmålet i inställningarna är fortfarande endast ett lokalt planeringsvärde.
