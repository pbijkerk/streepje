# streepje

Streepjescode lezer — een iOS-app die een boodschappenlijstje opbouwt door product-streepjescodes te scannen.

![iOS build](https://github.com/pbijkerk/streepje/actions/workflows/ios.yml/badge.svg)

## Features

- Scan EAN-8/EAN-13/UPC/CODE-128 streepjescodes met de camera (AVFoundation, geen externe dependencies)
- Productnaam wordt automatisch opgehaald via [Open Food Facts](https://world.openfoodfacts.org); onbekende codes kun je zelf benoemen
- Boodschappenlijst met aantallen, afvinken en lijstopruiming (wis aangevinkte items)
- Lijst wordt lokaal opgeslagen (JSON in de app-container); productnamen worden gecached

## Eisen

- Xcode 16 of nieuwer
- iOS 17+

Open `Streepje.xcodeproj` in Xcode en run op een fysieke iPhone (de simulator heeft geen camera; scannen werkt alleen op een toestel).

## CI

`.github/workflows/ios.yml` bouwt het project bij elke push/PR op een macOS-runner met xcodebuild (iOS Simulator, zonder code signing).

## Data

Productgegevens komen van Open Food Facts (Open Database License).
