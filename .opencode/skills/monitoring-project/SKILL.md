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
| `lib/models/` | Plain Dart models (`project`, `offering`, `payment`, `worker`, `tool_asset`, `rental_tool`, `timeline`, ...) |
| `lib/providers/` | `ChangeNotifier` state (`auth`, `project`, `worker`, `timeline`) |
| `lib/screens/` | Full pages (list/detail/form per entity, `login_screen`) |
| `lib/widgets/` | Reusable UI (`stat_card`, `status_chip`, `offering_map*`, `app_nav_bar`) |
| `lib/services/` | Data + IO: `mock_data.dart`, `schema_*.dart`, `invoice_pdf.dart` (shared invoice), `invoice_rental_pdf.dart` (Rent Tool invoice), CSV/invoice download (web/io split files), `geocoding_service.dart`, `error_logger.dart` |
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

## Rental flow (Rent Tool)

Data model — `lib/models/rental_tool.dart`:
- `RentalTool` — catalog entry (`id`, `name`, `description`, `category`, `unit`, `rentalRate` per day, `stock`). The bundled catalog is `rentalToolCatalog`.
- `RentalOfferingItem` — immutable per-line snapshot: `tool`, `quantity`, `duration` (days), `startsAt`, `rate` (captured at save time). Derives `endsAt` (`startsAt + duration - 1`) and `total` (`quantity * duration * rate`).
- `Offering.rentalItems` (not `lineItems`) carries these rows. For offerings whose `serviceType` starts with "rent", the constructor recomputes `budgetAmount` from the rental total; `toJson`/`fromJson` round-trip `rentalItems`.

UI — `offering_form_screen.dart`:
- When `_isRentalService`, the line-item editor is replaced by a rental-items card (add/edit/remove) backed by a catalog dropdown. Start date defaults from `rentalUntil`.
- `tools_view.dart` shows the catalog below the equipment grid.

Invoice — **do not edit `invoice_pdf.dart` for rentals**. Rental offerings branch in `offering_detail_screen.dart` (`offering.isRentalService`) to `lib/services/invoice_rental_pdf.dart` → `buildRentalInvoicePdf(...)`. All other service types keep using `buildOfferingInvoicePdf(...)` in `invoice_pdf.dart`, unchanged.
- `buildRentalInvoicePdf` takes `clientName`, `invoiceNumber`, `issuedAt`, bank fields — the detail screen supplies them from `ClientDirectory`; nothing is hard-coded to sample data.
- Layout is measured from `lib/assets/invoice_mockup_rent_tool_only.pdf` (A4 595.5×842, content x≈48.8–550.8): centered `INVOICE` / `Tagihan Sewa Alat` title, two-row info panels (Nomor Invoice | Periode Sewa, Penerbit Invoice | Terhitung), six-column table `No. | Uraian Sewa | Kuantitas | Satuan | Harga Perbulan | Jumlah` with an orange `#f5821f` header and `#9fb4cc` grid, right-aligned recap (Subtotal / PPN 11% / PPh 2%), `Terbilang:` line, payment info, signature, and the vector wordmark + footer band.
- Money format differs by section on purpose: table rows use `Rp. 5,500,000` (comma groups); recap uses `Rp 5.500.000` (dot groups) — matching the reference.

Tests: `rental_tool_test.dart` (model/JSON), `offering_rental_items_test.dart` (round-trip + budget), `rental_invoice_test.dart` (PDF builds; per-item rates change output size). Form validation enforces positive quantity/duration and ≥1 rental item.

Known limitations: the PDF uses core Helvetica (the reference uses Arial/Tahoma) because no font asset is bundled; the table column is labelled "Harga Perbulan" (monthly) per the reference while `RentalTool.rentalRate` is stored per day — reconcile the rate unit before treating figures as monthly vs daily.
