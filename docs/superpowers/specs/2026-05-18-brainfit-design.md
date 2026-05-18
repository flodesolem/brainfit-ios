# Brainfit — designspesifikasjon

**Dato:** 2026-05-18
**Status:** Godkjent for planlegging
**Eier:** Frode Solem
**Lisens:** MIT (åpen kildekode)

## Sammendrag

Brainfit er en åpen kildekode iOS-app for hjernetrim, inspirert av Lumosity, Elevate og Impulse. MVP leverer to spill (N-back og Stroop) bygget på en utvidbar `Game`-protokoll som lar bidragsytere legge til nye spill ved å implementere én kontrakt. Appen kjører lokalt med valgfri iCloud-sync via CloudKit. Daglig økt-modell med streak-belønning er kjernen i brukeropplevelsen.

## Mål

- Lever et fungerende iOS MVP (iOS 17+) med to spill og fullstendig daglig-økt-flyt
- Etabler en plattform-arkitektur der nye spill kan legges til uten å endre core-kode
- Hold åpen kildekode-friksjon lav: tydelig `ADDING_A_GAME.md`, MIT-lisens, CI fra dag én
- Tilgjengelighet i bunn: VoiceOver-støtte, Dynamic Type, kontrast

## Ikke-mål (for MVP)

- Brukerkontoer, leaderboards, sosial deling
- Egen backend-server
- Android- eller web-versjon
- Mer enn to spill i første utgivelse
- Lokalisering utover bokmål (struktur klargjøres, oversettelser kommer senere)
- Fri-spill-bibliotek (kun "spill fritt"-snarvei til Stats i MVP)

## Plattform og stack

- **iOS 17+**, krever iPhone XS eller nyere
- **SwiftUI** gjennomgående, ingen UIKit-bro
- **SwiftData** for lokal lagring
- **CloudKit** (privat database) for valgfri sync
- **Swift Charts** for statistikk-grafer
- **XCTest / XCUITest** for testing
- **SF Symbols** for ikoner
- **SF Pro** typografi

## Modulstruktur

Ett Xcode-prosjekt, organisert i mapper:

```
Brainfit/
├── App/                     # @main, root-view, navigasjon
├── Core/
│   ├── GameProtocol.swift   # Game-kontrakten
│   ├── GameRegistry.swift   # Registrerer tilgjengelige spill
│   ├── GameRun.swift        # SwiftData-modell, ett spill-resultat
│   └── DailySession.swift   # Velger dagens spill, sporer fremgang
├── Engine/
│   ├── SessionEngine.swift  # Driver økten: intro → spill → resultat → neste
│   └── ScoreCalculator.swift
├── Games/
│   ├── NBack/
│   └── TapTheColor/
├── Features/
│   ├── Home/
│   ├── Stats/
│   └── Settings/
├── Persistence/
│   └── ModelContainer.swift
└── DesignSystem/            # Theme, farger, typografi, knapper
```

Prinsipper:
- `Core/` og `Engine/` kjenner bare `Game`-protokollen — ikke spesifikke spill
- Hvert spill i `Games/` er selvstendig (view, viewmodel, konfig) og registreres i `GameRegistry`
- Nytt spill = ny mappe + én registreringslinje. Ingen core-endring

## Game-protokollen

```swift
protocol Game {
    static var metadata: GameMetadata { get }
    associatedtype IntroView: View
    associatedtype PlayView: View

    func makeIntroView() -> IntroView
    func makePlayView(difficulty: Difficulty,
                      onComplete: @escaping (GameResult) -> Void) -> PlayView
}

struct GameMetadata {
    let id: String                 // "nback", "tap-the-color"
    let displayName: String        // "Husk Mønsteret"
    let category: GameCategory     // .memory, .reaction, .attention, ...
    let shortDescription: String
    let icon: String               // SF Symbol-navn
    let targetDurationSeconds: Int // typisk 60–90 sek
}

struct GameResult {
    let gameId: String
    let score: Int                 // normalisert 0–1000
    let accuracy: Double           // 0–1
    let durationSeconds: Double
    let difficulty: Difficulty
    let rawMetrics: [String: Double]
}

enum Difficulty: Int, Codable { case easy = 1, medium = 2, hard = 3 }

enum GameCategory: String, Codable {
    case memory, reaction, attention, language, math, problemSolving
}
```

Begrunnelser:
- Protocol med `associatedtype` for views → ingen `AnyView`-overhead, sterke typer
- `rawMetrics` som fri ordbok → spill kan lagre egne målinger uten core-endring
- `Difficulty` styres av engine, ikke spill → konsistens på tvers
- Spill eier ikke lagring, navigasjon eller vanskelighetsalgoritme

## DailySessionEngine

Driver brukerens daglige opplevelse.

Oppførsel:
1. Sjekker om dagens økt er fullført. Hvis ja → vis "ferdig" + streak-status
2. Hvis nei → velg N spill (MVP: 2, én av hvert tilgjengelige). Senere: 3 + roterende
3. Tildel vanskelighet per spill basert på snitt-score siste 5 `GameRun` for samme spill:
   - Snitt > 700 → +1 nivå (cap på `hard`)
   - Snitt < 400 → −1 nivå (gulv på `easy`)
   - Ellers → behold forrige nivå (start `medium` ved første gang)
4. Driv flowen: intro → play → resultat → neste spill → totalresultat
5. Lagre `GameRun` til SwiftData (synker til CloudKit i bakgrunnen)
6. Oppdater `StreakState` ved fullført økt

Streak-regler:
- Teller dag-for-dag basert på siste fullførte økt
- Brutt etter 36 timer uten ny økt (margin for tidssone-vandring)
- Sammenligning gjøres mot kalenderdato i brukerens nåværende tidssone, ikke timestamps

Edge cases:
- Avsluttet midt i økten → ingenting lagres, streak påvirkes ikke (alt-eller-ingenting per økt)
- Klokke-justering bakover → kalenderdato-sammenligning, ikke epoch

Eksponering: `@Observable SessionState` som UI binder seg til. Engine tegner ingenting selv.

## Datamodell (SwiftData + CloudKit)

CloudKit krever default-verdier på alle felt og at relasjoner er valgfrie.

```swift
@Model
final class GameRun {
    var id: UUID = UUID()
    var gameId: String = ""
    var playedAt: Date = Date()
    var score: Int = 0
    var accuracy: Double = 0
    var durationSeconds: Double = 0
    var difficulty: Int = 2
    var rawMetricsJSON: String = "{}"
    var sessionId: UUID?
}

@Model
final class DailySessionRecord {
    var id: UUID = UUID()
    var date: Date = Date()      // brukerens lokale dag, midnatt-normalisert
    var completedAt: Date?
    var gameRunIds: [UUID] = []
    var totalScore: Int = 0
}

@Model
final class StreakState {
    var id: UUID = UUID()        // singleton-rad
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var lastSessionDate: Date?
}
```

Designvalg:
- `rawMetricsJSON` som string → unngår CloudKit-vansker med assosierte typer
- `gameId` som string, ikke enum → databasen brytes ikke når spill legges til/fjernes
- `StreakState` som egen singleton-rad → unngår tunge spørringer ved hver app-åpning
- Ingen `User`-modell → iCloud-konto er identitet implisitt

CloudKit: privat database, automatisk sync. Hvis ikke logget på iCloud → fungerer lokalt, diskret merke i Settings.

## UI-skjermbilder

Tab-navigasjon (Hjem, Stats, Innstillinger). Økt åpnes modalt fra Hjem.

### HomeView
- Hilsen + dato
- Stor "Start dagens trening"-knapp, eller "Fullført" hvis dagens økt er gjort
- Streak-tall med flamme-ikon (SF Symbol)
- Snarvei-stripe: "Spill fritt" → åpner Stats i MVP

### SessionFlowView (full-screen modal)
- Sekvens: `GameIntroView` (5 sek nedtelling) → `GamePlayView` → `GameResultView` (score, "neste")
- Etter siste spill: `SessionSummaryView` (totalscore, oppdatert streak, "Ferdig")
- Avbryt-knapp øverst, krever bekreftelse, økten kastes

### StatsView
- Linjediagram: snittscore per dag siste 30 dager (Swift Charts)
- Per-spill-kort: beste score, antall økter, siste vanskelighet
- Tidsromsfilter: 7 / 30 / 90 dager

### SettingsView
- iCloud-status (synket / ikke logget på)
- Daglig påminnelse (UNUserNotificationCenter, valgfritt tidspunkt)
- Lyd av/på
- Om: versjon, lisens-link, GitHub-link

### Designsystem
- `Theme.swift` med farger, typografi, spacing-konstanter
- Tone-i-tone, ikke lekende
- Mørk modus fra dag én via Asset Catalog
- Dynamic Type respekteres
- VoiceOver-labels på alle interaktive elementer

## Spill-spesifikasjoner

### Spill 1: N-Back ("Husk Mønsteret")

Klassisk visuell N-back. 3×3 rutenett. Firkant blinker blå i 500 ms, pause 2 sek, ny blink. Spilleren trykker "Match" når dagens blink-posisjon er lik den fra N runder siden.

- Vanskelighet: N = 1 (easy), 2 (medium), 3 (hard)
- 20 stimuli per runde, varighet ~50 sek
- Scoring: `score = round(1000 * (hits / targets) * (1 - falseAlarms / nonTargets))`
- `rawMetrics`: `hits`, `misses`, `falseAlarms`, `correctRejections`, `avgReactionMs`
- Kategori: `.memory`

### Spill 2: Tap-the-Color (Stroop)

Skjermen viser et ord (f.eks. "RØD") tegnet i en farge (f.eks. blå). Fire fargeknapper nederst. Spilleren trykker fargen ordet er **skrevet i**. Halvparten av stimuli kongruente, halvparten ikke.

- Tidsbasert: 30 sekunder, så mange riktige som mulig
- Scoring: `score = round(correct * 50 - incorrect * 30 + speedBonus)`, `speedBonus = max(0, 200 - avgMs / 10)`
- `rawMetrics`: `correct`, `incorrect`, `avgMs`, `congruentMs`, `incongruentMs`
- Kategori: `.attention`
- Vanskelighet justerer antall fargevalg (3/4/5) og om nøytrale distraktører vises

Hvorfor dette paret tester plattformen:
- N-back: runder med pause → tester at `GamePlayView` kontrollerer egen timing
- Stroop: kontinuerlig input med nedtelling → tester at engine ikke antar runde-struktur
- Ulik bruk av `rawMetrics` → bekrefter at fri-form ordbok er riktig valg

## Test-strategi

### Unit-tester (`BrainfitTests`)
- `ScoreCalculator`-funksjoner per spill
- `DailySessionEngine`: vanskelighetsvalg, streak-oppdatering, dato-grenser, 36-timers vindu
- `StreakState`-overganger (ny dag, brudd, gjenoppstart)
- Tidssone-edge cases: midnatt-krysning, tidssone-bytte under reise
- JSON-encoding/decoding av `rawMetrics` (round-trip)

### Spill-logikk-tester
- N-back: deterministisk stimuli + input-script → forventet `GameResult`
- Stroop: fast seed + forventet input → deterministisk score
- Hvert spill eksponerer `gameSession(seed:)` for tester. Produksjon bruker `SystemRandomNumberGenerator`

### UI-tester (`BrainfitUITests`, sparsomt)
- Happy path: åpne → start → fullfør begge spill → sammendrag
- Avbryt-knapp i økt → bekreftelse → tilbake til hjem, økt ikke lagret
- Tilgjengelighetstest: VoiceOver-navigasjon til "Start"-knapp

### Ikke testet (med vilje)
- SwiftData/CloudKit end-to-end (Apples kode, flakey)
- Pixel-perfekt rendering (snapshot-tester gir mer vedlikehold enn verdi for MVP)

### CI
- GitHub Actions: `xcodebuild test` på macos-latest, iPhone 15 / iOS 17 simulator
- Trigges på push og PR
- SwiftLint som separat job, advarer ikke blokkerer
- Unit + spill-tester blokkerer PR; UI-tester gir kun advarsel

## Åpen kildekode-oppsett

### Lisens
MIT. Tillater kommersiell bruk, krever bare lisensvarsel beholdes.

### Repo-struktur
```
brainfit-ios/
├── Brainfit.xcodeproj
├── Brainfit/
├── BrainfitTests/
├── BrainfitUITests/
├── .github/
│   ├── workflows/ci.yml
│   ├── ISSUE_TEMPLATE/        # bug, feature, new-game
│   └── PULL_REQUEST_TEMPLATE.md
├── docs/
│   ├── ADDING_A_GAME.md
│   ├── ARCHITECTURE.md
│   └── DESIGN_PRINCIPLES.md
├── README.md
├── CONTRIBUTING.md
├── CODE_OF_CONDUCT.md
├── LICENSE
├── .swiftlint.yml
└── CHANGELOG.md
```

### Navngivning
- App-navn: **Brainfit**
- Repo: `brainfit-ios` (åpner for `brainfit-android` senere)
- Bundle ID: `com.frodesolem.brainfit` inntil eget domene anskaffes

### Prioritert dokumentasjon
- `ADDING_A_GAME.md` er kjerne-doc — det er hele verdien av plattform-arkitekturen
- "Good first issue"-labels på nye spill-implementasjoner

### Repo-plassering lokalt
`~/dev/brainfit-ios/` (utenfor `~/claude/` som er Sigma2-admin)

## Agent-team og kjøremønster

Agent-teamet består av `general-purpose`-agenter med spesialiserte mandater (ikke pre-definerte roller).

### Agent 1 — Plattform-kjerne (sekvensiell, må gjøres først)
- `Game`-protokoll, `GameRegistry`, `DailySessionEngine`
- SwiftData-modeller + CloudKit-konfig
- Repository-protokoller (`GameRunRepository`, `StreakRepository`)
- `SessionFlowView`-skall
- Begrunnelse: alt annet importerer fra dette laget

### Agent 2 — N-Back-spill (parallell med 3 og 4)
- `NBackGame.swift`, `NBackView.swift`, `NBackViewModel.swift`
- Scoring + unit-tester med deterministisk seed
- Avhenger av: Agent 1's `Game`-protokoll

### Agent 3 — Tap-the-Color-spill (parallell med 2 og 4)
- Tilsvarende struktur for Stroop
- Ingen avhengighet til Agent 2

### Agent 4 — UI-skall og designsystem (parallell)
- `HomeView`, `StatsView`, `SettingsView`, `Theme.swift`
- Tab-navigasjon, modal økt-presentasjon
- VoiceOver-labels, Dynamic Type
- Avhenger av: Agent 1's `SessionState` (kan starte med stubs)

### Agent 5 — Åpen kildekode + CI (parallell, uavhengig)
- README, CONTRIBUTING, ADDING_A_GAME, LICENSE, CHANGELOG
- GitHub Actions workflow, SwiftLint-konfig, issue/PR-templates
- Kan kjøre fra dag én

### Kjøremønster
1. Agent 1 alene først (~30–60 min)
2. Når Agent 1 har committed kontraktene: Agent 2, 3, 4, 5 parallelt
3. Hver agent skriver tester for det den leverer (ingen separat QA-agent — testene er del av implementasjonen)

Estimert kjøretid: 2–4 timer agentarbeid for fungerende MVP-skall. Polering og enhets-testing skjer av eier etterpå.

## Suksesskriterier

MVP regnes som ferdig når:

1. App kompilerer og kjører på iOS 17-simulator og fysisk enhet
2. "Start dagens trening" fungerer ende-til-ende med begge spill
3. Streak-telling oppdateres korrekt etter fullført økt
4. Statistikk-skjerm viser minst snittscore-graf og per-spill-kort
5. iCloud-sync fungerer (testet med to enheter på samme Apple ID)
6. VoiceOver kan navigere alle hovedflyter
7. CI er grønn med unit + spill-tester
8. README, LICENSE, ADDING_A_GAME, CONTRIBUTING er publisert
9. Et tredjeparts-utvikler kan følge `ADDING_A_GAME.md` og legge til et nytt spill uten å endre core-kode

## Senere (post-MVP)

- Fri-spill-bibliotek
- Flere spill (ord-twist, mønster-fullføring, hoderegning)
- Hybrid daglig-økt + fri spill
- Engelsk lokalisering
- Apple Watch-companion
- Widget for streak og dagens trening
- iPad-tilpasning
- Mulig Swift Package-splitt hvis spill-katalogen vokser betraktelig
