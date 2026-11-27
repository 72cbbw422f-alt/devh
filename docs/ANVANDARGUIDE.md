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
- **Klara:** analysen eller kodförslagsflödet är färdigt och inget senare steg har misslyckats.
- **Fel / Misslyckade:** felstatus har företräde även om ett tidigare steg lyckades.
- Statusfiltren är ömsesidigt konsekventa: ett uppdrag med misslyckad analys eller PR hamnar under **Misslyckade**, inte samtidigt under **Klara**. Ett PR som fortfarande behandlas visas under **PR väntar**. Statusrutorna **Aktiva**, **PR väntar**, **Klara** och **Fel** går också att trycka på för att välja motsvarande filter direkt.

Varje historikpost visar om den faktiskt innehåller ett uppdrag, ett icke-tomt analysresultat, ett icke-tomt kodförslag eller båda. Historikens innehållsetiketter och innehållsfiltret använder samma kontroll, så tomma resultat räknas inte som sparat innehåll. Du ser både när uppdraget skapades och när det senast uppdaterades. Den tydliga huvudstatusen tar hänsyn till både analysen och PR-arbetet: ett misslyckat PR markeras som misslyckat även om själva analysen lyckades, och ett skapat PR visas som redo för granskning. Det gör det lättare att skilja äldre analyser från senare kodförslag och hitta rätt steg i arbetet. Du kan söka i uppdrag, filtrera på projekt, status och innehållstyp samt uppdatera status manuellt. Statusrutorna **Aktiva**, **PR väntar**, **Klara** och **Fel** går också att trycka på för att direkt välja motsvarande statusfilter. Innehållsfiltret kan visa poster som har analys, kodförslag eller båda delarna. Sökningen omfattar uppdragstitel, projektrepo, analysresultat, GitHub-fel, fel vid PR-skapande och kodförslagets diff. Använd rensa-symbolen i sökfältet för att tömma sökningen; om kombinationen av sökning och filter inte ger träffar kan du välja **Rensa alla filter**. Appen kontrollerar väntande GitHub-flöden automatiskt ungefär var 60:e sekund när vyn är aktiv. Om en avslutad körning saknar ett faktiskt analysresultat försöker appen hämta resultatet igen vid statuskontroll; även tomma eller enbart blanksteg räknas som saknat resultat. Samma princip gäller felorsaker från GitHub: tomma eller enbart blanksteg hämtas på nytt när du uppdaterar status eller begär felorsaken. Tomma feltexter visas inte som en felorsak i kön medan appen hämtar den faktiska informationen. I appen finns också en utfällbar förklaring under **Vad betyder statusarna?**.

Om appen visar timeout kan GitHub fortfarande arbeta. Kontrollera den befintliga GitHub-körningen innan du skickar samma uppdrag igen.

## 6. Kodförslag och godkännande

Ett kodförslag visas som en diff – en jämförelse som visar vilka rader som föreslås tas bort och läggas till.

- Läs uppdraget och förslaget innan du godkänner.
- **Dela kodförslag:** använd delningsknappen vid diffen om du vill skicka eller spara själva patchtexten för separat granskning. Delning godkänner eller tillämpar inte ändringen.
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

Arbetskön visar en summering av den användningsdata som sparats för uppdragen: registrerade in- och utgående token samt beräknad kostnad i USD. Summan omfattar bara uppdrag där användningsdata har hämtats och sparats i appen. Under summeringen kan du fälla ut kostnad per projekt. Projekten sorteras efter högst registrerad kostnad först; varje rad visar antal uppdrag samt in- och utgående token. Projekt utan sparad användningsdata visas inte. Beloppen är uppskattningar, inte en faktura, och ersätter inte kontroll av faktisk förbrukning hos AI-leverantören. Budgetmålet i inställningarna är fortfarande endast ett lokalt planeringsvärde.
