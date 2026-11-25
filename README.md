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

- **`.github/workflows/ios.yml`** — bouwt en test bij elke push/PR op een macOS-runner (build voor iOS Simulator, daarna unit-tests op een iPhone 16-simulator, zonder code signing).
- **`.github/workflows/testflight.yml`** — archiveert, tekent en uploadt naar TestFlight bij een `v*`-tag. Vereist eenmalig secrets; zie [DEPLOY.md](DEPLOY.md).

## Data

Productgegevens komen van Open Food Facts (Open Database License).
