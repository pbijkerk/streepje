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

### 2. Distributie-certificaat
1. In Xcode: **Settings → Accounts → je team → Manage Certificates → +** en kies **Apple Distribution** (of maak 'm via developer.apple.com).
2. Exporteer het certificaat uit de Sleutelhouder als `.p12` (instellingen: wachtwoord kies je zelf) en encodeer:
   ```bash
   base64 -i certificate.p12 | pbcopy
   ```

### 3. Provisioning profile (App Store)
1. Ga naar [developer.apple.com → Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/profiles/list) en maak een **App Store**-provisioning profile voor de bundle id `nl.pbijkerk.streepje`.
2. Download het en decodeer naar base64:
   ```bash
   base64 -i Streepje_AppStore.mobileprovision | pbcopy
   ```

### 4. Secrets instellen
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

Elke tag-push levert automatisch een TestFlight-build af. De allereerste build moet je in App Store Connect even vrijgeven aan jezelf via **TestFlight → Builds → Testers**.
