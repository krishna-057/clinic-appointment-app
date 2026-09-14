# Clinic Appointment App

A Flutter and Supabase appointment-management prototype for clinic reception
teams. It is being developed as a practical full-stack assignment, with a
particular focus on the staff workflow at
[Clinic Living Plus](https://cliniclivingplus.com/).

> This is an independent demonstration project, not an official Clinic Living
> Plus product. Do not enter real patient or medical data into the demo build.

## Current milestone

The repository contains a working end-to-end appointment workflow:

- Flutter applications for Android and Web
- Supabase initialization through build-time configuration
- PostgreSQL schema and versioned migrations
- Separate patient, doctor, and appointment records
- Seeded doctor and specialization data
- Row Level Security policies for the no-login demo
- Domain models, repository abstraction, and Riverpod ViewModel
- Appointment form with patient name, Indian mobile validation, doctor, date,
  available time, and optional description
- Live appointment list with status, search, filters, and expandable details
- Completed, Cancelled, and Delete actions with confirmation and feedback
- Database-backed persistence across app restarts and page refreshes
- Responsive phone, tablet, and web layout
- Loading, empty, success, retry, validation, and database error states
- Unit-tested scheduling rules and an installable Android APK

## Why this fits Clinic Living Plus

Clinic Living Plus describes a multidisciplinary team of medical experts,
nutrition and wellness professionals, and holistic practitioners. Its public
appointment workflow and recruitment material also indicate that staff handle
incoming enquiries and schedule consultations.

This project models that operating flow as a staff-facing application:

1. Reception staff find or register a patient.
2. They select a practitioner by name and specialization.
3. The application shows only free 30-minute slots.
4. The database prevents two active bookings for the same practitioner and
   time.
5. Staff track appointments as Scheduled, Completed, or Cancelled.
6. Cancelling preserves history while releasing the slot for another patient.
7. Search and filters help staff handle daily call and appointment volume.

The model can later expand beyond doctors to nutritionists, wellness coaches,
and other practitioner types without duplicating appointment logic.

## Scheduling rules

- The clinic operates every day.
- Appointments are 30 minutes long.
- Working hours are 10:00 AM to 5:00 PM.
- 1:00 PM to 2:00 PM is excluded as a lunch break.
- The booking window contains today and the following nine calendar dates.
- Passed slots cannot be booked.
- A practitioner cannot have two Scheduled appointments in the same slot.
- Different practitioners may be booked at the same time.
- Cancelled slots become available again.
- Future appointments cannot be marked Completed.

## Architecture

The project uses a small MVVM-style structure:

```text
Flutter View
    ↓ watches and sends user actions
Riverpod ViewModel
    ↓ calls a stable interface
Appointment Repository
    ↓ sends database requests
Supabase Data API
    ↓
PostgreSQL
```

- **View:** renders loading, error, and data states.
- **ViewModel:** owns shared appointment state and coordinates user actions.
- **Repository:** hides Supabase-specific queries from the UI.
- **Models:** represent patients, doctors, appointments, and statuses.
- **Database:** protects relationships, valid slots, and double-booking rules.

This separation keeps widgets focused on presentation and makes the business
logic easier to test or move behind a custom API later.

## Technology

- Flutter 3.47 / Dart 3.13
- Riverpod for shared asynchronous state and dependency injection
- Supabase Flutter client
- Supabase PostgreSQL
- PostgreSQL constraints, partial indexes, triggers, and RLS
- Material 3 UI

## Database design

```text
patients  1 ──────── * appointments * ──────── 1 doctors
```

Patients and doctors are stored once. An appointment connects them using
foreign keys. This avoids repeating names and contact data in every booking.

The database generates human-friendly references such as `APT-000001`. A
partial unique index reserves a doctor/date/time combination only while an
appointment is Scheduled, allowing a Cancelled slot to be reused.

## Run locally

### Prerequisites

- Flutter stable with Android or Chrome configured
- A Supabase project
- Git

### 1. Clone and install packages

```bash
git clone https://github.com/krishna-057/clinic-appointment-app.git
cd clinic-appointment-app
flutter pub get
```

### 2. Create the database

Open the Supabase SQL Editor and run these files in order:

```text
supabase/migrations/202609140001_initial_schema.sql
supabase/migrations/202609140002_demo_access_policies.sql
```

The first migration creates the schema and sample doctors. The second enables
client access for this no-login demonstration.

### 3. Configure Supabase

Copy the example file:

```bash
cp config/dev.example.json config/dev.json
```

On Windows PowerShell:

```powershell
Copy-Item config/dev.example.json config/dev.json
```

Fill `config/dev.json` using the **Project URL** and **publishable key** from the
Supabase Connect panel:

```json
{
  "SUPABASE_URL": "https://your-project-ref.supabase.co",
  "SUPABASE_PUBLISHABLE_KEY": "sb_publishable_your_key"
}
```

`config/dev.json` is ignored by Git. Never place a Supabase secret key or
service-role key in a Flutter application.

### 4. Run the application

Web:

```bash
flutter run -d chrome --dart-define-from-file=config/dev.json
```

Connected Android device:

```bash
flutter run -d android --dart-define-from-file=config/dev.json
```

### 5. Build an APK

```bash
flutter build apk --release --dart-define-from-file=config/dev.json
```

Flutter writes the APK to:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## Install the APK

1. Download the APK from the repository's
   [Releases page](https://github.com/krishna-057/clinic-appointment-app/releases).
2. Transfer it to an Android device if downloaded elsewhere.
3. Open the APK on the device.
4. Allow installation from that source if Android asks.
5. Install and open **Clinic Appointments**.

The current APK is signed with a development key and is intended only for
review/testing. A production release requires a private release keystore and
secure signing configuration.

## Security note

Version 1 intentionally has no login because the assignment treats the app as
an internal staff tool. Its demo RLS policies therefore permit access through
the public client role. This is **not appropriate for real medical data or an
unrestricted public deployment**.

Before production use:

- add staff authentication;
- restrict RLS policies to authorized clinic users;
- add roles and audit history;
- review health-data consent, retention, and privacy requirements;
- replace development signing with protected release signing.

## Roadmap

- Edit and reschedule using only available slots
- More widget and integration tests
- Optional voice-assisted form filling with staff confirmation
- Staff authentication and production-grade RLS

## AI feature direction

The planned optional AI feature lets reception staff speak a booking request,
for example:

> Book Ramesh with Dr. Priya tomorrow at 11 AM for a fever consultation.

Speech transcription and structured extraction would prefill the form. The
database—not the AI—would determine slot availability, and a staff member would
review and submit the appointment. AI would never create a booking silently.

## Project structure

```text
lib/
  core/config/                       build-time configuration
  features/appointments/
    domain/                          models and scheduling rules
    data/                            repository contract and Supabase adapter
    presentation/providers/         Riverpod ViewModel and providers
    presentation/screens/           Flutter screens
supabase/migrations/                 versioned database changes
config/dev.example.json              safe configuration template
test/                                scheduling unit tests
```

## License and data

This repository is provided as an assessment/demo project. The seeded names are
fictional sample data. Do not store real patient information in the public demo.
