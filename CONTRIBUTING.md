# Bidra til Brainfit

Takk for at du vurderer å bidra. Brainfit er bygd for at det skal være lett å plugge inn nye spill.

## Hva vi tar imot

- **Nye spill** — implementer `Game`-protokollen og send PR. Se [docs/ADDING_A_GAME.md](docs/ADDING_A_GAME.md).
- **Bug-fikser** — åpne issue først hvis det er noe større enn en typo.
- **Oversettelser** — bokmål er primær. Engelsk er prioritert for v2.
- **Tilgjengelighet** — VoiceOver-labels, Dynamic Type-justeringer, kontrast.
- **Tester** — vi tar imot dekning der den mangler.

## Arbeidsflyt

1. Fork repoet og lag en branch: `git checkout -b feat/min-funksjon`
2. Kjør `xcodegen generate` for å generere Xcode-prosjektet
3. Skriv tester der det gir mening (spill-logikk: ja; views: sjelden)
4. Kjør `xcodebuild test` lokalt før PR
5. Følg commit-melding-format: `feat(scope): kort beskrivelse` eller `fix(scope): …`
6. Åpne PR mot `main`

## Kode-stil

- Swift 5.10, SwiftUI, SwiftData
- SwiftLint kjøres i CI — kjør `swiftlint --quiet` lokalt for å sjekke
- Spill skal være i `Brainfit/Games/<Navn>/` og registreres i `AppEnvironment`
- Ingen avhengigheter til ny tredjeparts-kode uten å åpne issue først

## Code of Conduct

Se [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md). Vi følger Contributor Covenant 2.1.
