# Rijschool Katronic op Mac/Xcode zetten

Gebruik deze stappen op een Mac.

## 1. Project uitpakken

Pak de zip uit en open Terminal in de projectmap.

## 2. Dependencies installeren

```bash
npm install
```

## 3. iOS/Xcode-project maken

```bash
npx expo prebuild -p ios
```

## 4. Openen in Xcode

Open het `.xcworkspace` bestand in de map `ios`.

```bash
open ios/*.xcworkspace
```

## 5. iPhone installeren

In Xcode:

- Sluit de iPhone aan met kabel
- Kies de iPhone als doelapparaat
- Ga naar `Signing & Capabilities`
- Log in met Apple ID
- Kies het juiste Team
- Controleer de bundle identifier, bijvoorbeeld `com.rijschoolkatronic.app`
- Druk op Run

Met een gratis Apple ID verloopt de installatie meestal na ongeveer 7 dagen. Met Apple Developer blijft dit normaal werken via signing/provisioning.
