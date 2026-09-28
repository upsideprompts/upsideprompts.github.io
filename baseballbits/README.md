# Baseball Bits

Dart-first Flutter web app. UI and logic live in `lib/` (`main.dart`).  
`index.html` only boots Flutter — no app JavaScript.

## Run locally

```bash
cd baseballbits
flutter pub get
flutter run -d chrome
```

## Build for GitHub Pages (`/baseballbits/`)

```bash
flutter build web --base-href /baseballbits/
./deploy_web.sh
```

Then commit and push the updated build files on `gh-pages`.

Live URL: https://upsideprompts.github.io/baseballbits/
