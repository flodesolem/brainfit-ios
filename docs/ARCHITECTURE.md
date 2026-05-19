# Arkitektur

Brainfit er bygd rundt en `Game`-protokoll som lar nye spill plugges inn uten å endre core-koden.

## Lagdeling

```
App → RootView (TabView)
        ↓
       HomeView, StatsView, SettingsView, SessionFlowView
        ↓
       AppEnvironment (composition root)
        ↓
   ┌────────────────────────────────────────────────┐
   │ GameRegistry │ DailySessionEngine │ SessionState │
   └────────────────────────────────────────────────┘
        ↓                  ↓
   AnyGame instans  GameRunRepository, StreakRepository
        ↓                  ↓
   Game-protokoll    SwiftData @Model + CloudKit
```

## Sentrale typer

- `Game` (protokoll) — kontrakt alle spill følger
- `GameRegistry` — registrerer og slår opp spill
- `GameRun`, `DailySessionRecord`, `StreakState` — SwiftData-modeller
- `DailySessionEngine` — eier streak-logikk og vanskelighetsanbefaling
- `SessionState` — `@Observable` UI-state for en pågående økt

## Hvor ting bor

| Mappe | Ansvar |
|-------|--------|
| `Brainfit/Core` | Spill-kontrakten, kjernetyper |
| `Brainfit/Engine` | Domeneregler (scoring, økt-flyt) |
| `Brainfit/Persistence` | SwiftData-modeller + repositories + CloudKit |
| `Brainfit/Games/<Navn>` | Selvstendige spill |
| `Brainfit/Features` | UI-skjermer (Home, Stats, Settings, Session) |
| `Brainfit/DesignSystem` | Theme-tokens |
| `Brainfit/App` | App-entry, RootView, AppEnvironment |

## Avhengighetsregler

- `Games/*` avhenger av `Core` (Game-protokoll) — ikke av `Engine` eller `Features`
- `Engine` avhenger av `Core` og `Persistence` (via protokoller)
- `Features` avhenger av `Engine`, `Core`, `Persistence`, `DesignSystem`
- `App` komponerer alt sammen via `AppEnvironment`

## Hvorfor protocol-basert plattform?

Vi skiller spill-kontrakten fra implementasjonene. Resultatet:
- Nye spill kan legges til ved å implementere én protokoll
- Core-koden trenger ikke kjenne til konkrete spill
- Tester kan stubbe spill via egne `Game`-konformanter

## Hvorfor ikke Swift Packages per spill?

Vurdert og avvist for MVP. Pakke-splitt gir reell modularitet, men kreves ikke før vi har 10+ spill og ekte ekstern utvikling. Det er en refaktor for senere.
