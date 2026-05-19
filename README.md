# Brainfit

Åpen kildekode iOS-app for hjernetrim, inspirert av Lumosity og Elevate. Bygd på en utvidbar plattform-arkitektur som lar bidragsytere legge til nye spill ved å implementere én protokoll.

## Funksjoner

- To spill i MVP: **Husk Mønsteret** (N-back) og **Riktig Farge** (Stroop)
- Daglig økt-modell med streak-belønning
- iCloud-sync via CloudKit (privat database)
- VoiceOver, Dynamic Type, mørk modus
- Norsk (bokmål) i første versjon

## Krav

- iOS 17.0+ (iPhone XS eller nyere)
- Xcode 15.0+
- iCloud-konto for synkronisering (valgfritt — appen fungerer lokalt uten)

## Kom i gang

```bash
git clone https://github.com/frodesolem/brainfit-ios.git
cd brainfit-ios
brew install xcodegen
xcodegen generate
open Brainfit.xcodeproj
```

Velg en iOS-simulator og kjør (⌘R).

## Arkitektur

Se [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for en oversikt.

## Bidra

Vi tar gjerne imot nye spill, oversettelser og forbedringer. Les [CONTRIBUTING.md](CONTRIBUTING.md) og [docs/ADDING_A_GAME.md](docs/ADDING_A_GAME.md) før du sender en PR.

## Lisens

[MIT](LICENSE) — fri kommersiell og privat bruk.
