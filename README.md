# PayLater Tracker (Flutter)

A clean, mobile-first bill tracker for SPayLater-style installment plans, built with Flutter.

## Features

- **Home / Dashboard** — big Total Unpaid Balance card (with show/hide toggle), summary cards, and detailed "Upcoming Bills" cards with an inline "Add saving" field.
- **Bills** — compact list of every bill and its month-by-month installment breakdown.
- **Add New Bill** — Monthly Payment, Installment Months (1/3/6/12), auto-calculated Total Bill, Due Date picker, and optional Initial Saved amount.
- **Calendar** — chronological list of every installment's due date across all bills.

## Core payment logic (`lib/providers/bill_provider.dart`)

- Each `Bill` is split into N `Installment`s (one per month), starting from the **Due Date** entered when the bill was created.
- Adding a saving amount via `BillProvider.addSaving()`:
  1. Adds the amount to the current (active) installment's `saved` total.
  2. If `saved >= monthlyPayment`, the installment is capped and marked **Paid**.
  3. The **next** installment automatically becomes **Unpaid/active** (e.g. Month 1 of 3 → Month 2 of 3).
  4. `Bill.totalUnpaidBalance` (Total Bill − paid installments × monthly payment) recalculates automatically, which flows straight into the Home screen's **Total Unpaid Balance** card since it's driven by `ChangeNotifier`.
- Users can add savings multiple times before the installment is fully paid — each call just adds to the running `saved` total.

## Getting started

```bash
flutter pub get
flutter run
```

Requires Flutter 3.x+ (Dart SDK ^3.0.0). Dependencies: `provider`, `intl`.

## Project structure

```
lib/
  main.dart                 # App entry point (loads saved data at startup)
  theme/app_theme.dart       # Colors & ThemeData
  models/bill.dart           # Bill + Installment data models & derived getters
  providers/bill_provider.dart  # ChangeNotifier: add bill, add saving, auto-advance logic
  screens/
    main_screen.dart         # Bottom nav (Home / Bills / Calendar)
    home_screen.dart         # Dashboard
    bills_screen.dart        # Full bill + installment list
    add_bill_screen.dart     # New bill form
    calendar_screen.dart     # Due-date list
  widgets/
    bill_detail_card.dart    # Interactive card w/ "Add saving" + "+ Add"
    status_badge.dart        # Paid / Unpaid / Pending / In Progress pill
```

## Notes / customization ideas

- The app starts completely empty on a fresh install — no sample/demo data. You add your first bill from the Home screen.
- **Data is saved locally** using `shared_preferences` (JSON under the hood) — bills, history, and the transaction log all survive closing/reopening the app or restarting the phone. Nothing leaves the device and no account is required. If you outgrow this later (e.g. want multi-device sync), swap the storage layer in `BillProvider` for a proper local DB (`sqflite`, `hive`) or a backend, without touching the UI code.
- Currency formatting uses `intl`'s `en_PH` locale with a `₱` symbol.
