# Brainfit MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bygg en åpen kildekode iOS-app for hjernetrim med plattform-arkitektur, to spill (N-back + Stroop), daglig økt med streak, iCloud-sync via CloudKit, og full åpen kildekode-pakke (lisens, docs, CI).

**Architecture:** SwiftUI + SwiftData + CloudKit på iOS 17+. Plattform-først design: `Game`-protokoll + `GameRegistry` lar nye spill plugges inn ved å implementere kontrakten. Ingen backend-server.

**Tech Stack:** Swift 5.10, SwiftUI, SwiftData, CloudKit, Swift Charts, XCTest, XCUITest, xcodegen (prosjekt-generering), SwiftLint, GitHub Actions.

**Repo:** `~/dev/brainfit-ios/` (allerede initialisert med spec)

**Spec:** `docs/superpowers/specs/2026-05-18-brainfit-design.md`

---

## Kjøremønster

- **Wave 0 (sekvensiell, 1 agent):** Repo-bootstrap. Tasks 1–4.
- **Wave 1 (sekvensiell, 1 agent):** Core platform. Tasks 5–18. Alt etterfølgende avhenger av at denne committen er stabil.
- **Wave 2 (4 parallelle agenter):**
  - Agent A — N-back: Tasks 19–23
  - Agent B — Stroop: Tasks 24–28
  - Agent C — UI-skall: Tasks 29–35
  - Agent D — OSS + CI: Tasks 36–47

Hver agent jobber på egen branch (eller atomic commits på master). Wave 2-agenter kan starte når Wave 1 er committet.

---

# Wave 0 — Repo-bootstrapping

### Task 1: Initialiser .gitignore og lisens

**Files:**
- Create: `.gitignore`
- Create: `LICENSE`

- [ ] **Step 1: Skriv .gitignore**

Innhold:
```
# Xcode
build/
DerivedData/
*.pbxuser
!default.pbxuser
*.mode1v3
!default.mode1v3
*.mode2v3
!default.mode2v3
*.perspectivev3
!default.perspectivev3
xcuserdata/
*.moved-aside
*.xccheckout
*.xcscmblueprint
*.xcuserstate

# Swift Package Manager
.swiftpm/
Packages/
Package.resolved
*.xcodeproj/xcuserdata/

# CocoaPods (not used, but defensive)
Pods/

# macOS
.DS_Store

# IDE
.vscode/
.idea/

# xcodegen artifact (we commit project.yml, regenerate .xcodeproj)
*.xcodeproj
```

- [ ] **Step 2: Skriv LICENSE (MIT)**

```
MIT License

Copyright (c) 2026 Frode Solem and Brainfit contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

- [ ] **Step 3: Commit**

```bash
cd ~/dev/brainfit-ios
git add .gitignore LICENSE
git commit -m "chore: add .gitignore and MIT license"
```

---

### Task 2: Installer xcodegen og skriv project.yml

**Files:**
- Create: `project.yml`

- [ ] **Step 1: Installer xcodegen**

```bash
which xcodegen || brew install xcodegen
xcodegen --version
```

Expected: versjon ≥ 2.40.0

- [ ] **Step 2: Skriv project.yml**

```yaml
name: Brainfit
options:
  bundleIdPrefix: com.frodesolem
  deploymentTarget:
    iOS: "17.0"
  developmentLanguage: nb
  createIntermediateGroups: true
  generateEmptyDirectories: true

settings:
  base:
    SWIFT_VERSION: "5.10"
    MARKETING_VERSION: "0.1.0"
    CURRENT_PROJECT_VERSION: "1"
    ENABLE_USER_SCRIPT_SANDBOXING: "YES"
    SWIFT_STRICT_CONCURRENCY: complete

targets:
  Brainfit:
    type: application
    platform: iOS
    deploymentTarget: "17.0"
    sources:
      - path: Brainfit
        excludes:
          - "**/*.md"
    info:
      path: Brainfit/Info.plist
      properties:
        UILaunchScreen:
          UIColorName: AccentColor
        UISupportedInterfaceOrientations:
          - UIInterfaceOrientationPortrait
        CFBundleDisplayName: Brainfit
        NSUserNotificationUsageDescription: Brainfit sender deg en daglig påminnelse om dagens trening.
    entitlements:
      path: Brainfit/Brainfit.entitlements
      properties:
        com.apple.developer.icloud-container-identifiers:
          - iCloud.com.frodesolem.brainfit
        com.apple.developer.icloud-services:
          - CloudKit
        com.apple.developer.ubiquity-kvstore-identifier: $(TeamIdentifierPrefix)com.frodesolem.brainfit
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.frodesolem.brainfit
        GENERATE_INFOPLIST_FILE: "NO"
        ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon
        ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME: AccentColor

  BrainfitTests:
    type: bundle.unit-test
    platform: iOS
    sources:
      - BrainfitTests
    dependencies:
      - target: Brainfit
    settings:
      base:
        TEST_HOST: $(BUILT_PRODUCTS_DIR)/Brainfit.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/Brainfit
        BUNDLE_LOADER: $(TEST_HOST)
        GENERATE_INFOPLIST_FILE: "YES"

  BrainfitUITests:
    type: bundle.ui-testing
    platform: iOS
    sources:
      - BrainfitUITests
    dependencies:
      - target: Brainfit
    settings:
      base:
        TEST_TARGET_NAME: Brainfit
        GENERATE_INFOPLIST_FILE: "YES"

schemes:
  Brainfit:
    build:
      targets:
        Brainfit: all
        BrainfitTests: [test]
        BrainfitUITests: [test]
    test:
      targets:
        - BrainfitTests
        - BrainfitUITests
      gatherCoverageData: true
```

- [ ] **Step 3: Commit**

```bash
git add project.yml
git commit -m "chore: add xcodegen project configuration"
```

---

### Task 3: Generer Xcode-prosjekt og verifiser bygg

**Files:**
- Create: `Brainfit/App/BrainfitApp.swift` (placeholder)
- Create: `Brainfit/Info.plist`
- Create: `Brainfit/Brainfit.entitlements`
- Create: `Brainfit/Assets.xcassets/AppIcon.appiconset/Contents.json`
- Create: `Brainfit/Assets.xcassets/AccentColor.colorset/Contents.json`
- Create: `Brainfit/Assets.xcassets/Contents.json`
- Create: `BrainfitTests/BrainfitTests.swift` (smoke)
- Create: `BrainfitUITests/BrainfitUITests.swift` (smoke)

- [ ] **Step 1: Lag mappestruktur og placeholder-app**

```bash
mkdir -p Brainfit/App Brainfit/Assets.xcassets/AppIcon.appiconset Brainfit/Assets.xcassets/AccentColor.colorset BrainfitTests BrainfitUITests
```

- [ ] **Step 2: Skriv placeholder App-fil — `Brainfit/App/BrainfitApp.swift`**

```swift
import SwiftUI

@main
struct BrainfitApp: App {
    var body: some Scene {
        WindowGroup {
            Text("Brainfit")
                .font(.largeTitle)
        }
    }
}
```

- [ ] **Step 3: Skriv `Brainfit/Info.plist`**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>nb</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>$(PRODUCT_BUNDLE_PACKAGE_TYPE)</string>
    <key>CFBundleShortVersionString</key>
    <string>$(MARKETING_VERSION)</string>
    <key>CFBundleVersion</key>
    <string>$(CURRENT_PROJECT_VERSION)</string>
    <key>LSRequiresIPhoneOS</key>
    <true/>
</dict>
</plist>
```

- [ ] **Step 4: Skriv `Brainfit/Brainfit.entitlements`**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.developer.icloud-container-identifiers</key>
    <array>
        <string>iCloud.com.frodesolem.brainfit</string>
    </array>
    <key>com.apple.developer.icloud-services</key>
    <array>
        <string>CloudKit</string>
    </array>
</dict>
</plist>
```

- [ ] **Step 5: Skriv asset-catalog JSON-filer**

`Brainfit/Assets.xcassets/Contents.json`:
```json
{ "info" : { "author" : "xcode", "version" : 1 } }
```

`Brainfit/Assets.xcassets/AppIcon.appiconset/Contents.json`:
```json
{
  "images" : [
    { "idiom" : "universal", "platform" : "ios", "size" : "1024x1024" }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
```

`Brainfit/Assets.xcassets/AccentColor.colorset/Contents.json`:
```json
{
  "colors" : [
    {
      "color" : {
        "color-space" : "srgb",
        "components" : { "alpha" : "1.000", "blue" : "0.831", "green" : "0.502", "red" : "0.094" }
      },
      "idiom" : "universal"
    }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
```

- [ ] **Step 6: Skriv smoke-tester**

`BrainfitTests/BrainfitTests.swift`:
```swift
import XCTest
@testable import Brainfit

final class BrainfitSmokeTests: XCTestCase {
    func testTrueIsTrue() {
        XCTAssertTrue(true)
    }
}
```

`BrainfitUITests/BrainfitUITests.swift`:
```swift
import XCTest

final class BrainfitUISmokeTests: XCTestCase {
    func testAppLaunches() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.staticTexts["Brainfit"].waitForExistence(timeout: 5))
    }
}
```

- [ ] **Step 7: Generer Xcode-prosjekt**

```bash
xcodegen generate
ls -d Brainfit.xcodeproj
```

Expected: `Brainfit.xcodeproj` finnes.

- [ ] **Step 8: Verifiser bygg**

```bash
xcodebuild -project Brainfit.xcodeproj \
  -scheme Brainfit \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
  -quiet build 2>&1 | tail -20
```

Expected: `** BUILD SUCCEEDED **`

Hvis build feiler på CloudKit-entitlements på simulator (manglende team-signering): legg til `CODE_SIGN_IDENTITY=""`, `CODE_SIGNING_REQUIRED=NO`, `CODE_SIGNING_ALLOWED=NO` til xcodebuild-kommandoen.

- [ ] **Step 9: Kjør smoke-tester**

```bash
xcodebuild -project Brainfit.xcodeproj \
  -scheme Brainfit \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
  -quiet test 2>&1 | tail -20
```

Expected: alle tester passerer.

- [ ] **Step 10: Commit**

```bash
git add Brainfit BrainfitTests BrainfitUITests
git commit -m "chore: scaffold Xcode project with placeholder app and smoke tests"
```

Merk: `.xcodeproj` er i .gitignore — den genereres av xcodegen ved behov.

---

### Task 4: SwiftLint-konfig

**Files:**
- Create: `.swiftlint.yml`

- [ ] **Step 1: Skriv `.swiftlint.yml`**

```yaml
included:
  - Brainfit
  - BrainfitTests
  - BrainfitUITests

excluded:
  - Brainfit/Assets.xcassets

disabled_rules:
  - trailing_whitespace
  - todo

opt_in_rules:
  - empty_count
  - empty_string
  - explicit_init
  - first_where
  - last_where
  - unused_import
  - vertical_whitespace_closing_braces
  - closure_spacing

line_length:
  warning: 140
  error: 200
  ignores_comments: true

type_name:
  min_length: 2
  max_length: 60

identifier_name:
  min_length: 1
  excluded:
    - id
    - n
    - x
    - y
```

- [ ] **Step 2: Verifiser at SwiftLint kjører lokalt (valgfritt — installert eller ikke)**

```bash
which swiftlint && swiftlint --config .swiftlint.yml --quiet 2>&1 | tail -5 || echo "SwiftLint ikke installert — CI vil håndtere det"
```

- [ ] **Step 3: Commit**

```bash
git add .swiftlint.yml
git commit -m "chore: add SwiftLint configuration"
```

---

# Wave 1 — Core platform

Sekvensiell. Alt etterfølgende avhenger av at denne committen er stabil og bygger.

### Task 5: Definer Difficulty, GameCategory, GameMetadata

**Files:**
- Create: `Brainfit/Core/GameTypes.swift`

- [ ] **Step 1: Skriv testfil først — `BrainfitTests/Core/GameTypesTests.swift`**

```swift
import XCTest
@testable import Brainfit

final class GameTypesTests: XCTestCase {
    func testDifficultyRawValues() {
        XCTAssertEqual(Difficulty.easy.rawValue, 1)
        XCTAssertEqual(Difficulty.medium.rawValue, 2)
        XCTAssertEqual(Difficulty.hard.rawValue, 3)
    }

    func testDifficultyRoundTripsThroughCodable() throws {
        let data = try JSONEncoder().encode(Difficulty.hard)
        let decoded = try JSONDecoder().decode(Difficulty.self, from: data)
        XCTAssertEqual(decoded, .hard)
    }

    func testGameCategoryHasAllExpectedCases() {
        let all: Set<GameCategory> = [.memory, .reaction, .attention, .language, .math, .problemSolving]
        XCTAssertEqual(all.count, 6)
    }
}
```

- [ ] **Step 2: Kjør testen — forventes å feile (typer eksisterer ikke)**

```bash
xcodebuild -project Brainfit.xcodeproj -scheme Brainfit \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
  -quiet test -only-testing:BrainfitTests/GameTypesTests 2>&1 | tail -10
```

Expected: kompileringsfeil på `Difficulty`, `GameCategory`.

- [ ] **Step 3: Skriv implementasjon — `Brainfit/Core/GameTypes.swift`**

```swift
import Foundation

public enum Difficulty: Int, Codable, CaseIterable, Sendable {
    case easy = 1
    case medium = 2
    case hard = 3

    public func bumped(by delta: Int) -> Difficulty {
        let raw = max(Difficulty.easy.rawValue, min(Difficulty.hard.rawValue, rawValue + delta))
        return Difficulty(rawValue: raw) ?? self
    }
}

public enum GameCategory: String, Codable, CaseIterable, Sendable {
    case memory
    case reaction
    case attention
    case language
    case math
    case problemSolving
}

public struct GameMetadata: Sendable, Hashable {
    public let id: String
    public let displayName: String
    public let category: GameCategory
    public let shortDescription: String
    public let icon: String
    public let targetDurationSeconds: Int

    public init(id: String,
                displayName: String,
                category: GameCategory,
                shortDescription: String,
                icon: String,
                targetDurationSeconds: Int) {
        self.id = id
        self.displayName = displayName
        self.category = category
        self.shortDescription = shortDescription
        self.icon = icon
        self.targetDurationSeconds = targetDurationSeconds
    }
}
```

- [ ] **Step 4: Regenerer prosjekt og kjør tester**

```bash
xcodegen generate
xcodebuild -project Brainfit.xcodeproj -scheme Brainfit \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
  -quiet test -only-testing:BrainfitTests/GameTypesTests 2>&1 | tail -10
```

Expected: alle 3 tester passerer.

- [ ] **Step 5: Commit**

```bash
git add Brainfit/Core/GameTypes.swift BrainfitTests/Core/GameTypesTests.swift
git commit -m "feat(core): add Difficulty, GameCategory, GameMetadata types"
```

---

### Task 6: GameResult med rawMetrics-enkoding

**Files:**
- Create: `Brainfit/Core/GameResult.swift`
- Create: `BrainfitTests/Core/GameResultTests.swift`

- [ ] **Step 1: Skriv testene først**

```swift
import XCTest
@testable import Brainfit

final class GameResultTests: XCTestCase {
    func testEncodesAndDecodesRawMetrics() throws {
        let result = GameResult(
            gameId: "nback",
            score: 750,
            accuracy: 0.85,
            durationSeconds: 52.3,
            difficulty: .medium,
            rawMetrics: ["hits": 14, "misses": 3, "avgReactionMs": 620.5]
        )
        let json = try result.rawMetricsJSON()
        let decoded = try GameResult.decodeRawMetrics(from: json)
        XCTAssertEqual(decoded["hits"], 14)
        XCTAssertEqual(decoded["misses"], 3)
        XCTAssertEqual(decoded["avgReactionMs"], 620.5)
    }

    func testDecodingEmptyJSONReturnsEmptyDictionary() throws {
        XCTAssertEqual(try GameResult.decodeRawMetrics(from: "{}"), [:])
    }

    func testDecodingMalformedJSONThrows() {
        XCTAssertThrowsError(try GameResult.decodeRawMetrics(from: "not-json"))
    }
}
```

- [ ] **Step 2: Skriv implementasjonen — `Brainfit/Core/GameResult.swift`**

```swift
import Foundation

public struct GameResult: Sendable, Equatable {
    public let gameId: String
    public let score: Int
    public let accuracy: Double
    public let durationSeconds: Double
    public let difficulty: Difficulty
    public let rawMetrics: [String: Double]

    public init(gameId: String,
                score: Int,
                accuracy: Double,
                durationSeconds: Double,
                difficulty: Difficulty,
                rawMetrics: [String: Double]) {
        self.gameId = gameId
        self.score = score
        self.accuracy = accuracy
        self.durationSeconds = durationSeconds
        self.difficulty = difficulty
        self.rawMetrics = rawMetrics
    }

    public func rawMetricsJSON() throws -> String {
        let data = try JSONSerialization.data(withJSONObject: rawMetrics, options: [.sortedKeys])
        return String(data: data, encoding: .utf8) ?? "{}"
    }

    public static func decodeRawMetrics(from json: String) throws -> [String: Double] {
        guard let data = json.data(using: .utf8) else { return [:] }
        let object = try JSONSerialization.jsonObject(with: data)
        guard let dict = object as? [String: Any] else {
            throw NSError(domain: "GameResult", code: 1, userInfo: [NSLocalizedDescriptionKey: "rawMetrics JSON must be an object"])
        }
        return dict.compactMapValues { value in
            if let double = value as? Double { return double }
            if let int = value as? Int { return Double(int) }
            return nil
        }
    }
}
```

- [ ] **Step 3: Regenerer og kjør tester**

```bash
xcodegen generate
xcodebuild -project Brainfit.xcodeproj -scheme Brainfit \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
  -quiet test -only-testing:BrainfitTests/GameResultTests 2>&1 | tail -10
```

Expected: alle 3 tester passerer.

- [ ] **Step 4: Commit**

```bash
git add Brainfit/Core/GameResult.swift BrainfitTests/Core/GameResultTests.swift
git commit -m "feat(core): add GameResult with rawMetrics JSON encoding"
```

---

### Task 7: Game-protokollen

**Files:**
- Create: `Brainfit/Core/Game.swift`

- [ ] **Step 1: Skriv `Brainfit/Core/Game.swift`**

```swift
import SwiftUI

public protocol Game {
    associatedtype IntroView: View
    associatedtype PlayView: View

    static var metadata: GameMetadata { get }

    @MainActor
    func makeIntroView() -> IntroView

    @MainActor
    func makePlayView(difficulty: Difficulty,
                      onComplete: @escaping @MainActor (GameResult) -> Void) -> PlayView
}

public extension Game {
    static var id: String { metadata.id }
}
```

- [ ] **Step 2: Skriv type-eraser for å lagre forskjellige Game-typer i Registry — append til samme fil**

```swift
public struct AnyGame: Sendable {
    public let metadata: GameMetadata
    private let _makeIntroView: @MainActor () -> AnyView
    private let _makePlayView: @MainActor (Difficulty, @escaping @MainActor (GameResult) -> Void) -> AnyView

    public init<G: Game>(_ game: G) {
        self.metadata = G.metadata
        let captured = game
        self._makeIntroView = { @MainActor in AnyView(captured.makeIntroView()) }
        self._makePlayView = { @MainActor difficulty, onComplete in
            AnyView(captured.makePlayView(difficulty: difficulty, onComplete: onComplete))
        }
    }

    @MainActor
    public func makeIntroView() -> AnyView { _makeIntroView() }

    @MainActor
    public func makePlayView(difficulty: Difficulty,
                             onComplete: @escaping @MainActor (GameResult) -> Void) -> AnyView {
        _makePlayView(difficulty, onComplete)
    }
}
```

- [ ] **Step 3: Regenerer og verifiser bygg**

```bash
xcodegen generate
xcodebuild -project Brainfit.xcodeproj -scheme Brainfit \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
  -quiet build 2>&1 | tail -10
```

Expected: BUILD SUCCEEDED.

- [ ] **Step 4: Commit**

```bash
git add Brainfit/Core/Game.swift
git commit -m "feat(core): add Game protocol and AnyGame type eraser"
```

---

### Task 8: GameRegistry

**Files:**
- Create: `Brainfit/Core/GameRegistry.swift`
- Create: `BrainfitTests/Core/GameRegistryTests.swift`

- [ ] **Step 1: Skriv testene først**

```swift
import XCTest
import SwiftUI
@testable import Brainfit

private struct DummyGame: Game {
    static let metadata = GameMetadata(
        id: "dummy",
        displayName: "Dummy",
        category: .memory,
        shortDescription: "test",
        icon: "circle",
        targetDurationSeconds: 30
    )
    func makeIntroView() -> some View { Text("intro") }
    func makePlayView(difficulty: Difficulty, onComplete: @escaping (GameResult) -> Void) -> some View {
        Text("play")
    }
}

final class GameRegistryTests: XCTestCase {
    func testRegisteredGameCanBeRetrievedById() {
        let registry = GameRegistry()
        registry.register(DummyGame())
        XCTAssertEqual(registry.game(forId: "dummy")?.metadata.id, "dummy")
    }

    func testRegistryIsEmptyByDefault() {
        XCTAssertEqual(GameRegistry().allGames.count, 0)
    }

    func testRegisteringSameIdTwiceReplaces() {
        let registry = GameRegistry()
        registry.register(DummyGame())
        registry.register(DummyGame())
        XCTAssertEqual(registry.allGames.count, 1)
    }

    func testGamesByCategoryFiltersCorrectly() {
        let registry = GameRegistry()
        registry.register(DummyGame())
        XCTAssertEqual(registry.games(in: .memory).count, 1)
        XCTAssertEqual(registry.games(in: .reaction).count, 0)
    }
}
```

- [ ] **Step 2: Skriv implementasjonen**

```swift
import Foundation

@MainActor
public final class GameRegistry {
    private var games: [String: AnyGame] = [:]

    public init() {}

    public func register<G: Game>(_ game: G) {
        games[G.metadata.id] = AnyGame(game)
    }

    public func game(forId id: String) -> AnyGame? {
        games[id]
    }

    public var allGames: [AnyGame] {
        Array(games.values).sorted { $0.metadata.displayName < $1.metadata.displayName }
    }

    public func games(in category: GameCategory) -> [AnyGame] {
        allGames.filter { $0.metadata.category == category }
    }
}
```

- [ ] **Step 3: Regenerer og kjør tester**

```bash
xcodegen generate
xcodebuild -project Brainfit.xcodeproj -scheme Brainfit \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
  -quiet test -only-testing:BrainfitTests/GameRegistryTests 2>&1 | tail -10
```

Expected: alle 4 tester passerer.

- [ ] **Step 4: Commit**

```bash
git add Brainfit/Core/GameRegistry.swift BrainfitTests/Core/GameRegistryTests.swift
git commit -m "feat(core): add GameRegistry"
```

---

### Task 9: SwiftData-modell — GameRun

**Files:**
- Create: `Brainfit/Persistence/Models/GameRun.swift`

- [ ] **Step 1: Skriv modellen**

```swift
import Foundation
import SwiftData

@Model
public final class GameRun {
    public var id: UUID = UUID()
    public var gameId: String = ""
    public var playedAt: Date = Date()
    public var score: Int = 0
    public var accuracy: Double = 0
    public var durationSeconds: Double = 0
    public var difficulty: Int = 2
    public var rawMetricsJSON: String = "{}"
    public var sessionId: UUID?

    public init(gameId: String,
                score: Int,
                accuracy: Double,
                durationSeconds: Double,
                difficulty: Difficulty,
                rawMetricsJSON: String,
                sessionId: UUID? = nil,
                playedAt: Date = Date()) {
        self.id = UUID()
        self.gameId = gameId
        self.score = score
        self.accuracy = accuracy
        self.durationSeconds = durationSeconds
        self.difficulty = difficulty.rawValue
        self.rawMetricsJSON = rawMetricsJSON
        self.sessionId = sessionId
        self.playedAt = playedAt
    }

    public var difficultyEnum: Difficulty {
        Difficulty(rawValue: difficulty) ?? .medium
    }
}

public extension GameRun {
    convenience init(from result: GameResult, sessionId: UUID? = nil, playedAt: Date = Date()) throws {
        self.init(
            gameId: result.gameId,
            score: result.score,
            accuracy: result.accuracy,
            durationSeconds: result.durationSeconds,
            difficulty: result.difficulty,
            rawMetricsJSON: try result.rawMetricsJSON(),
            sessionId: sessionId,
            playedAt: playedAt
        )
    }
}
```

- [ ] **Step 2: Regenerer og verifiser bygg**

```bash
xcodegen generate
xcodebuild -project Brainfit.xcodeproj -scheme Brainfit \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
  -quiet build 2>&1 | tail -10
```

Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Commit**

```bash
git add Brainfit/Persistence/Models/GameRun.swift
git commit -m "feat(persistence): add GameRun SwiftData model"
```

---

### Task 10: SwiftData-modell — DailySessionRecord

**Files:**
- Create: `Brainfit/Persistence/Models/DailySessionRecord.swift`

- [ ] **Step 1: Skriv modellen**

```swift
import Foundation
import SwiftData

@Model
public final class DailySessionRecord {
    public var id: UUID = UUID()
    public var date: Date = Date()
    public var completedAt: Date?
    public var gameRunIds: [UUID] = []
    public var totalScore: Int = 0

    public init(date: Date,
                completedAt: Date? = nil,
                gameRunIds: [UUID] = [],
                totalScore: Int = 0) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.completedAt = completedAt
        self.gameRunIds = gameRunIds
        self.totalScore = totalScore
    }
}
```

- [ ] **Step 2: Regenerer og verifiser bygg**

```bash
xcodegen generate
xcodebuild -project Brainfit.xcodeproj -scheme Brainfit \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
  -quiet build 2>&1 | tail -10
```

Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Commit**

```bash
git add Brainfit/Persistence/Models/DailySessionRecord.swift
git commit -m "feat(persistence): add DailySessionRecord SwiftData model"
```

---

### Task 11: SwiftData-modell — StreakState

**Files:**
- Create: `Brainfit/Persistence/Models/StreakState.swift`

- [ ] **Step 1: Skriv modellen**

```swift
import Foundation
import SwiftData

@Model
public final class StreakState {
    public var id: UUID = UUID()
    public var currentStreak: Int = 0
    public var longestStreak: Int = 0
    public var lastSessionDate: Date?

    public init(currentStreak: Int = 0,
                longestStreak: Int = 0,
                lastSessionDate: Date? = nil) {
        self.id = UUID()
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.lastSessionDate = lastSessionDate
    }
}
```

- [ ] **Step 2: Regenerer og verifiser bygg, deretter commit**

```bash
xcodegen generate
xcodebuild -project Brainfit.xcodeproj -scheme Brainfit \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
  -quiet build 2>&1 | tail -10
git add Brainfit/Persistence/Models/StreakState.swift
git commit -m "feat(persistence): add StreakState SwiftData model"
```

---

### Task 12: ModelContainer + CloudKit-konfig

**Files:**
- Create: `Brainfit/Persistence/ModelContainer.swift`

- [ ] **Step 1: Skriv container-fabrikken**

```swift
import Foundation
import SwiftData

public enum BrainfitModelContainer {
    public static let allModels: [any PersistentModel.Type] = [
        GameRun.self,
        DailySessionRecord.self,
        StreakState.self
    ]

    public static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema(allModels)
        let config: ModelConfiguration
        if inMemory {
            config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        } else {
            config = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .private("iCloud.com.frodesolem.brainfit")
            )
        }
        return try ModelContainer(for: schema, configurations: [config])
    }
}
```

- [ ] **Step 2: Regenerer og verifiser bygg**

```bash
xcodegen generate
xcodebuild -project Brainfit.xcodeproj -scheme Brainfit \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
  -quiet build 2>&1 | tail -10
```

Expected: BUILD SUCCEEDED. Hvis CloudKit-feil: kjør med `CODE_SIGNING_ALLOWED=NO`.

- [ ] **Step 3: Commit**

```bash
git add Brainfit/Persistence/ModelContainer.swift
git commit -m "feat(persistence): add ModelContainer with CloudKit private database"
```

---

### Task 13: GameRunRepository

**Files:**
- Create: `Brainfit/Persistence/Repositories/GameRunRepository.swift`

- [ ] **Step 1: Skriv protokoll og SwiftData-implementasjon**

```swift
import Foundation
import SwiftData

public protocol GameRunRepository: AnyObject, Sendable {
    func save(_ run: GameRun) throws
    func recent(forGameId gameId: String, limit: Int) throws -> [GameRun]
    func all(since date: Date) throws -> [GameRun]
}

@MainActor
public final class SwiftDataGameRunRepository: GameRunRepository {
    private let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    public func save(_ run: GameRun) throws {
        context.insert(run)
        try context.save()
    }

    public func recent(forGameId gameId: String, limit: Int) throws -> [GameRun] {
        var descriptor = FetchDescriptor<GameRun>(
            predicate: #Predicate { $0.gameId == gameId },
            sortBy: [SortDescriptor(\.playedAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return try context.fetch(descriptor)
    }

    public func all(since date: Date) throws -> [GameRun] {
        let descriptor = FetchDescriptor<GameRun>(
            predicate: #Predicate { $0.playedAt >= date },
            sortBy: [SortDescriptor(\.playedAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }
}
```

- [ ] **Step 2: Regenerer og verifiser bygg**

```bash
xcodegen generate
xcodebuild -project Brainfit.xcodeproj -scheme Brainfit \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
  -quiet build 2>&1 | tail -10
```

Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Commit**

```bash
git add Brainfit/Persistence/Repositories/GameRunRepository.swift
git commit -m "feat(persistence): add GameRunRepository"
```

---

### Task 14: StreakRepository

**Files:**
- Create: `Brainfit/Persistence/Repositories/StreakRepository.swift`

- [ ] **Step 1: Skriv protokoll og implementasjon**

```swift
import Foundation
import SwiftData

public protocol StreakRepository: AnyObject, Sendable {
    func load() throws -> StreakState
    func save(_ state: StreakState) throws
}

@MainActor
public final class SwiftDataStreakRepository: StreakRepository {
    private let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    public func load() throws -> StreakState {
        let descriptor = FetchDescriptor<StreakState>()
        if let existing = try context.fetch(descriptor).first {
            return existing
        }
        let fresh = StreakState()
        context.insert(fresh)
        try context.save()
        return fresh
    }

    public func save(_ state: StreakState) throws {
        try context.save()
    }
}
```

- [ ] **Step 2: Regenerer og verifiser bygg**

```bash
xcodegen generate
xcodebuild -project Brainfit.xcodeproj -scheme Brainfit \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
  -quiet build 2>&1 | tail -10
```

Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Commit**

```bash
git add Brainfit/Persistence/Repositories/StreakRepository.swift
git commit -m "feat(persistence): add StreakRepository singleton-row pattern"
```

---

### Task 15: ScoreCalculator (normaliserings-hjelpere)

**Files:**
- Create: `Brainfit/Engine/ScoreCalculator.swift`
- Create: `BrainfitTests/Engine/ScoreCalculatorTests.swift`

- [ ] **Step 1: Skriv tester først**

```swift
import XCTest
@testable import Brainfit

final class ScoreCalculatorTests: XCTestCase {
    func testNormalizeClampsAbove1000() {
        XCTAssertEqual(ScoreCalculator.normalize(rawScore: 1500), 1000)
    }

    func testNormalizeClampsBelow0() {
        XCTAssertEqual(ScoreCalculator.normalize(rawScore: -10), 0)
    }

    func testAverageReturnsZeroForEmpty() {
        XCTAssertEqual(ScoreCalculator.averageScore(runs: []), 0)
    }

    func testAverageRoundsDown() {
        XCTAssertEqual(ScoreCalculator.averageScore(runs: [100, 200, 301]), 200)
    }
}
```

- [ ] **Step 2: Skriv implementasjonen**

```swift
import Foundation

public enum ScoreCalculator {
    public static func normalize(rawScore: Int) -> Int {
        max(0, min(1000, rawScore))
    }

    public static func averageScore(runs: [Int]) -> Int {
        guard !runs.isEmpty else { return 0 }
        return runs.reduce(0, +) / runs.count
    }

    public static func recommendDifficulty(currentLevel: Difficulty, recentScores: [Int]) -> Difficulty {
        guard !recentScores.isEmpty else { return currentLevel }
        let avg = averageScore(runs: recentScores)
        if avg > 700 { return currentLevel.bumped(by: 1) }
        if avg < 400 { return currentLevel.bumped(by: -1) }
        return currentLevel
    }
}
```

- [ ] **Step 3: Regenerer og kjør tester**

```bash
xcodegen generate
xcodebuild -project Brainfit.xcodeproj -scheme Brainfit \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
  -quiet test -only-testing:BrainfitTests/ScoreCalculatorTests 2>&1 | tail -10
```

Expected: alle 4 tester passerer.

- [ ] **Step 4: Commit**

```bash
git add Brainfit/Engine/ScoreCalculator.swift BrainfitTests/Engine/ScoreCalculatorTests.swift
git commit -m "feat(engine): add ScoreCalculator normalization and difficulty recommendation"
```

---

### Task 16: DailySessionEngine

**Files:**
- Create: `Brainfit/Engine/DailySessionEngine.swift`
- Create: `BrainfitTests/Engine/DailySessionEngineTests.swift`

- [ ] **Step 1: Skriv tester først (in-memory fakes)**

```swift
import XCTest
@testable import Brainfit

@MainActor
final class DailySessionEngineTests: XCTestCase {
    private final class FakeRunRepo: GameRunRepository {
        var stored: [GameRun] = []
        func save(_ run: GameRun) throws { stored.append(run) }
        func recent(forGameId gameId: String, limit: Int) throws -> [GameRun] {
            stored.filter { $0.gameId == gameId }.prefix(limit).map { $0 }
        }
        func all(since date: Date) throws -> [GameRun] {
            stored.filter { $0.playedAt >= date }
        }
    }

    private final class FakeStreakRepo: StreakRepository {
        var state = StreakState()
        func load() throws -> StreakState { state }
        func save(_ state: StreakState) throws { self.state = state }
    }

    func testFirstEverSessionStartsStreakAtOne() throws {
        let engine = DailySessionEngine(
            runs: FakeRunRepo(),
            streaks: FakeStreakRepo(),
            calendar: .current,
            now: { Date() }
        )
        try engine.recordCompletion(score: 500)
        XCTAssertEqual(engine.currentStreak(), 1)
    }

    func testTwoSessionsSameDayDoesNotIncrementStreak() throws {
        let engine = DailySessionEngine(
            runs: FakeRunRepo(),
            streaks: FakeStreakRepo(),
            calendar: .current,
            now: { Date() }
        )
        try engine.recordCompletion(score: 500)
        try engine.recordCompletion(score: 600)
        XCTAssertEqual(engine.currentStreak(), 1)
    }

    func testDidCompleteSessionTodayReflectsState() throws {
        let engine = DailySessionEngine(
            runs: FakeRunRepo(),
            streaks: FakeStreakRepo(),
            calendar: .current,
            now: { Date() }
        )
        XCTAssertFalse(engine.didCompleteSessionToday())
        try engine.recordCompletion(score: 500)
        XCTAssertTrue(engine.didCompleteSessionToday())
    }

    func testSessionOnConsecutiveDaysIncrementsStreak() throws {
        var fakeNow = Date(timeIntervalSince1970: 1_700_000_000)
        let engine = DailySessionEngine(
            runs: FakeRunRepo(),
            streaks: FakeStreakRepo(),
            calendar: .current,
            now: { fakeNow }
        )
        try engine.recordCompletion(score: 500)
        fakeNow = fakeNow.addingTimeInterval(86_400)
        try engine.recordCompletion(score: 600)
        XCTAssertEqual(engine.currentStreak(), 2)
    }

    func testSessionAfter36HoursBreaksStreak() throws {
        var fakeNow = Date(timeIntervalSince1970: 1_700_000_000)
        let engine = DailySessionEngine(
            runs: FakeRunRepo(),
            streaks: FakeStreakRepo(),
            calendar: .current,
            now: { fakeNow }
        )
        try engine.recordCompletion(score: 500)
        fakeNow = fakeNow.addingTimeInterval(36 * 3600 + 60) // 36t + 1 min
        try engine.recordCompletion(score: 500)
        XCTAssertEqual(engine.currentStreak(), 1)
    }

    func testDifficultyForFreshGameDefaultsToMedium() throws {
        let engine = DailySessionEngine(
            runs: FakeRunRepo(),
            streaks: FakeStreakRepo(),
            calendar: .current,
            now: { Date() }
        )
        XCTAssertEqual(try engine.recommendedDifficulty(forGameId: "nback"), .medium)
    }
}
```

- [ ] **Step 2: Skriv implementasjonen**

```swift
import Foundation

@MainActor
public final class DailySessionEngine {
    private let runs: any GameRunRepository
    private let streaks: any StreakRepository
    private let calendar: Calendar
    private let now: @MainActor () -> Date

    public init(runs: any GameRunRepository,
                streaks: any StreakRepository,
                calendar: Calendar = .current,
                now: @escaping @MainActor () -> Date = { Date() }) {
        self.runs = runs
        self.streaks = streaks
        self.calendar = calendar
        self.now = now
    }

    public func currentStreak() -> Int {
        (try? streaks.load().currentStreak) ?? 0
    }

    public func longestStreak() -> Int {
        (try? streaks.load().longestStreak) ?? 0
    }

    public func recommendedDifficulty(forGameId gameId: String) throws -> Difficulty {
        let recent = try runs.recent(forGameId: gameId, limit: 5)
        guard let last = recent.first else { return .medium }
        let scores = recent.map(\.score)
        return ScoreCalculator.recommendDifficulty(currentLevel: last.difficultyEnum, recentScores: scores)
    }

    public func didCompleteSessionToday() -> Bool {
        guard let state = try? streaks.load(),
              let last = state.lastSessionDate else { return false }
        return calendar.startOfDay(for: last) == calendar.startOfDay(for: now())
    }

    public func recordCompletion(score: Int) throws {
        let state = try streaks.load()
        let today = calendar.startOfDay(for: now())

        if let last = state.lastSessionDate {
            let lastDay = calendar.startOfDay(for: last)
            if lastDay == today {
                // Samme dag — streak uendret
                state.lastSessionDate = now()
                try streaks.save(state)
                return
            }
            let hoursSince = now().timeIntervalSince(last) / 3600
            if hoursSince > 36 {
                state.currentStreak = 1
            } else {
                state.currentStreak += 1
            }
        } else {
            state.currentStreak = 1
        }
        state.longestStreak = max(state.longestStreak, state.currentStreak)
        state.lastSessionDate = now()
        try streaks.save(state)
    }
}
```

- [ ] **Step 3: Regenerer og kjør tester**

```bash
xcodegen generate
xcodebuild -project Brainfit.xcodeproj -scheme Brainfit \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
  -quiet test -only-testing:BrainfitTests/DailySessionEngineTests 2>&1 | tail -20
```

Expected: alle 5 tester passerer.

- [ ] **Step 4: Commit**

```bash
git add Brainfit/Engine/DailySessionEngine.swift BrainfitTests/Engine/DailySessionEngineTests.swift
git commit -m "feat(engine): add DailySessionEngine with streak rules and difficulty recommendation"
```

---

### Task 17: SessionState (@Observable)

**Files:**
- Create: `Brainfit/Engine/SessionState.swift`

- [ ] **Step 1: Skriv observable state-objekt**

```swift
import Foundation
import Observation

public enum SessionPhase: Equatable {
    case idle
    case intro(gameId: String)
    case playing(gameId: String, difficulty: Difficulty)
    case result(GameResult)
    case summary(totalScore: Int)
    case cancelled
}

@Observable
@MainActor
public final class SessionState {
    public private(set) var phase: SessionPhase = .idle
    public private(set) var queuedGameIds: [String] = []
    public private(set) var currentIndex: Int = 0
    public private(set) var completedResults: [GameResult] = []
    public private(set) var sessionId: UUID = UUID()

    public init() {}

    public func start(gameIds: [String]) {
        sessionId = UUID()
        queuedGameIds = gameIds
        currentIndex = 0
        completedResults = []
        guard let first = gameIds.first else {
            phase = .idle
            return
        }
        phase = .intro(gameId: first)
    }

    public func startPlay(difficulty: Difficulty) {
        guard case .intro(let gameId) = phase else { return }
        phase = .playing(gameId: gameId, difficulty: difficulty)
    }

    public func recordResult(_ result: GameResult) {
        completedResults.append(result)
        phase = .result(result)
    }

    public func advance() {
        currentIndex += 1
        if currentIndex >= queuedGameIds.count {
            let total = completedResults.reduce(0) { $0 + $1.score }
            phase = .summary(totalScore: total)
        } else {
            phase = .intro(gameId: queuedGameIds[currentIndex])
        }
    }

    public func cancel() {
        phase = .cancelled
    }

    public func reset() {
        phase = .idle
        queuedGameIds = []
        currentIndex = 0
        completedResults = []
    }
}
```

- [ ] **Step 2: Regenerer, verifiser bygg, commit**

```bash
xcodegen generate
xcodebuild -project Brainfit.xcodeproj -scheme Brainfit \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
  -quiet build 2>&1 | tail -10
git add Brainfit/Engine/SessionState.swift
git commit -m "feat(engine): add SessionState observable phase machine"
```

---

### Task 18: AppEnvironment composition + verifisering av Wave 1

**Files:**
- Create: `Brainfit/App/AppEnvironment.swift`
- Modify: `Brainfit/App/BrainfitApp.swift`

- [ ] **Step 1: Skriv AppEnvironment**

```swift
import Foundation
import SwiftData

@MainActor
public final class AppEnvironment {
    public let modelContainer: ModelContainer
    public let runRepository: any GameRunRepository
    public let streakRepository: any StreakRepository
    public let engine: DailySessionEngine
    public let registry: GameRegistry
    public let sessionState: SessionState

    public init(inMemory: Bool = false) throws {
        let container = try BrainfitModelContainer.makeContainer(inMemory: inMemory)
        self.modelContainer = container
        let context = ModelContext(container)
        let runs = SwiftDataGameRunRepository(context: context)
        let streaks = SwiftDataStreakRepository(context: context)
        self.runRepository = runs
        self.streakRepository = streaks
        self.engine = DailySessionEngine(runs: runs, streaks: streaks)
        self.registry = GameRegistry()
        self.sessionState = SessionState()
    }
}
```

- [ ] **Step 2: Oppdater `Brainfit/App/BrainfitApp.swift`**

```swift
import SwiftUI

@main
struct BrainfitApp: App {
    @State private var environment: AppEnvironment?
    @State private var initError: String?

    var body: some Scene {
        WindowGroup {
            Group {
                if let environment {
                    Text("Core OK · Spill registrert: \(environment.registry.allGames.count)")
                        .font(.headline)
                } else if let initError {
                    Text("Init feilet: \(initError)")
                        .foregroundStyle(.red)
                } else {
                    ProgressView()
                }
            }
            .task {
                do {
                    environment = try AppEnvironment()
                } catch {
                    initError = error.localizedDescription
                }
            }
        }
    }
}
```

- [ ] **Step 3: Regenerer, kjør hele testsuite**

```bash
xcodegen generate
xcodebuild -project Brainfit.xcodeproj -scheme Brainfit \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
  -quiet test 2>&1 | tail -30
```

Expected: alle tester passerer, BUILD SUCCEEDED.

- [ ] **Step 4: Commit — Wave 1 ferdig**

```bash
git add Brainfit/App/AppEnvironment.swift Brainfit/App/BrainfitApp.swift
git commit -m "feat(core): compose AppEnvironment wiring container, repos, engine, registry"
git tag wave-1-complete
```

---

# Wave 2A — N-Back-spill (parallell)

Avhenger av Wave 1.

### Task 19: NBack-konfig og scoring-tester

**Files:**
- Create: `Brainfit/Games/NBack/NBackConfig.swift`
- Create: `Brainfit/Games/NBack/NBackScorer.swift`
- Create: `BrainfitTests/Games/NBack/NBackScorerTests.swift`

- [ ] **Step 1: Skriv NBackConfig.swift**

```swift
import Foundation

public struct NBackConfig: Sendable {
    public let n: Int                  // 1, 2 eller 3
    public let stimuliPerRound: Int    // 20 i MVP
    public let stimulusDurationMs: Int // 500
    public let interStimulusMs: Int    // 2000
    public let gridSize: Int           // 3 (3x3)

    public static func forDifficulty(_ difficulty: Difficulty) -> NBackConfig {
        switch difficulty {
        case .easy:   return NBackConfig(n: 1, stimuliPerRound: 20, stimulusDurationMs: 500, interStimulusMs: 2000, gridSize: 3)
        case .medium: return NBackConfig(n: 2, stimuliPerRound: 20, stimulusDurationMs: 500, interStimulusMs: 2000, gridSize: 3)
        case .hard:   return NBackConfig(n: 3, stimuliPerRound: 20, stimulusDurationMs: 500, interStimulusMs: 2000, gridSize: 3)
        }
    }
}
```

- [ ] **Step 2: Skriv NBackScorer.swift**

```swift
import Foundation

public struct NBackScore: Sendable, Equatable {
    public let score: Int
    public let hits: Int
    public let misses: Int
    public let falseAlarms: Int
    public let correctRejections: Int
    public let avgReactionMs: Double
}

public enum NBackScorer {
    public static func score(targets: Int,
                             nonTargets: Int,
                             hits: Int,
                             falseAlarms: Int,
                             avgReactionMs: Double) -> NBackScore {
        let misses = max(0, targets - hits)
        let correctRejections = max(0, nonTargets - falseAlarms)
        let accuracy: Double
        if targets == 0 {
            accuracy = nonTargets == 0 ? 1.0 : Double(correctRejections) / Double(nonTargets)
        } else {
            let hitRate = Double(hits) / Double(targets)
            let faRate = nonTargets == 0 ? 0 : Double(falseAlarms) / Double(nonTargets)
            accuracy = max(0, hitRate * (1 - faRate))
        }
        let raw = Int((accuracy * 1000).rounded())
        return NBackScore(
            score: ScoreCalculator.normalize(rawScore: raw),
            hits: hits,
            misses: misses,
            falseAlarms: falseAlarms,
            correctRejections: correctRejections,
            avgReactionMs: avgReactionMs
        )
    }
}
```

- [ ] **Step 3: Skriv tester**

```swift
import XCTest
@testable import Brainfit

final class NBackScorerTests: XCTestCase {
    func testPerfectPlayScores1000() {
        let result = NBackScorer.score(targets: 5, nonTargets: 15, hits: 5, falseAlarms: 0, avgReactionMs: 600)
        XCTAssertEqual(result.score, 1000)
        XCTAssertEqual(result.misses, 0)
        XCTAssertEqual(result.correctRejections, 15)
    }

    func testAllMissesAndNoFalseAlarmsScoresZero() {
        let result = NBackScorer.score(targets: 5, nonTargets: 15, hits: 0, falseAlarms: 0, avgReactionMs: 0)
        XCTAssertEqual(result.score, 0)
        XCTAssertEqual(result.misses, 5)
    }

    func testFalseAlarmsReduceScore() {
        let result = NBackScorer.score(targets: 5, nonTargets: 15, hits: 5, falseAlarms: 5, avgReactionMs: 600)
        XCTAssertLessThan(result.score, 1000)
        XCTAssertGreaterThan(result.score, 0)
    }

    func testZeroTargetsCountsRejectionsOnly() {
        let result = NBackScorer.score(targets: 0, nonTargets: 20, hits: 0, falseAlarms: 0, avgReactionMs: 0)
        XCTAssertEqual(result.score, 1000)
    }
}
```

- [ ] **Step 4: Regenerer, kjør tester, commit**

```bash
xcodegen generate
xcodebuild -project Brainfit.xcodeproj -scheme Brainfit \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
  -quiet test -only-testing:BrainfitTests/NBackScorerTests 2>&1 | tail -10
git add Brainfit/Games/NBack/ BrainfitTests/Games/NBack/
git commit -m "feat(nback): add config and scorer with tests"
```

---

### Task 20: NBackViewModel (state machine, seedet RNG)

**Files:**
- Create: `Brainfit/Games/NBack/NBackViewModel.swift`
- Create: `BrainfitTests/Games/NBack/NBackViewModelTests.swift`

- [ ] **Step 1: Skriv ViewModel**

```swift
import Foundation
import Observation

public struct NBackStimulus: Identifiable, Sendable {
    public let id = UUID()
    public let position: Int       // 0..<(gridSize*gridSize)
    public let isTarget: Bool
}

@Observable
@MainActor
public final class NBackViewModel {
    public let config: NBackConfig
    public private(set) var stimuli: [NBackStimulus] = []
    public private(set) var currentIndex: Int = -1
    public private(set) var hits: Int = 0
    public private(set) var falseAlarms: Int = 0
    public private(set) var responses: [Double] = [] // reaksjonstider i ms
    public private(set) var stimulusStart: Date?
    public private(set) var isComplete: Bool = false

    private var rng: SystemRandomNumberGeneratorBox

    public init(config: NBackConfig, seed: UInt64? = nil) {
        self.config = config
        self.rng = SystemRandomNumberGeneratorBox(seed: seed)
        generateStimuli()
    }

    public var currentStimulus: NBackStimulus? {
        guard currentIndex >= 0, currentIndex < stimuli.count else { return nil }
        return stimuli[currentIndex]
    }

    public func advanceToNext() {
        currentIndex += 1
        stimulusStart = Date()
        if currentIndex >= stimuli.count {
            isComplete = true
        }
    }

    public func registerMatchTap() {
        guard let stimulus = currentStimulus else { return }
        if let start = stimulusStart {
            responses.append(Date().timeIntervalSince(start) * 1000)
        }
        if stimulus.isTarget {
            hits += 1
        } else {
            falseAlarms += 1
        }
    }

    public func finalResult(difficulty: Difficulty) -> GameResult {
        let targets = stimuli.filter(\.isTarget).count
        let nonTargets = stimuli.count - targets
        let avgMs = responses.isEmpty ? 0 : responses.reduce(0, +) / Double(responses.count)
        let scored = NBackScorer.score(
            targets: targets,
            nonTargets: nonTargets,
            hits: hits,
            falseAlarms: falseAlarms,
            avgReactionMs: avgMs
        )
        return GameResult(
            gameId: "nback",
            score: scored.score,
            accuracy: targets > 0 ? Double(hits) / Double(targets) : 1.0,
            durationSeconds: Double(config.stimuliPerRound) * Double(config.stimulusDurationMs + config.interStimulusMs) / 1000,
            difficulty: difficulty,
            rawMetrics: [
                "hits": Double(scored.hits),
                "misses": Double(scored.misses),
                "falseAlarms": Double(scored.falseAlarms),
                "correctRejections": Double(scored.correctRejections),
                "avgReactionMs": scored.avgReactionMs
            ]
        )
    }

    private func generateStimuli() {
        let gridCells = config.gridSize * config.gridSize
        var positions: [Int] = []
        for _ in 0..<config.stimuliPerRound {
            positions.append(Int(rng.nextUInt64() % UInt64(gridCells)))
        }
        // ~30 % targets: tving noen til match
        let targetIndices = Set((config.n..<positions.count).shuffled(using: &rng).prefix(config.stimuliPerRound / 3))
        for index in targetIndices where index >= config.n {
            positions[index] = positions[index - config.n]
        }
        stimuli = positions.enumerated().map { idx, pos in
            let isTarget = idx >= config.n && pos == positions[idx - config.n]
            return NBackStimulus(position: pos, isTarget: isTarget)
        }
    }
}

// Determinisme: SeedableRNG-wrapper for tester
public struct SystemRandomNumberGeneratorBox: RandomNumberGenerator {
    private var state: UInt64

    public init(seed: UInt64?) {
        self.state = seed ?? UInt64.random(in: .min ... .max)
    }

    public mutating func next() -> UInt64 {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return state
    }

    public mutating func nextUInt64() -> UInt64 { next() }
}

// Trenger Array.shuffled(using:) for seedet RNG — Swift har dette innebygd
```

- [ ] **Step 2: Skriv tester**

```swift
import XCTest
@testable import Brainfit

@MainActor
final class NBackViewModelTests: XCTestCase {
    func testSameSeedProducesSameStimuli() {
        let vm1 = NBackViewModel(config: .forDifficulty(.medium), seed: 42)
        let vm2 = NBackViewModel(config: .forDifficulty(.medium), seed: 42)
        let positions1 = vm1.stimuli.map(\.position)
        let positions2 = vm2.stimuli.map(\.position)
        XCTAssertEqual(positions1, positions2)
    }

    func testGenerates20StimuliForMVPConfig() {
        let vm = NBackViewModel(config: .forDifficulty(.medium), seed: 7)
        XCTAssertEqual(vm.stimuli.count, 20)
    }

    func testTargetsExistAtFirstNIndicesOrLater() {
        let vm = NBackViewModel(config: .forDifficulty(.medium), seed: 99)
        // De første n stimuli kan ikke være targets
        for i in 0..<vm.config.n {
            XCTAssertFalse(vm.stimuli[i].isTarget)
        }
    }

    func testRegisteringMatchOnTargetIncrementsHits() {
        let vm = NBackViewModel(config: .forDifficulty(.easy), seed: 1)
        vm.advanceToNext()
        // Plasser fram til vi finner et target
        while vm.currentIndex < vm.stimuli.count - 1 && !(vm.currentStimulus?.isTarget ?? false) {
            vm.advanceToNext()
        }
        if vm.currentStimulus?.isTarget == true {
            let before = vm.hits
            vm.registerMatchTap()
            XCTAssertEqual(vm.hits, before + 1)
        }
    }
}
```

- [ ] **Step 3: Regenerer, kjør tester, commit**

```bash
xcodegen generate
xcodebuild -project Brainfit.xcodeproj -scheme Brainfit \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
  -quiet test -only-testing:BrainfitTests/NBackViewModelTests 2>&1 | tail -15
git add Brainfit/Games/NBack/NBackViewModel.swift BrainfitTests/Games/NBack/NBackViewModelTests.swift
git commit -m "feat(nback): add ViewModel with deterministic seeded RNG"
```

---

### Task 21: NBackPlayView

**Files:**
- Create: `Brainfit/Games/NBack/NBackPlayView.swift`

- [ ] **Step 1: Skriv view**

```swift
import SwiftUI

struct NBackPlayView: View {
    @State private var viewModel: NBackViewModel
    private let difficulty: Difficulty
    private let onComplete: @MainActor (GameResult) -> Void
    @State private var advanceTask: Task<Void, Never>?
    @State private var showingActiveStimulus = false

    init(config: NBackConfig,
         difficulty: Difficulty,
         onComplete: @escaping @MainActor (GameResult) -> Void) {
        self._viewModel = State(initialValue: NBackViewModel(config: config))
        self.difficulty = difficulty
        self.onComplete = onComplete
    }

    var body: some View {
        VStack(spacing: 32) {
            Text("Trykk MATCH når posisjonen er lik den fra \(viewModel.config.n) runder siden")
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            grid
                .padding()

            Button {
                viewModel.registerMatchTap()
            } label: {
                Text("MATCH")
                    .font(.title2.bold())
                    .frame(maxWidth: .infinity, minHeight: 60)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
            .disabled(viewModel.currentStimulus == nil)

            Spacer()
        }
        .padding()
        .onAppear { start() }
        .onDisappear { advanceTask?.cancel() }
    }

    private var grid: some View {
        let cells = viewModel.config.gridSize * viewModel.config.gridSize
        let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: viewModel.config.gridSize)
        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(0..<cells, id: \.self) { index in
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorFor(index: index))
                    .aspectRatio(1, contentMode: .fit)
                    .accessibilityLabel("Rute \(index + 1)")
            }
        }
    }

    private func colorFor(index: Int) -> Color {
        if showingActiveStimulus, viewModel.currentStimulus?.position == index {
            return .accentColor
        }
        return Color(.secondarySystemBackground)
    }

    private func start() {
        advanceTask = Task { @MainActor in
            for _ in 0..<viewModel.config.stimuliPerRound {
                viewModel.advanceToNext()
                showingActiveStimulus = true
                try? await Task.sleep(for: .milliseconds(viewModel.config.stimulusDurationMs))
                showingActiveStimulus = false
                try? await Task.sleep(for: .milliseconds(viewModel.config.interStimulusMs))
                if Task.isCancelled { return }
            }
            onComplete(viewModel.finalResult(difficulty: difficulty))
        }
    }
}
```

- [ ] **Step 2: Regenerer, verifiser bygg, commit**

```bash
xcodegen generate
xcodebuild -project Brainfit.xcodeproj -scheme Brainfit \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
  -quiet build 2>&1 | tail -10
git add Brainfit/Games/NBack/NBackPlayView.swift
git commit -m "feat(nback): add play view with timed grid stimuli"
```

---

### Task 22: NBackGame-konformans og registrering

**Files:**
- Create: `Brainfit/Games/NBack/NBackGame.swift`
- Modify: `Brainfit/App/AppEnvironment.swift`

- [ ] **Step 1: Skriv NBackGame.swift**

```swift
import SwiftUI

public struct NBackGame: Game {
    public init() {}

    public static let metadata = GameMetadata(
        id: "nback",
        displayName: "Husk Mønsteret",
        category: .memory,
        shortDescription: "Trykk når posisjonen er lik den fra N runder siden",
        icon: "square.grid.3x3.fill",
        targetDurationSeconds: 60
    )

    public func makeIntroView() -> some View {
        NBackIntroView()
    }

    public func makePlayView(difficulty: Difficulty,
                             onComplete: @escaping @MainActor (GameResult) -> Void) -> some View {
        NBackPlayView(
            config: .forDifficulty(difficulty),
            difficulty: difficulty,
            onComplete: onComplete
        )
    }
}

struct NBackIntroView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.grid.3x3.fill")
                .font(.system(size: 80))
                .foregroundStyle(.accent)
            Text("Husk Mønsteret")
                .font(.largeTitle.bold())
            Text("En firkant blinker i et 3×3-rutenett. Trykk MATCH når posisjonen er den samme som N runder tilbake.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}
```

- [ ] **Step 2: Registrer spillet i AppEnvironment**

I `Brainfit/App/AppEnvironment.swift`, etter `self.sessionState = SessionState()`, legg til:

```swift
        self.registry.register(NBackGame())
```

- [ ] **Step 3: Regenerer, kjør hele testsuite, commit**

```bash
xcodegen generate
xcodebuild -project Brainfit.xcodeproj -scheme Brainfit \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
  -quiet test 2>&1 | tail -20
git add Brainfit/Games/NBack/NBackGame.swift Brainfit/App/AppEnvironment.swift
git commit -m "feat(nback): conform to Game protocol and register in AppEnvironment"
```

---

### Task 23: Verifiser at N-back registreres i kjørende app

- [ ] **Step 1: Bygg og verifiser placeholder-teksten oppdateres**

```bash
xcodebuild -project Brainfit.xcodeproj -scheme Brainfit \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
  -quiet build 2>&1 | tail -5
```

Expected: BUILD SUCCEEDED. Når appen kjører i simulator (manuell verifisering — agent rapporterer kun bygg-status), skal teksten vise "Core OK · Spill registrert: 1" (eller 2 etter Wave 2B).

- [ ] **Step 2: Marker N-back-wave ferdig**

```bash
git tag wave-2a-nback-complete
```

---

# Wave 2B — Tap-the-Color (Stroop) (parallell)

Avhenger av Wave 1.

### Task 24: Stroop-konfig og scoring-tester

**Files:**
- Create: `Brainfit/Games/TapTheColor/StroopConfig.swift`
- Create: `Brainfit/Games/TapTheColor/StroopScorer.swift`
- Create: `BrainfitTests/Games/TapTheColor/StroopScorerTests.swift`

- [ ] **Step 1: Skriv StroopConfig.swift**

```swift
import SwiftUI

public enum StroopColor: String, CaseIterable, Sendable {
    case red, green, blue, yellow, purple

    public var displayName: String {
        switch self {
        case .red: return "RØD"
        case .green: return "GRØNN"
        case .blue: return "BLÅ"
        case .yellow: return "GUL"
        case .purple: return "LILLA"
        }
    }

    public var swiftUIColor: Color {
        switch self {
        case .red: return .red
        case .green: return .green
        case .blue: return .blue
        case .yellow: return .yellow
        case .purple: return .purple
        }
    }
}

public struct StroopConfig: Sendable {
    public let totalSeconds: Int
    public let optionCount: Int

    public static func forDifficulty(_ difficulty: Difficulty) -> StroopConfig {
        switch difficulty {
        case .easy:   return StroopConfig(totalSeconds: 30, optionCount: 3)
        case .medium: return StroopConfig(totalSeconds: 30, optionCount: 4)
        case .hard:   return StroopConfig(totalSeconds: 30, optionCount: 5)
        }
    }
}
```

- [ ] **Step 2: Skriv StroopScorer.swift**

```swift
import Foundation

public struct StroopScore: Sendable, Equatable {
    public let score: Int
    public let correct: Int
    public let incorrect: Int
    public let avgMs: Double
}

public enum StroopScorer {
    public static func score(correct: Int, incorrect: Int, avgMs: Double) -> StroopScore {
        let speedBonus = max(0, 200 - Int(avgMs / 10))
        let raw = correct * 50 - incorrect * 30 + speedBonus
        return StroopScore(
            score: ScoreCalculator.normalize(rawScore: raw),
            correct: correct,
            incorrect: incorrect,
            avgMs: avgMs
        )
    }
}
```

- [ ] **Step 3: Skriv tester**

```swift
import XCTest
@testable import Brainfit

final class StroopScorerTests: XCTestCase {
    func testAllCorrectGivesHighScore() {
        let result = StroopScorer.score(correct: 20, incorrect: 0, avgMs: 800)
        XCTAssertEqual(result.score, ScoreCalculator.normalize(rawScore: 20 * 50 + max(0, 200 - 80)))
    }

    func testIncorrectAnswersPenalize() {
        let allCorrect = StroopScorer.score(correct: 20, incorrect: 0, avgMs: 800)
        let withMistakes = StroopScorer.score(correct: 20, incorrect: 5, avgMs: 800)
        XCTAssertLessThan(withMistakes.score, allCorrect.score)
    }

    func testFasterResponsesGiveSpeedBonus() {
        let slow = StroopScorer.score(correct: 10, incorrect: 0, avgMs: 1500)
        let fast = StroopScorer.score(correct: 10, incorrect: 0, avgMs: 600)
        XCTAssertGreaterThan(fast.score, slow.score)
    }

    func testNegativeRawScoreIsClampedToZero() {
        let result = StroopScorer.score(correct: 0, incorrect: 50, avgMs: 1500)
        XCTAssertEqual(result.score, 0)
    }
}
```

- [ ] **Step 4: Regenerer, kjør tester, commit**

```bash
xcodegen generate
xcodebuild -project Brainfit.xcodeproj -scheme Brainfit \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
  -quiet test -only-testing:BrainfitTests/StroopScorerTests 2>&1 | tail -10
git add Brainfit/Games/TapTheColor/ BrainfitTests/Games/TapTheColor/
git commit -m "feat(stroop): add config, colors, scorer with tests"
```

---

### Task 25: StroopViewModel (timer + randomisering)

**Files:**
- Create: `Brainfit/Games/TapTheColor/StroopViewModel.swift`
- Create: `BrainfitTests/Games/TapTheColor/StroopViewModelTests.swift`

- [ ] **Step 1: Skriv ViewModel**

```swift
import Foundation
import Observation

public struct StroopStimulus: Identifiable, Sendable {
    public let id = UUID()
    public let word: StroopColor   // ordet som vises
    public let inkColor: StroopColor // fargen ordet tegnes i
    public var isCongruent: Bool { word == inkColor }
}

@Observable
@MainActor
public final class StroopViewModel {
    public let config: StroopConfig
    public let options: [StroopColor]
    public private(set) var currentStimulus: StroopStimulus
    public private(set) var correct: Int = 0
    public private(set) var incorrect: Int = 0
    public private(set) var responses: [Double] = []
    public private(set) var isComplete: Bool = false
    private var stimulusStart: Date

    private var rng: SystemRandomNumberGeneratorBox
    private let allOptions: [StroopColor]

    public init(config: StroopConfig, seed: UInt64? = nil) {
        self.config = config
        self.rng = SystemRandomNumberGeneratorBox(seed: seed)
        let pool = Array(StroopColor.allCases.prefix(config.optionCount))
        self.allOptions = pool
        self.options = pool
        var prng = rng
        let word = pool[Int(prng.nextUInt64() % UInt64(pool.count))]
        let ink = pool[Int(prng.nextUInt64() % UInt64(pool.count))]
        self.rng = prng
        self.currentStimulus = StroopStimulus(word: word, inkColor: ink)
        self.stimulusStart = Date()
    }

    public func registerAnswer(_ chosen: StroopColor) {
        let ms = Date().timeIntervalSince(stimulusStart) * 1000
        responses.append(ms)
        if chosen == currentStimulus.inkColor {
            correct += 1
        } else {
            incorrect += 1
        }
        nextStimulus()
    }

    public func markComplete() {
        isComplete = true
    }

    public func finalResult(difficulty: Difficulty, durationSeconds: Double) -> GameResult {
        let avgMs = responses.isEmpty ? 0 : responses.reduce(0, +) / Double(responses.count)
        let scored = StroopScorer.score(correct: correct, incorrect: incorrect, avgMs: avgMs)
        let total = correct + incorrect
        let accuracy = total == 0 ? 0 : Double(correct) / Double(total)
        return GameResult(
            gameId: "tap-the-color",
            score: scored.score,
            accuracy: accuracy,
            durationSeconds: durationSeconds,
            difficulty: difficulty,
            rawMetrics: [
                "correct": Double(scored.correct),
                "incorrect": Double(scored.incorrect),
                "avgMs": scored.avgMs
            ]
        )
    }

    private func nextStimulus() {
        let word = allOptions[Int(rng.nextUInt64() % UInt64(allOptions.count))]
        let ink = allOptions[Int(rng.nextUInt64() % UInt64(allOptions.count))]
        currentStimulus = StroopStimulus(word: word, inkColor: ink)
        stimulusStart = Date()
    }
}
```

- [ ] **Step 2: Skriv tester**

```swift
import XCTest
@testable import Brainfit

@MainActor
final class StroopViewModelTests: XCTestCase {
    func testCorrectAnswerIncrementsCorrect() {
        let vm = StroopViewModel(config: .forDifficulty(.medium), seed: 1)
        let actualInk = vm.currentStimulus.inkColor
        vm.registerAnswer(actualInk)
        XCTAssertEqual(vm.correct, 1)
        XCTAssertEqual(vm.incorrect, 0)
    }

    func testIncorrectAnswerIncrementsIncorrect() {
        let vm = StroopViewModel(config: .forDifficulty(.medium), seed: 2)
        let wrong = StroopColor.allCases.first { $0 != vm.currentStimulus.inkColor }!
        vm.registerAnswer(wrong)
        XCTAssertEqual(vm.correct, 0)
        XCTAssertEqual(vm.incorrect, 1)
    }

    func testOptionsCountMatchesDifficulty() {
        XCTAssertEqual(StroopViewModel(config: .forDifficulty(.easy), seed: 1).options.count, 3)
        XCTAssertEqual(StroopViewModel(config: .forDifficulty(.medium), seed: 1).options.count, 4)
        XCTAssertEqual(StroopViewModel(config: .forDifficulty(.hard), seed: 1).options.count, 5)
    }

    func testFinalResultReportsCorrectGameId() {
        let vm = StroopViewModel(config: .forDifficulty(.medium), seed: 1)
        let result = vm.finalResult(difficulty: .medium, durationSeconds: 30)
        XCTAssertEqual(result.gameId, "tap-the-color")
    }
}
```

- [ ] **Step 3: Regenerer, kjør tester, commit**

```bash
xcodegen generate
xcodebuild -project Brainfit.xcodeproj -scheme Brainfit \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
  -quiet test -only-testing:BrainfitTests/StroopViewModelTests 2>&1 | tail -15
git add Brainfit/Games/TapTheColor/StroopViewModel.swift BrainfitTests/Games/TapTheColor/StroopViewModelTests.swift
git commit -m "feat(stroop): add ViewModel with seeded RNG"
```

---

### Task 26: StroopPlayView

**Files:**
- Create: `Brainfit/Games/TapTheColor/StroopPlayView.swift`

- [ ] **Step 1: Skriv view**

```swift
import SwiftUI

struct StroopPlayView: View {
    @State private var viewModel: StroopViewModel
    private let difficulty: Difficulty
    private let onComplete: @MainActor (GameResult) -> Void
    @State private var remainingSeconds: Int
    @State private var timerTask: Task<Void, Never>?

    init(config: StroopConfig,
         difficulty: Difficulty,
         onComplete: @escaping @MainActor (GameResult) -> Void) {
        self._viewModel = State(initialValue: StroopViewModel(config: config))
        self.difficulty = difficulty
        self.onComplete = onComplete
        self._remainingSeconds = State(initialValue: config.totalSeconds)
    }

    var body: some View {
        VStack(spacing: 32) {
            HStack {
                Image(systemName: "timer")
                Text("\(remainingSeconds)s")
                    .font(.title2.monospacedDigit())
            }
            .padding(.top)

            Spacer()

            Text(viewModel.currentStimulus.word.displayName)
                .font(.system(size: 80, weight: .bold))
                .foregroundStyle(viewModel.currentStimulus.inkColor.swiftUIColor)
                .accessibilityLabel("Ord: \(viewModel.currentStimulus.word.displayName), farge: \(viewModel.currentStimulus.inkColor.displayName)")

            Text("Trykk fargen ordet er skrevet i")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()

            grid

            Spacer().frame(height: 24)
        }
        .padding()
        .onAppear { startTimer() }
        .onDisappear { timerTask?.cancel() }
    }

    private var grid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 2)
        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(viewModel.options, id: \.self) { color in
                Button {
                    viewModel.registerAnswer(color)
                } label: {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(color.swiftUIColor)
                        .frame(height: 80)
                        .overlay(
                            Text(color.displayName)
                                .font(.headline)
                                .foregroundStyle(.white)
                        )
                }
                .accessibilityLabel(color.displayName)
            }
        }
    }

    private func startTimer() {
        timerTask = Task { @MainActor in
            for _ in 0..<viewModel.config.totalSeconds {
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { return }
                remainingSeconds -= 1
            }
            viewModel.markComplete()
            onComplete(viewModel.finalResult(difficulty: difficulty,
                                             durationSeconds: Double(viewModel.config.totalSeconds)))
        }
    }
}
```

- [ ] **Step 2: Regenerer, bygg, commit**

```bash
xcodegen generate
xcodebuild -project Brainfit.xcodeproj -scheme Brainfit \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
  -quiet build 2>&1 | tail -10
git add Brainfit/Games/TapTheColor/StroopPlayView.swift
git commit -m "feat(stroop): add play view with timer and color grid"
```

---

### Task 27: TapTheColorGame-konformans og registrering

**Files:**
- Create: `Brainfit/Games/TapTheColor/TapTheColorGame.swift`
- Modify: `Brainfit/App/AppEnvironment.swift`

- [ ] **Step 1: Skriv TapTheColorGame.swift**

```swift
import SwiftUI

public struct TapTheColorGame: Game {
    public init() {}

    public static let metadata = GameMetadata(
        id: "tap-the-color",
        displayName: "Riktig Farge",
        category: .attention,
        shortDescription: "Trykk fargen ordet er skrevet i — ikke ordet selv",
        icon: "paintpalette.fill",
        targetDurationSeconds: 30
    )

    public func makeIntroView() -> some View {
        TapTheColorIntroView()
    }

    public func makePlayView(difficulty: Difficulty,
                             onComplete: @escaping @MainActor (GameResult) -> Void) -> some View {
        StroopPlayView(
            config: .forDifficulty(difficulty),
            difficulty: difficulty,
            onComplete: onComplete
        )
    }
}

struct TapTheColorIntroView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "paintpalette.fill")
                .font(.system(size: 80))
                .foregroundStyle(.accent)
            Text("Riktig Farge")
                .font(.largeTitle.bold())
            Text("Trykk fargen ordet er skrevet i. Hvis ordet er «RØD» og det er skrevet i blått, trykker du BLÅ.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}
```

- [ ] **Step 2: Registrer spillet i AppEnvironment**

I `Brainfit/App/AppEnvironment.swift`, etter `self.registry.register(NBackGame())`, legg til:

```swift
        self.registry.register(TapTheColorGame())
```

- [ ] **Step 3: Regenerer, kjør hele testsuite, commit**

```bash
xcodegen generate
xcodebuild -project Brainfit.xcodeproj -scheme Brainfit \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
  -quiet test 2>&1 | tail -20
git add Brainfit/Games/TapTheColor/TapTheColorGame.swift Brainfit/App/AppEnvironment.swift
git commit -m "feat(stroop): conform to Game protocol and register in AppEnvironment"
git tag wave-2b-stroop-complete
```

---

### Task 28: Sluttverifikasjon for Stroop-wave

- [ ] **Step 1: Bygg og verifiser at registry har begge spill**

```bash
xcodebuild -project Brainfit.xcodeproj -scheme Brainfit \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
  -quiet build 2>&1 | tail -5
```

Expected: BUILD SUCCEEDED. Placeholder-tekst i kjørende app vil nå vise "Core OK · Spill registrert: 2".

---

# Wave 2C — UI-skall og designsystem (parallell)

Avhenger av Wave 1. Kan starte med stubs for `NBackGame` / `TapTheColorGame` hvis de ikke er ferdige enda — UI-skallet ringer kun til registry.

### Task 29: Theme.swift

**Files:**
- Create: `Brainfit/DesignSystem/Theme.swift`

- [ ] **Step 1: Skriv Theme.swift**

```swift
import SwiftUI

public enum Theme {
    public enum Spacing {
        public static let xs: CGFloat = 4
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 16
        public static let lg: CGFloat = 24
        public static let xl: CGFloat = 40
    }

    public enum Radius {
        public static let card: CGFloat = 16
        public static let button: CGFloat = 12
    }

    public enum FontStyle {
        public static let displayLarge = Font.system(size: 48, weight: .bold, design: .rounded)
        public static let title = Font.title.weight(.semibold)
        public static let body = Font.body
        public static let caption = Font.caption
    }
}

public extension ShapeStyle where Self == Color {
    static var brainfitBackground: Color { Color(.systemBackground) }
    static var brainfitCard: Color { Color(.secondarySystemBackground) }
    static var brainfitMutedText: Color { Color(.secondaryLabel) }
}
```

- [ ] **Step 2: Regenerer, bygg, commit**

```bash
xcodegen generate
xcodebuild -project Brainfit.xcodeproj -scheme Brainfit \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
  -quiet build 2>&1 | tail -5
git add Brainfit/DesignSystem/Theme.swift
git commit -m "feat(design): add Theme tokens for spacing, radius, fonts, colors"
```

---

### Task 30: HomeView

**Files:**
- Create: `Brainfit/Features/Home/HomeView.swift`

- [ ] **Step 1: Skriv HomeView**

```swift
import SwiftUI

public struct HomeView: View {
    let engine: DailySessionEngine
    let registry: GameRegistry
    let onStartSession: ([String]) -> Void

    private var todayDone: Bool { engine.didCompleteSessionToday() }

    public var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.lg) {
                header
                streakCard
                Spacer()
                startButton
                Spacer().frame(height: Theme.Spacing.lg)
            }
            .padding(.horizontal, Theme.Spacing.md)
            .navigationTitle("Brainfit")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(greeting)
                .font(Theme.FontStyle.title)
            Text(dateString)
                .font(Theme.FontStyle.caption)
                .foregroundStyle(.brainfitMutedText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, Theme.Spacing.lg)
    }

    private var streakCard: some View {
        HStack {
            Image(systemName: "flame.fill")
                .font(.title)
                .foregroundStyle(.orange)
            VStack(alignment: .leading) {
                Text("\(engine.currentStreak()) dager på rad")
                    .font(.headline)
                Text("Lengste: \(engine.longestStreak())")
                    .font(.caption)
                    .foregroundStyle(.brainfitMutedText)
            }
            Spacer()
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: Theme.Radius.card).fill(.brainfitCard))
    }

    private var startButton: some View {
        Button {
            let ids = registry.allGames.map(\.metadata.id)
            onStartSession(ids)
        } label: {
            Text(todayDone ? "Dagens trening fullført" : "Start dagens trening")
                .font(.title3.bold())
                .frame(maxWidth: .infinity, minHeight: 56)
        }
        .buttonStyle(.borderedProminent)
        .disabled(todayDone || registry.allGames.isEmpty)
        .accessibilityLabel(todayDone ? "Fullført" : "Start dagens trening")
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<10: return "God morgen"
        case 10..<17: return "Hei"
        case 17..<22: return "God kveld"
        default: return "Hei"
        }
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "nb_NO")
        formatter.dateStyle = .full
        return formatter.string(from: Date())
    }
}
```

- [ ] **Step 2: Regenerer, bygg, commit**

```bash
xcodegen generate
xcodebuild -project Brainfit.xcodeproj -scheme Brainfit \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
  -quiet build 2>&1 | tail -5
git add Brainfit/Features/Home/HomeView.swift
git commit -m "feat(ui): add HomeView with streak card and start button"
```

---

### Task 31: SessionFlowView

**Files:**
- Create: `Brainfit/Features/Session/SessionFlowView.swift`

- [ ] **Step 1: Skriv SessionFlowView**

```swift
import SwiftUI

public struct SessionFlowView: View {
    let registry: GameRegistry
    let engine: DailySessionEngine
    let runRepository: any GameRunRepository
    @Bindable var state: SessionState
    let onClose: () -> Void

    @State private var showingCancelConfirm = false

    public var body: some View {
        ZStack(alignment: .topTrailing) {
            content
            cancelButton
        }
        .background(Color.brainfitBackground.ignoresSafeArea())
    }

    @ViewBuilder
    private var content: some View {
        switch state.phase {
        case .idle:
            ProgressView()
        case .intro(let gameId):
            introView(for: gameId)
        case .playing(let gameId, let difficulty):
            playView(for: gameId, difficulty: difficulty)
        case .result(let result):
            resultView(for: result)
        case .summary(let total):
            summaryView(total: total)
        case .cancelled:
            VStack { ProgressView() }
                .onAppear { onClose() }
        }
    }

    private var cancelButton: some View {
        Button {
            showingCancelConfirm = true
        } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.title2)
                .foregroundStyle(.secondary)
        }
        .padding()
        .accessibilityLabel("Avbryt økt")
        .confirmationDialog("Avbryt økten?", isPresented: $showingCancelConfirm) {
            Button("Avbryt økten", role: .destructive) {
                state.cancel()
            }
            Button("Fortsett", role: .cancel) {}
        } message: {
            Text("Resultater fra denne økten vil ikke lagres.")
        }
    }

    private func introView(for gameId: String) -> some View {
        VStack(spacing: Theme.Spacing.lg) {
            if let game = registry.game(forId: gameId) {
                game.makeIntroView()
            } else {
                Text("Ukjent spill: \(gameId)")
            }
            Button("Start") {
                let difficulty = (try? engine.recommendedDifficulty(forGameId: gameId)) ?? .medium
                state.startPlay(difficulty: difficulty)
            }
            .buttonStyle(.borderedProminent)
            .font(.title3.bold())
        }
        .padding()
    }

    private func playView(for gameId: String, difficulty: Difficulty) -> some View {
        Group {
            if let game = registry.game(forId: gameId) {
                game.makePlayView(difficulty: difficulty) { result in
                    persist(result: result)
                    state.recordResult(result)
                }
            } else {
                Text("Ukjent spill: \(gameId)")
            }
        }
    }

    private func resultView(for result: GameResult) -> some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "star.fill")
                .font(.system(size: 60))
                .foregroundStyle(.yellow)
            Text("Score")
                .font(.headline)
            Text("\(result.score)")
                .font(Theme.FontStyle.displayLarge)
            Button("Neste") {
                state.advance()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private func summaryView(total: Int) -> some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)
            Text("Økten er fullført")
                .font(.title2.bold())
            Text("Totalscore: \(total)")
                .font(.title3)
            Button("Ferdig") {
                try? engine.recordCompletion(score: total)
                onClose()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private func persist(result: GameResult) {
        do {
            let run = try GameRun(from: result, sessionId: state.sessionId)
            try runRepository.save(run)
        } catch {
            // Stille feil — en feilet save bryter ikke økten
        }
    }
}
```

- [ ] **Step 2: Regenerer, bygg, commit**

```bash
xcodegen generate
xcodebuild -project Brainfit.xcodeproj -scheme Brainfit \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
  -quiet build 2>&1 | tail -10
git add Brainfit/Features/Session/SessionFlowView.swift
git commit -m "feat(ui): add SessionFlowView with intro/play/result/summary phases"
```

---

### Task 32: StatsView

**Files:**
- Create: `Brainfit/Features/Stats/StatsView.swift`

- [ ] **Step 1: Skriv StatsView**

```swift
import SwiftUI
import Charts

public struct StatsView: View {
    let runRepository: any GameRunRepository
    let registry: GameRegistry

    @State private var selectedRange: Range = .month
    @State private var runs: [GameRun] = []

    public enum Range: String, CaseIterable, Identifiable {
        case week, month, quarter
        public var id: String { rawValue }
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .quarter: return 90
            }
        }
        var label: String {
            switch self {
            case .week: return "7 dager"
            case .month: return "30 dager"
            case .quarter: return "90 dager"
            }
        }
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    Picker("Tidsrom", selection: $selectedRange) {
                        ForEach(Range.allCases) { range in
                            Text(range.label).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)

                    chartSection

                    gameCards
                }
                .padding()
            }
            .navigationTitle("Statistikk")
            .task(id: selectedRange) { await reload() }
        }
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Snittscore per dag")
                .font(.headline)
            if runs.isEmpty {
                Text("Ingen data ennå — spill noen økter først.")
                    .font(.subheadline)
                    .foregroundStyle(.brainfitMutedText)
                    .frame(maxWidth: .infinity, minHeight: 160)
            } else {
                Chart(dailyAverages(), id: \.day) { entry in
                    LineMark(x: .value("Dag", entry.day), y: .value("Score", entry.average))
                    PointMark(x: .value("Dag", entry.day), y: .value("Score", entry.average))
                }
                .frame(height: 200)
            }
        }
    }

    private var gameCards: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Per spill")
                .font(.headline)
            ForEach(registry.allGames, id: \.metadata.id) { game in
                let filtered = runs.filter { $0.gameId == game.metadata.id }
                gameCard(metadata: game.metadata, runs: filtered)
            }
        }
    }

    private func gameCard(metadata: GameMetadata, runs: [GameRun]) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: metadata.icon)
                .font(.title2)
                .frame(width: 40)
            VStack(alignment: .leading) {
                Text(metadata.displayName).font(.headline)
                Text(runs.isEmpty
                     ? "Ingen økter enda"
                     : "Beste: \(runs.map(\.score).max() ?? 0) · \(runs.count) økter")
                    .font(.caption)
                    .foregroundStyle(.brainfitMutedText)
            }
            Spacer()
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: Theme.Radius.card).fill(.brainfitCard))
    }

    private func dailyAverages() -> [(day: Date, average: Double)] {
        let grouped = Dictionary(grouping: runs) { Calendar.current.startOfDay(for: $0.playedAt) }
        return grouped
            .map { (day: $0.key, average: Double($0.value.reduce(0) { $0 + $1.score }) / Double($0.value.count)) }
            .sorted { $0.day < $1.day }
    }

    @MainActor
    private func reload() async {
        let since = Calendar.current.date(byAdding: .day, value: -selectedRange.days, to: Date()) ?? Date()
        runs = (try? runRepository.all(since: since)) ?? []
    }
}
```

- [ ] **Step 2: Regenerer, bygg, commit**

```bash
xcodegen generate
xcodebuild -project Brainfit.xcodeproj -scheme Brainfit \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
  -quiet build 2>&1 | tail -10
git add Brainfit/Features/Stats/StatsView.swift
git commit -m "feat(ui): add StatsView with chart and per-game cards"
```

---

### Task 33: SettingsView

**Files:**
- Create: `Brainfit/Features/Settings/SettingsView.swift`

- [ ] **Step 1: Skriv SettingsView**

```swift
import SwiftUI
import UserNotifications

public struct SettingsView: View {
    @State private var reminderEnabled: Bool = UserDefaults.standard.bool(forKey: "reminderEnabled")
    @State private var reminderTime: Date = SettingsView.loadReminderTime()
    @State private var soundEnabled: Bool = UserDefaults.standard.object(forKey: "soundEnabled") as? Bool ?? true
    @State private var iCloudStatus: String = "Sjekker…"

    public var body: some View {
        NavigationStack {
            Form {
                Section("Synk") {
                    HStack {
                        Image(systemName: "icloud.fill")
                        Text(iCloudStatus)
                    }
                }

                Section("Påminnelse") {
                    Toggle("Daglig påminnelse", isOn: $reminderEnabled)
                        .onChange(of: reminderEnabled) { _, new in
                            UserDefaults.standard.set(new, forKey: "reminderEnabled")
                            updateNotificationSchedule()
                        }
                    if reminderEnabled {
                        DatePicker("Tidspunkt", selection: $reminderTime, displayedComponents: .hourAndMinute)
                            .onChange(of: reminderTime) { _, new in
                                UserDefaults.standard.set(new, forKey: "reminderTime")
                                updateNotificationSchedule()
                            }
                    }
                }

                Section("Lyd") {
                    Toggle("Lyd på", isOn: $soundEnabled)
                        .onChange(of: soundEnabled) { _, new in
                            UserDefaults.standard.set(new, forKey: "soundEnabled")
                        }
                }

                Section("Om Brainfit") {
                    LabeledContent("Versjon", value: appVersion)
                    Link("Lisens (MIT)", destination: URL(string: "https://github.com/frodesolem/brainfit-ios/blob/main/LICENSE")!)
                    Link("GitHub", destination: URL(string: "https://github.com/frodesolem/brainfit-ios")!)
                }
            }
            .navigationTitle("Innstillinger")
            .task { await checkICloudStatus() }
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.0"
    }

    private static func loadReminderTime() -> Date {
        UserDefaults.standard.object(forKey: "reminderTime") as? Date
        ?? Calendar.current.date(from: DateComponents(hour: 8, minute: 30)) ?? Date()
    }

    @MainActor
    private func checkICloudStatus() async {
        // Forenklet — full sjekk ville bruke CKContainer.accountStatus
        iCloudStatus = FileManager.default.ubiquityIdentityToken != nil ? "Logget på iCloud" : "Ikke logget på iCloud"
    }

    private func updateNotificationSchedule() {
        Task {
            let center = UNUserNotificationCenter.current()
            center.removeAllPendingNotificationRequests()
            guard reminderEnabled else { return }
            let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = "Dagens trening venter"
            content.body = "Hold streak'en — start en kort økt nå."
            content.sound = soundEnabled ? .default : nil
            let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(identifier: "daily-reminder", content: content, trigger: trigger)
            try? await center.add(request)
        }
    }
}
```

- [ ] **Step 2: Regenerer, bygg, commit**

```bash
xcodegen generate
xcodebuild -project Brainfit.xcodeproj -scheme Brainfit \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
  -quiet build 2>&1 | tail -10
git add Brainfit/Features/Settings/SettingsView.swift
git commit -m "feat(ui): add SettingsView with iCloud status, reminders, and about"
```

---

### Task 34: RootView med TabView og modal session

**Files:**
- Create: `Brainfit/App/RootView.swift`
- Modify: `Brainfit/App/BrainfitApp.swift`

- [ ] **Step 1: Skriv RootView.swift**

```swift
import SwiftUI

struct RootView: View {
    let environment: AppEnvironment

    @State private var showingSession = false

    var body: some View {
        TabView {
            HomeView(
                engine: environment.engine,
                registry: environment.registry,
                onStartSession: startSession
            )
            .tabItem { Label("Hjem", systemImage: "house.fill") }

            StatsView(
                runRepository: environment.runRepository,
                registry: environment.registry
            )
            .tabItem { Label("Statistikk", systemImage: "chart.line.uptrend.xyaxis") }

            SettingsView()
                .tabItem { Label("Innstillinger", systemImage: "gearshape.fill") }
        }
        .fullScreenCover(isPresented: $showingSession) {
            SessionFlowView(
                registry: environment.registry,
                engine: environment.engine,
                runRepository: environment.runRepository,
                state: environment.sessionState,
                onClose: { showingSession = false }
            )
        }
    }

    private func startSession(gameIds: [String]) {
        environment.sessionState.start(gameIds: gameIds)
        showingSession = true
    }
}
```

- [ ] **Step 2: Oppdater BrainfitApp.swift**

```swift
import SwiftUI

@main
struct BrainfitApp: App {
    @State private var environment: AppEnvironment?
    @State private var initError: String?

    var body: some Scene {
        WindowGroup {
            Group {
                if let environment {
                    RootView(environment: environment)
                } else if let initError {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.orange)
                        Text("Klarte ikke å starte appen")
                            .font(.headline)
                        Text(initError)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                } else {
                    ProgressView()
                }
            }
            .task {
                do {
                    environment = try AppEnvironment()
                } catch {
                    initError = error.localizedDescription
                }
            }
        }
    }
}
```

- [ ] **Step 3: Regenerer, kjør alle tester, commit**

```bash
xcodegen generate
xcodebuild -project Brainfit.xcodeproj -scheme Brainfit \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
  -quiet test 2>&1 | tail -20
git add Brainfit/App/RootView.swift Brainfit/App/BrainfitApp.swift
git commit -m "feat(ui): wire RootView with TabView and modal session presentation"
```

---

### Task 35: UI-test for happy path

**Files:**
- Modify: `BrainfitUITests/BrainfitUITests.swift`

- [ ] **Step 1: Erstatt smoke-testen med happy-path-test**

```swift
import XCTest

final class BrainfitUITests: XCTestCase {
    func testHomeScreenShowsStartButton() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["Start dagens trening"].waitForExistence(timeout: 5))
    }

    func testCanNavigateBetweenTabs() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Statistikk"].waitForExistence(timeout: 5))
        app.tabBars.buttons["Statistikk"].tap()
        XCTAssertTrue(app.staticTexts["Snittscore per dag"].exists ||
                      app.staticTexts["Ingen data ennå — spill noen økter først."].exists)
        app.tabBars.buttons["Innstillinger"].tap()
        XCTAssertTrue(app.navigationBars["Innstillinger"].exists)
    }

    func testCancelSessionReturnsToHome() {
        let app = XCUIApplication()
        app.launch()
        guard app.buttons["Start dagens trening"].waitForExistence(timeout: 5) else {
            return XCTFail("Start-knapp ikke funnet")
        }
        app.buttons["Start dagens trening"].tap()
        XCTAssertTrue(app.buttons["Avbryt økt"].waitForExistence(timeout: 5))
        app.buttons["Avbryt økt"].tap()
        app.buttons["Avbryt økten"].tap()
        XCTAssertTrue(app.buttons["Start dagens trening"].waitForExistence(timeout: 5))
    }
}
```

- [ ] **Step 2: Regenerer, bygg, commit (UI-tester kjøres i CI, ikke blokkering)**

```bash
xcodegen generate
xcodebuild -project Brainfit.xcodeproj -scheme Brainfit \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
  -quiet build 2>&1 | tail -5
git add BrainfitUITests/BrainfitUITests.swift
git commit -m "test(ui): add happy-path UI tests for tabs and session cancellation"
git tag wave-2c-ui-complete
```

---

# Wave 2D — Åpen kildekode-dokumentasjon og CI (parallell, uavhengig)

Kan kjøres samtidig med Wave 2A/B/C — ingen kode-avhengigheter.

### Task 36: README.md

**Files:**
- Create: `README.md`

- [ ] **Step 1: Skriv README**

```markdown
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
```

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -m "docs: add README"
```

---

### Task 37: CONTRIBUTING.md

**Files:**
- Create: `CONTRIBUTING.md`

- [ ] **Step 1: Skriv CONTRIBUTING.md**

```markdown
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
```

- [ ] **Step 2: Commit**

```bash
git add CONTRIBUTING.md
git commit -m "docs: add CONTRIBUTING guide"
```

---

### Task 38: CODE_OF_CONDUCT.md

**Files:**
- Create: `CODE_OF_CONDUCT.md`

- [ ] **Step 1: Skriv CODE_OF_CONDUCT.md (Contributor Covenant 2.1 kortform)**

```markdown
# Code of Conduct

## Vårt løfte

Vi som bidragsytere og vedlikeholdere forplikter oss til å gjøre deltakelse i prosjektet en respektfull opplevelse for alle, uavhengig av alder, kropp, funksjonsevne, etnisk bakgrunn, kjønnsidentitet eller -uttrykk, erfaringsnivå, utdanning, sosioøkonomisk status, nasjonalitet, utseende, rase, religion eller seksuell identitet.

## Standarder

Eksempler på positiv adferd:
- Bruk inkluderende språk
- Vis respekt for ulike synspunkter
- Ta imot konstruktiv kritikk
- Fokuser på det som er best for fellesskapet

Eksempler på uakseptabel adferd:
- Trakassering, fornærmelser eller nedsettende kommentarer
- Personangrep
- Publisering av andres private informasjon uten samtykke

## Håndheving

Brudd kan rapporteres til vedlikeholdere via GitHub issues merket `coc-violation` eller direkte til prosjekteier (`frode.solem@sigma2.no`). Alle rapporter behandles konfidensielt.

## Tilpasning

Denne Code of Conduct er tilpasset fra [Contributor Covenant 2.1](https://www.contributor-covenant.org/version/2/1/code_of_conduct.html).
```

- [ ] **Step 2: Commit**

```bash
git add CODE_OF_CONDUCT.md
git commit -m "docs: add Contributor Covenant Code of Conduct"
```

---

### Task 39: docs/ARCHITECTURE.md

**Files:**
- Create: `docs/ARCHITECTURE.md`

- [ ] **Step 1: Skriv ARCHITECTURE.md**

```markdown
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
```

- [ ] **Step 2: Commit**

```bash
mkdir -p docs
git add docs/ARCHITECTURE.md
git commit -m "docs: add architecture overview"
```

---

### Task 40: docs/ADDING_A_GAME.md

**Files:**
- Create: `docs/ADDING_A_GAME.md`

- [ ] **Step 1: Skriv ADDING_A_GAME.md**

```markdown
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
```

- [ ] **Step 2: Commit**

```bash
git add docs/ADDING_A_GAME.md
git commit -m "docs: add ADDING_A_GAME guide for contributors"
```

---

### Task 41: docs/DESIGN_PRINCIPLES.md

**Files:**
- Create: `docs/DESIGN_PRINCIPLES.md`

- [ ] **Step 1: Skriv DESIGN_PRINCIPLES.md**

```markdown
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
```

- [ ] **Step 2: Commit**

```bash
git add docs/DESIGN_PRINCIPLES.md
git commit -m "docs: add design principles"
```

---

### Task 42: Issue- og PR-templates

**Files:**
- Create: `.github/ISSUE_TEMPLATE/bug.md`
- Create: `.github/ISSUE_TEMPLATE/feature.md`
- Create: `.github/ISSUE_TEMPLATE/new-game.md`
- Create: `.github/ISSUE_TEMPLATE/config.yml`
- Create: `.github/PULL_REQUEST_TEMPLATE.md`

- [ ] **Step 1: Lag mapper**

```bash
mkdir -p .github/ISSUE_TEMPLATE
```

- [ ] **Step 2: Skriv `bug.md`**

```markdown
---
name: Bug-rapport
about: Noe fungerer ikke som forventet
labels: bug
---

## Hva skjedde
<!-- Kort beskrivelse -->

## Hva forventet du
<!-- Forventet adferd -->

## Steg for å reprodusere
1.
2.
3.

## Miljø
- iOS-versjon:
- Enhet/simulator:
- Brainfit-versjon:
```

- [ ] **Step 3: Skriv `feature.md`**

```markdown
---
name: Ny funksjon
about: Forslag til en forbedring eller ny funksjonalitet
labels: enhancement
---

## Problem
<!-- Hvilket problem løser dette? -->

## Forslag
<!-- Hva foreslår du? -->

## Alternativer
<!-- Andre måter å løse det på -->
```

- [ ] **Step 4: Skriv `new-game.md`**

```markdown
---
name: Nytt spill
about: Forslag til et nytt spill
labels: new-game, good-first-issue
---

## Spillets navn
<!-- F.eks. "Ord-twist" -->

## Kategori
<!-- memory, reaction, attention, language, math, problemSolving -->

## Mekanikk
<!-- Hvordan spilles det? 3–5 setninger. -->

## Inspirasjon
<!-- Lignende spill i andre apper, eller original idé -->

## Vanskelighetsskala
<!-- Hva endres mellom easy / medium / hard? -->

## Scoring-skisse
<!-- Hvordan beregnes score 0–1000? Hvilke metrikker logges? -->
```

- [ ] **Step 5: Skriv `config.yml`**

```yaml
blank_issues_enabled: false
contact_links:
  - name: Spørsmål eller diskusjon
    url: https://github.com/frodesolem/brainfit-ios/discussions
    about: For spørsmål, ikke bug-rapport eller funksjonsforslag
```

- [ ] **Step 6: Skriv `PULL_REQUEST_TEMPLATE.md`**

```markdown
## Hva endrer denne PR-en

<!-- Kort beskrivelse -->

## Type endring

- [ ] Bug-fiks
- [ ] Ny funksjon
- [ ] Nytt spill
- [ ] Refactor / oppstrømming
- [ ] Dokumentasjon

## Sjekkliste

- [ ] Tester skrevet eller oppdatert
- [ ] `xcodebuild test` passerer lokalt
- [ ] SwiftLint kjørt uten advarsler
- [ ] Tilgjengelighet vurdert (VoiceOver, Dynamic Type)
- [ ] CHANGELOG.md oppdatert (hvis brukervendt endring)

## Skjermbilder / video

<!-- For UI-endringer -->

## Relaterte issues

<!-- Closes #N -->
```

- [ ] **Step 7: Commit**

```bash
git add .github/ISSUE_TEMPLATE .github/PULL_REQUEST_TEMPLATE.md
git commit -m "chore: add issue and PR templates"
```

---

### Task 43: GitHub Actions CI

**Files:**
- Create: `.github/workflows/ci.yml`

- [ ] **Step 1: Skriv `.github/workflows/ci.yml`**

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build-and-test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4

      - name: Velg Xcode 15
        run: sudo xcode-select -s /Applications/Xcode_15.4.app/Contents/Developer

      - name: Installer xcodegen
        run: brew install xcodegen

      - name: Generer Xcode-prosjekt
        run: xcodegen generate

      - name: Bygg
        run: |
          xcodebuild build \
            -project Brainfit.xcodeproj \
            -scheme Brainfit \
            -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
            CODE_SIGNING_ALLOWED=NO | xcpretty
        shell: bash

      - name: Kjør unit-tester
        run: |
          xcodebuild test \
            -project Brainfit.xcodeproj \
            -scheme Brainfit \
            -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
            -only-testing:BrainfitTests \
            CODE_SIGNING_ALLOWED=NO | xcpretty
        shell: bash

      - name: Kjør UI-tester (advarsel kun)
        continue-on-error: true
        run: |
          xcodebuild test \
            -project Brainfit.xcodeproj \
            -scheme Brainfit \
            -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
            -only-testing:BrainfitUITests \
            CODE_SIGNING_ALLOWED=NO | xcpretty
        shell: bash

  swiftlint:
    runs-on: macos-latest
    continue-on-error: true
    steps:
      - uses: actions/checkout@v4
      - name: Installer SwiftLint
        run: brew install swiftlint
      - name: Kjør SwiftLint
        run: swiftlint --strict --config .swiftlint.yml
```

- [ ] **Step 2: Commit**

```bash
git add .github/workflows/ci.yml
git commit -m "ci: add GitHub Actions workflow for build, test, and lint"
```

---

### Task 44: CHANGELOG.md

**Files:**
- Create: `CHANGELOG.md`

- [ ] **Step 1: Skriv CHANGELOG**

```markdown
# Changelog

Alle merkbare endringer dokumenteres her. Følger [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

### Added
- MVP plattform-arkitektur med `Game`-protokoll og `GameRegistry`
- To spill: **Husk Mønsteret** (N-back) og **Riktig Farge** (Stroop)
- Daglig økt-flyt med streak-belønning og 36-timers vindu
- SwiftData-modeller med CloudKit private database for valgfri sync
- Hjem-, Statistikk- og Innstillinger-skjermer
- VoiceOver-støtte og Dynamic Type
- Daglig påminnelse via UNUserNotificationCenter
- Norsk bokmål-lokalisering
- Test-suite for scoring, ViewModels og engine-logikk
- GitHub Actions CI for bygg + tester
- MIT-lisens, CONTRIBUTING, CODE_OF_CONDUCT, ADDING_A_GAME

## [0.1.0] - TBD

- Første offentlige utgivelse
```

- [ ] **Step 2: Commit**

```bash
git add CHANGELOG.md
git commit -m "docs: add CHANGELOG"
```

---

### Task 45: README-badges og GitHub-konfig

- [ ] **Step 1: Oppdater README med badges (etter at repo er pushet til GitHub)**

Erstatt toppen av `README.md` med:

```markdown
# Brainfit

[![CI](https://github.com/frodesolem/brainfit-ios/actions/workflows/ci.yml/badge.svg)](https://github.com/frodesolem/brainfit-ios/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![iOS 17+](https://img.shields.io/badge/iOS-17%2B-blue.svg)](https://developer.apple.com/ios)

Åpen kildekode iOS-app for hjernetrim, inspirert av Lumosity og Elevate.
```

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -m "docs: add CI and license badges to README"
git tag wave-2d-docs-complete
```

---

### Task 46: Sluttverifisering av alle waves

- [ ] **Step 1: Kjør hele testsuiten**

```bash
xcodegen generate
xcodebuild test \
  -project Brainfit.xcodeproj \
  -scheme Brainfit \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest' \
  CODE_SIGNING_ALLOWED=NO 2>&1 | tail -30
```

Expected: alle unit-tester passerer. UI-tester kan flake — det er OK.

- [ ] **Step 2: Verifiser at registry har 2 spill ved app-start**

Bygg og kjør appen manuelt i simulator. Verifiser:
- Hjem-skjerm viser "Start dagens trening"
- Streak-kort viser "0 dager på rad"
- Tab-bar har Hjem, Statistikk, Innstillinger
- Trykk Start → intro for N-back → spill → resultat → intro for Stroop → spill → resultat → sammendrag → tilbake til Hjem
- Etter fullført økt: streak = 1
- Statistikk viser data
- Innstillinger viser "Logget på iCloud" eller "Ikke logget på iCloud"

- [ ] **Step 3: Sluttcommit**

```bash
git tag v0.1.0-mvp
```

---

### Task 47: Push til GitHub (manuell, ikke automatisk)

Når brukeren har opprettet GitHub-repo `frodesolem/brainfit-ios` og lagt til SSH-nøkkel:

- [ ] **Step 1: Legg til remote og push**

```bash
git remote add origin git@github.com:frodesolem/brainfit-ios.git
git push -u origin main
git push --tags
```

- [ ] **Step 2: Aktivér Issues og Discussions i GitHub-settings**

Manuelt via GitHub-UI:
- Settings → Features → Discussions (på)
- Settings → Features → Issues (på)
- Settings → General → Default branch → main

- [ ] **Step 3: Verifiser CI grønn**

Sjekk Actions-fanen. Build- og test-jobben skal være grønn.

---

## Suksesskriterier (fra spec)

Plan-eksekusjon regnes som vellykket når:

1. App kompilerer og kjører på iOS 17-simulator
2. "Start dagens trening" → ende-til-ende-flyt fungerer for begge spill
3. Streak oppdateres korrekt etter fullført økt
4. Statistikk viser snittscore-graf og per-spill-kort
5. iCloud-sync fungerer (testes manuelt mot to enheter)
6. VoiceOver navigerer hovedflyter
7. CI grønn: alle unit-tester passerer
8. README, LICENSE, ADDING_A_GAME, CONTRIBUTING publisert
9. En kontributør kan følge `ADDING_A_GAME.md` og legge til et tredje spill uten core-endring
