# MFU Student Assignment Tracking System (Flutter app)

Mobile/web front end for the group project **MFU Student Assignment Tracking System**.
A project coordinator (PC) creates group projects and assigns tasks; members update status, submit work and comment.

## Status

- **Partly connected to the API.** Register, login, profile, creating projects and adding/removing members call the backend (`lib/controller/api_controller.dart`, base URL `http://localhost:3000/api`, so a backend must be running to sign in).
- Everything else (project lists, tasks, comments, notifications) still runs on **mock data** in `lib/data/workspace_store.dart`.
- Data shapes follow the project database (`mfu_student_assignment_tracking`):
  - Roles are per project and have two values: `PC` and `MEMBER`.
  - Every comment has its own `id`, author student id and creation time.
  - Users can delete only their own comments and notifications.
  - A task keeps `submittedAt` and `completedAt`.

## Run

```
cd mfu_student_workspace
flutter pub get
flutter run
```

Sign in with the pre-filled account on the login screen to see the demo data.

## Test

```
flutter analyze
flutter test
```

## Folders (`lib/`)

| Folder | Purpose |
| :-- | :-- |
| `models/` | Data classes: project, task, comment, team member, notification |
| `data/` | `WorkspaceStore` mock data and rules (notifications, delete, deadlines) |
| `screens/` | Login/register, dashboard, project, task, notifications, profile |
| `app/`, `navigation/` | App setup and navigation |
| `core/` | Colors (`constants/`) and helpers (`utils/`: status, deadline, date picker) |
| `widgets/` | Shared widgets |
