# Designprinsipper

Disse prinsippene veileder beslutninger om kode og UI.

## 1. Plattformen er kontrakten, ikke implementasjonen

`Game`-protokollen er stabil. Spill kan komme og gå. Bryt aldri en publisert protokoll uten major versjonsbump.

## 2. Tilgjengelighet er ikke valgfritt

Brainfit-brukere inkluderer eldre, folk med synssvekkelse, og folk som spiller i fart. VoiceOver-labels, Dynamic Type og høy kontrast er bakt inn fra dag én — ikke retted opp etterpå.

## 3. Spill skal være korte

Mål: 30–90 sek per spill. En daglig økt = 2–3 spill = under 5 min totalt. Brukeren skal aldri trenge å sette av tid.

## 4. Normalisert scoring

Alle spill rapporterer score 0–1000. Det betyr at en N-back-score på 750 er sammenlignbar med en Stroop-score på 750 — begge plasserer brukeren samme sted i fremgangsgrafen.

## 5. Lokal data først, sky-sync på toppen

Appen fungerer komplett uten iCloud. Sync er en bonus. Ikke skriv kode som krever nettilkobling eller iCloud-konto.

## 6. Ingen mørke mønstre

- Ingen "kjøp mer streak"-mekanikker
- Ingen sosial pressmiddel for å holde streaks
- 36-timers vindu før brudd, slik at brukeren ikke straffes for tidssone-vandring
- Påminnelser er valgfrie og av som default

## 7. Tester der det betaler seg

- Scoring og engine-logikk: full dekning
- ViewModels: deterministisk via seedet RNG
- Views: sparsom snapshot-/UI-test for happy path
- Persistens: ikke tested ende-til-ende (Apple-ansvar)

## 8. Norsk først

UI på bokmål. Strenger via `String(localized:)` for å klargjøre lokalisering. Engelsk legges til når noen vil bidra med oversettelsen.
