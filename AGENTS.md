# AGENTS.md

Guidance for AI coding agents working in this repository.

## What this is

**Geoterra Monitoring** — a Flutter app for a land-surveying company (PT Geoterra Indonesia). It manages the sales-to-execution flow: offerings (proposals) → accepted offering → project, plus clients, workers, equipment, a field-team timeline, payments, and invoice PDFs.

- UI language: English labels, Indonesian currency (`Rp`) and invoice content.
- Primary target: **Flutter web** (`android/` and `ios/` also exist; no desktop folders).
- Current branch: `landgis-database-schema` (default branch is `main`).

## Commands

```bash
flutter pub get
flutter run -d chrome          # develop in the browser
flutter analyze                # must pass before committing
flutter test                   # unit + widget tests
flutter build web --release    # production web bundle -> build/web
node server.js                 # serve build/web at http://localhost:8080
npm start                      # same as node server.js
npm run deploy                 # build web + serve
```

## Architecture

```
lib/
  main.dart              # providers + MaterialApp.router bootstrap
  router/app_router.dart # all routes (go_router, auth redirect)
  theme/app_theme.dart   # AppColors + Material 3 light theme
  models/                # plain Dart models (fromJson/toJson, enums)
  providers/             # ChangeNotifier state (provider package)
  screens/               # pages + forms (most UI lives here)
  widgets/               # shared UI (nav bar, cards, map, chips…)
  services/              # mock data, PDF, geocoding, clients, rules
  utils/                 # currency, status labels/colors, rich text
  assets/                # invoice logo + schema documentation
```

### State & data flow

- `provider` + `ChangeNotifier` only; no Riverpod/BLoC.
- Providers are wired in `main.dart`:
  - `AuthProvider` — mock login, session persisted in `shared_preferences` (`auth_user`).
  - `ProjectProvider` — offerings, projects, activity feed.
  - `WorkerProvider` — field-team directory.
  - `TimelineProvider` — Gantt rows/tasks; synced from `WorkerProvider` via `ChangeNotifierProxyProvider`.
- **There is no real backend.** All data comes from `MockData` (`lib/services/mock_data.dart`) and `SchemaMockData` (`lib/services/schema_mock_data.dart`). Mutations are in-memory and reset on reload.
- `lib/services/api_service.dart` is a legacy/unused REST client pointing at `http://localhost:3000/api`; don't assume it is wired in.
- Loading pattern: call `ensureProjectsLoaded()` / `ensureWorkersLoaded()` from `initState` (post-frame) or build; reload methods merge new mock rows under local edits (`_merge*`, local records win).

### Routing (`lib/router/app_router.dart`)

- `/login`, `/dashboard`, `/offerings`, `/tools`, `/workers`, `/timeline` are the bottom-nav branches (`StatefulShellRoute.indexedStack`).
- Details/forms: `/offerings/new`, `/offerings/:id` (`?tab=0..3`), `/offerings/:id/edit`, `/offerings/:id/project/new`, `/projects/:id`, `/projects/:id/edit`, `/workers/new`, `/workers/:id/edit`.
- Use the `AppRouter.offeringDetail()` / `offeringEdit()` / `projectDetail()` helpers instead of hand-building paths.
- Redirect sends unauthenticated users to `/login`.
- When adding a tab, update both `app_router.dart` and the `sections` list in `DashboardShell` (`lib/screens/dashboard_shell.dart`).

### Core domain rules

- An **Offering** (`OfferingStatus`: draft/sent/accepted/rejected/expired) becomes a **Project** only once accepted. `Offering.projectId` is the link; `Project.offeringId` is the inverse.
- **Rent Tool** offerings (`serviceType` starts with "rent") never create projects; they use `rentalUntil`.
- **Calibrate Service** offerings do not need coordinates (`isCalibrationService`).
- Offering totals: line items form a hierarchy (`indent` 0–2, `excludeFromTotal`, nested rows roll up) — see `lib/utils/offering_line_items.dart` and `Offering._lineItemsTotal`.
- Payment: `Offering.amountPaid` vs `budgetAmount`; `PaidStatus` is unpaid/partiallyPaid/paid. Payment records (`Payment`) carry method, date, invoice number, proof file.
- **Offering terms** (`OfferingTerm`) are payment milestones (name, percentage, amount) used for termin invoices.
- Worker assignment limits (`lib/services/assignment_rules.dart`): CAD unlimited; field in office max 2 active projects; field out of town max 1. Only non-completed/cancelled projects count.

### Key services

- `invoice_pdf.dart` — builds the invoice PDF with the `pdf` package; uses `lib/assets/invoice_logo.png` (declared in `pubspec.yaml`) and reads client/bank data from `ClientDirectory`. Entry point: `buildOfferingInvoicePdf(...)`.
- `invoice_download.dart` — conditional import (`_io` / `_web`) for saving the PDF.
- `geocoding_service.dart` — native geocoder on mobile, OpenStreetMap Nominatim on web.
- `client_directory.dart` — clients read from `SchemaMockData.rows('clients')`; in-memory `add()` for new clients.
- `schema_data.dart` / `schema_mock_data.dart` — LandGIS table schema and positional dummy rows; documented in `lib/assets/landgis_database_schema (1).md`.
- `error_logger.dart` — installs global Flutter error handlers and POSTs to `/api/log`.

### Web hosting

`server.js` is an Express static server for `build/web` (port 8080, SPA fallback to `index.html`, no-cache headers) and exposes `POST /api/log` for `ErrorLogger`. Keep the client log endpoint and this route in sync. `serve.json` holds equivalent cache headers for other static hosts.

## Conventions

- Follow the existing style: 2-space indent, single quotes, trailing commas, `const` constructors, private widget classes per screen.
- Colors come from `AppColors` / `AppTheme`; don't hardcode palette values in screens.
- Status labels/colors/icons come from `lib/utils/status_extensions.dart` — extend the enums there rather than duplicating switches.
- Money formatting: `formatRupiah` / `formatRupiahInput` / `parseRupiah` / `RupiahInputFormatter` in `lib/utils/currency.dart`.
- Models are immutable with `fromJson`/`toJson`; add `copyWith` when callers need partial updates (see `Project`). Keep JSON keys camelCase, enums serialized as strings.
- Heavy screens are already large (e.g. `offering_detail_screen.dart` ~100 KB, `offerings_page.dart` ~90 KB). Make focused edits; don't reformat whole files.
- `analysis_options.yaml` uses `flutter_lints`; keep `flutter analyze` clean.

## Testing

Tests live in `test/` and cover: auth/login, activity feed, assignment rules, client directory, currency, invoice PDF, rental offerings, payments, providers, rich text, timeline. Add or update a test when changing business rules, serialization, or PDF output. Run `flutter test` before finishing.

## Gotchas

- Data is all mock/in-memory; refreshing the app loses creates/edits. Don't "fix" this unless the task asks for persistence/API integration.
- `ProjectProvider.fetchProjects()` merges mock data with local state (local wins by id); preserve that behavior when touching reload logic.
- Only `lib/assets/invoice_logo.png` is declared under `pubspec.yaml` assets — other files in `lib/assets/` are reference material and not bundled.
- `image` is pinned to `4.5.4` and `proj4dart` to `3.0.0` because of `pdf`/`flutter_map` constraints; upgrade them together and re-run tests.
- The repo contains a stray `nul` file (Windows artifact) and build output folders; don't commit generated files.
