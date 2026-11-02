---
name: monitoring-project
description: Use when working in the Geoterra Monitoring Flutter web project (geoterra_monitoring) — editing lib/ Dart screens, models, providers, services, widgets, or the Express server.js host. Covers project layout, run/build commands, state conventions, and where features belong.
---

# Geoterra Monitoring Project

Flutter web app (`geoterra_monitoring`) for field monitoring (projects, offerings, workers, tools, timelines), served by a small Express static host. Material Design, no codegen.

## Layout

| Path | Contents |
| --- | --- |
| `lib/main.dart` | App entry, provider wiring |
| `lib/router/app_router.dart` | `go_router` route table |
| `lib/models/` | Plain Dart models (`project`, `offering`, `payment`, `worker`, `tool_asset`, `timeline`, ...) |
| `lib/providers/` | `ChangeNotifier` state (`auth`, `project`, `worker`, `timeline`) |
| `lib/screens/` | Full pages (list/detail/form per entity, `login_screen`) |
| `lib/widgets/` | Reusable UI (`stat_card`, `status_chip`, `offering_map*`, `app_nav_bar`) |
| `lib/services/` | Data + IO: `mock_data.dart`, `schema_*.dart`, `invoice_pdf.dart`, CSV/invoice download (web/io split files), `geocoding_service.dart`, `error_logger.dart` |
| `lib/utils/` | `currency`, `rich_text*`, `offering_line_items`, `status_extensions` |
| `lib/theme/app_theme.dart` | Theme |
| `server.js` | Express static host for `build/web` + `POST /api/log` |

## Conventions

- State: `provider` + `ChangeNotifier`; consume with `context.watch` / `Consumer`. Widgets live in `widgets/`, screens only compose them.
- Navigation: `go_router` in `app_router.dart` — add routes there, not `Navigator.push`.
- Data source: currently mock data in `lib/services/mock_data.dart` and `schema_mock_data.dart`; swap there rather than in widgets.
- Platform-conditional files: `*_web.dart` / `*_io.dart` / `*_stub.dart` pairs with a `*.dart` conditional-import facade (`invoice_download.dart`, `csv_download.dart`). Keep the facade signature when adding platforms.
- State text/colors go through `utils/status_extensions.dart` and `widgets/status_chip.dart`, not inline.
- Formatting: `dart format`. Lints: `flutter_lints` via `analysis_options.yaml`.
- Do NOT bump `image` / `proj4dart` past the pinned versions in `pubspec.yaml` — comments explain the `pdf`/`archive` and `flutter_map` constraints.

## Commands

```powershell
flutter pub get
flutter analyze
dart format lib
flutter test
flutter run -d chrome
```

```powershell
npm install
npm run build      # flutter build web --release
npm start          # node server.js  (serves build/web on :8080)
npm run deploy     # build + start
```

`server.js` exits if `build/web/index.html` is missing — run `flutter build web` first.

## Error logging

Client errors POST to `/api/log` via `lib/services/error_logger.dart`; the server prints them as `[CLIENT ERROR]`. Use that instead of `print` for runtime failures.
