# TestFlight-deployment

De workflow `.github/workflows/testflight.yml` archiveert de app, tekent hem en uploadt hem naar TestFlight. Die wordt geactiveerd door:

- een tag te pushen: `git tag v1.0.0 && git push origin v1.0.0` (de marketingversie komt uit de tagnaam: `v1.2.3` → `1.2.3`), of
- handmatig via **Actions → TestFlight → Run workflow**.

Zolang de secrets ontbreken, stopt de workflow netjes met een duidelijke foutmelding.

## Eenmalige voorbereiding (ca. 30 min)

### 1. App Store Connect API-sleutel
1. Ga naar [App Store Connect → Users and Access → Integrations → App Store Connect API](https://appstoreconnect.apple.com/access/integrations/api) en maak een sleutel met rol **App Manager** (of **Developer**).
2. Noteer de **Key ID** en het **Issuer ID**.
3. Download het `.p8`-bestand (kan maar één keer!) en encodeer het naar base64:
   ```bash
   base64 -i AuthKey_XXXXXX.p8 | pbcopy
   ```

### 2. App ID (bundle id) registreren
De bundle id `nl.pbijkerk.streepje` moet eerst bestaan als App ID, anders kun je er geen provisioning profile voor maken:

1. Ga naar [developer.apple.com → Certificates, Identifiers & Profiles → Identifiers](https://developer.apple.com/account/resources/identifiers/list).
2. Klik op **+** → kies **App IDs** → **App** → **Continue**.
3. Vul in:
   - **Description**: `Streepje`
   - **Bundle ID**: kies **Explicit** en vul `nl.pbijkerk.streepje` in
4. Vink onder **Capabilities** niets extra's aan (Streepje heeft geen speciale capabilities) en klik **Register**.

Let op: gebruik je liever een andere bundle id, pas dan ook `PRODUCT_BUNDLE_IDENTIFIER` in `project.yml` én het provisioning profile in `.github/workflows/testflight.yml` aan.

### 3. Distributie-certificaat
1. In Xcode: **Settings → Accounts → je team → Manage Certificates → +** en kies **Apple Distribution** (of maak 'm via developer.apple.com).
2. Exporteer het certificaat uit de Sleutelhouder als `.p12` (instellingen: wachtwoord kies je zelf) en encodeer:
   ```bash
   base64 -i certificate.p12 | pbcopy
   ```

### 4. Provisioning profile (App Store)
1. Ga naar [developer.apple.com → Certificates, Identifiers & Profiles → Profiles](https://developer.apple.com/account/resources/profiles/list) en maak een **App Store**-provisioning profile voor de App ID `nl.pbijkerk.streepje` (uit stap 2).
2. Download het en encodeer naar base64:
   ```bash
   base64 -i Streepje_AppStore.mobileprovision | pbcopy
   ```

### 5. App aanmaken in App Store Connect
De TestFlight-upload vindt alleen een thuis als er een app-record bestaat:

1. Ga naar [App Store Connect → My Apps](https://appstoreconnect.apple.com/apps) en klik op **+** → **New App**.
2. Vul in: **Name** — dit is de naam in de App Store en moet **uniek** zijn; `Streepje` is bezet. Voorgestelde naam: `Pluk` (bij controle in nov. 2025 nog niet in gebruik; Apple valideert de uniekheid definitief op dit punt). Mocht die tussentijds bezet zijn, kies dan bijv. `Pluk Boodschappen` of `Streepje Lijstje`. **Primary Language** Nederlands, **Bundle ID** `nl.pbijkerk.streepje` (uit stap 2), **SKU** bijv. `streepje`.
3. De naam die gebruikers onder het app-icoontje zien (op het thuisscherm) is onafhankelijk hiervan en blijft gewoon `Streepje` — die hoeft niet uniek te zijn.

### 6. Secrets instellen
Zet in **GitHub → Settings → Secrets and variables → Actions** (delen van deze waarden nooit hier in de chat):

| Secret | Waarde |
|---|---|
| `ASC_KEY_ID` | Key ID van de API-sleutel (10 tekens) |
| `ASC_ISSUER_ID` | Issuer ID (UUID) |
| `ASC_KEY_P8_BASE64` | Base64 van het `.p8`-bestand |
| `BUILD_CERT_P12_BASE64` | Base64 van het `.p12`-certificaat |
| `BUILD_CERT_PASSWORD` | Het wachtwoord van het `.p12`-bestand |
| `BUILD_PROVISION_PROFILE_BASE64` | Base64 van het provisioning profile |
| `PROVISIONING_PROFILE_SPECIFIER` | De **naam** van het profile (bijv. `Streepje App Store`) |
| `DEVELOPMENT_TEAM_ID` | Je 10-tekens Team ID (developer.apple.com → Membership) |

## Daarna

Elke tag-push levert automatisch een TestFlight-build af. Gebruik per release een **nieuwe** tagnaam (`v0.1.2`, `v0.1.3`, …): een verwijderde en opnieuw gepushte tag met dezelfde naam/commit triegert géén nieuwe workflow-run. De allereerste build moet je in App Store Connect even vrijgeven aan jezelf via **TestFlight → Builds → Testers**.

Voor nieuwe versies: verhoog de marketingversie niet handmatig — de workflow haalt die automatisch uit de tagnaam. Het buildnummer neemt automatisch toe (gelijk aan het nummer van de Actions-run), dus elke tag-push hoeft niets te houden van het vorige.

Opmerking: Apple stuurt soms een ITMS-90725-e-mail ("SDK version issue") als informatieve waarschuwing over toekomstige SDK-vereisen — dat is geen afkeuring en de build werkt gewoon in TestFlight.

De build werkt met Xcode 26 (iOS 26 SDK, verplicht voor App Store-uploads); de workflow draait op de `macos-26`-runner — die kan druk zijn, dus een langere queue is normaal.

## TestFlight-troubleshooting: "build verschijnt niet"

De upload via `altool` is geslaagd, maar de build is nog niet zichtbaar voor testers. Loop deze checklist na:

1. **Verwerkingstijd**: Apple heeft na een geslaagde upload doorgaans 2–10 minuten nodig (soms langer). Controleer **App Store Connect → Mijn apps → Pluk → TestFlight-tab → iOS → versie 1.0**: daar staan álle builds met hun status (In behandeling / Klaar om te testen / Ontbrekende conformiteit).
2. **E-mail van App Store Connect**: Apple mailt na verwerking óf een bevestiging ("App Store Connect: ...is ready for testing") óf problemen. Geen mail en na een uur nog niets in ASC → zoek het Apple ID-wachtwoord-/ASC-probleem in de workflowlog.
3. **"Missing Compliance" (ontbrekende exportconformiteit)**: de build staat dan wél in de lijst maar is niet "Ready to Test". Klik op de build → **Compliance** → beantwoord de encryptievraag met "Nee" (de app gebruikt alleen standaard HTTPS) → opslaan. Vanaf de volgende build zit `ITSAppUsesNonExemptEncryption: false` in de app zelf (zie `project.yml`), waardoor deze vraag niet meer komt.
4. **Testers**: zelfs een "Ready to Test"-build verschijnt alleen in de TestFlight-app bij testers die in een groep zitten waaraan de build is gekoppeld. Nieuwe builds hangen automatisch aan de groepen van dezelfde app-versie; controleer anders **TestFlight → groep → +** naast de build.
5. **Goede plek om te kijken**: de **web-ASC** (appstoreconnect.apple.com) is duidelijker dan de TestFlight-app zelf — de TestFlight-app toont alleen "Ready to Test"-builds.

## Fase 5: iCloud-sync (eenmalige instellingen)

De app zoekt bij het starten de CloudKit-container `iCloud.nl.pbijkerk.streepje`. Zolang de onderstaande stappen niet gedaan zijn, valt de app netjes terug op lokale opslag (niets crasht), maar er synchroniseert niets.

1. **iCloud-capability op het App ID**: developer.apple.com → Certificates, IDs & Profiles → Identifiers → `nl.pbijkerk.streepje` → Capability **iCloud** aanvinken (inclusief **CloudKit**) en container `iCloud.nl.pbijkerk.streepje` aanmaken/koppelen. Push notifications (aps) meestand laten.
2. **Provisioning profile opnieuw genereren**: het bestaande App Store-profile bevat de iCloud-capability niet. Maak het profile opnieuw aan (of bewerkt het zodat iCloud erin zit), download het, en zet de base64 in het secret `BUILD_PROVISION_PROFILE_BASE64` (vervang de waarde). Zonder deze stap faalt de TestFlight-upload met een entitlement-mismatch.
3. **CloudKit-container** verschijnt automatisch in de CloudKit Console zodra de eerste build met de entitlement draait.
4. **Testen**: log op twee apparaten (of simulator + toestel) in met hetzelfde Apple ID; nieuwe voorraadproducten verschijnen vanzelf op het andere apparaat (kan enkele seconden tot minuten duren; bij de eerste sync ook een paar minuten).

Let op: met CloudKit verviel het `.unique`-attribuut op de barcode. Dubbele producten worden in de app zelf voorkomen (check vóór het inserten); mocht er via sync ooit een dubbel ontstaan, dan worden ze naast elkaar getoond — geen dataverlies.

## Fase 5b: provisioning voor de widget + vernieuwd app-profile

De TestFlight-upload faalt totdat dit klaar is (de app heeft nu iCloud- en push-entitlements, en de widget-extensie heeft een eigen provisioning profile nodig):

1. **App ID bijwerken**: developer.apple.com → Identifiers → `nl.pbijkerk.streepje` → vink aan: **iCloud (CloudKit, container `iCloud.nl.pbijkerk.streepje`)** én **Push Notifications** (CloudKit gebruikt stille pushes voor snelle sync).
2. **Widget App ID aanmaken**: Identifiers → **+** → App IDs → App → beschrijving "Streepje Widgets", **Explicit** Bundle ID: `nl.pbijkerk.streepje.widgets`. Extra capabilities niet nodig.
3. **App-provisioning profile vernieuwen**: Profiles → het bestaande App Store-profile → **Edit** → opnieuw genereren → downloaden → base64 → vervang secret `BUILD_PROVISION_PROFILE_BASE64`.
4. **Widget-provisioning profile aanmaken**: Profiles → **+** → App Store Connect → App ID `nl.pbijkerk.streepje.widgets` → certificaat Apple Distribution → naam bijv. `Streepje Widgets App Store` → downloaden → base64 → zet in **twee nieuwe secrets**:
   - `WIDGET_PROVISION_PROFILE_BASE64` (de base64 van het profile)
   - `WIDGET_PROVISION_PROFILE_SPECIFIER` (de **naam**, bijv. `Streepje Widgets App Store`)
5. De workflow installeert beide profiles en koppelt ze per target via build settings (`APP_PP_SPECIFIER` / `WIDGET_PP_SPECIFIER`, alleen Release).

Base64 maken:
```bash
base64 -i ~/Downloads/naam.mobileprovision | pbcopy
```
