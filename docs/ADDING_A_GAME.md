# Legge til et nytt spill

Et nytt spill = én ny mappe under `Brainfit/Games/` + én registreringslinje i `AppEnvironment`. Ingen endring i core-kode.

## Steg-for-steg

### 1. Lag mappestruktur

```
Brainfit/Games/MittSpill/
├── MittSpillConfig.swift      # Vanskelighet → parametere
├── MittSpillScorer.swift      # Rene scoring-funksjoner
├── MittSpillViewModel.swift   # @Observable state
├── MittSpillPlayView.swift    # Spillets UI
└── MittSpillGame.swift        # Game-protokoll-konformans
```

### 2. Implementer `Game`-protokollen

```swift
public struct MittSpillGame: Game {
    public init() {}

    public static let metadata = GameMetadata(
        id: "mitt-spill",
        displayName: "Mitt Spill",
        category: .memory, // eller .reaction, .attention, ...
        shortDescription: "Hva spilleren skal gjøre",
        icon: "brain.head.profile", // SF Symbol
        targetDurationSeconds: 60
    )

    public func makeIntroView() -> some View {
        VStack { Text("Intro").font(.title) }
    }

    public func makePlayView(difficulty: Difficulty,
                             onComplete: @escaping @MainActor (GameResult) -> Void) -> some View {
        MittSpillPlayView(difficulty: difficulty, onComplete: onComplete)
    }
}
```

### 3. Rapporter resultat

Når spillet er ferdig, kall `onComplete` med en `GameResult`:

```swift
let result = GameResult(
    gameId: "mitt-spill",
    score: 750,                          // 0–1000, normalisert
    accuracy: 0.85,                      // 0–1
    durationSeconds: 60,
    difficulty: difficulty,
    rawMetrics: ["correct": 17, "incorrect": 3]
)
onComplete(result)
```

### 4. Registrer spillet

I `Brainfit/App/AppEnvironment.swift`:

```swift
self.registry.register(MittSpillGame())
```

### 5. Skriv tester

Spill-logikk skal være deterministisk via seedet RNG. Se [NBackViewModelTests](../BrainfitTests/Games/NBack/NBackViewModelTests.swift) for mønster.

### 6. Send PR

Følg [CONTRIBUTING.md](../CONTRIBUTING.md). I PR-beskrivelsen, legg ved:
- Skjermbilde fra simulator
- Kort forklaring av spillets mekanikk
- Hvilken kategori spillet hører hjemme i, og hvorfor

## Scoring-normalisering

Alle spill skal rapportere `score` mellom 0 og 1000. Bruk `ScoreCalculator.normalize(rawScore:)` for å klampe. Dette gir konsistent statistikk på tvers av spill.

## Tilgjengelighet (påkrevd)

- Alle interaktive elementer må ha `accessibilityLabel`
- Bruk `Dynamic Type` (`.font(.body)` i stedet for hardkodet `.system(size: 16)`)
- Test med VoiceOver i simulator (⌘+Option+F5)
