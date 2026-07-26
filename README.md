# PM Schedule

**PM Schedule** is a free, open-source mobile application giving students of the Maritime University of Szczecin (_Politechnika Morska w Szczecinie_) easy access to their class schedules — no login, no paywall, no subscription. Built by students, for students.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)
![Flask](https://img.shields.io/badge/Flask-000000?style=for-the-badge&logo=flask&logoColor=white)

---

## Screenshots

### iOS

<table>
  <tr>
    <td><img src="docs/pr-assets/liquid-glass/ios-01.png" width="220" /></td>
    <td><img src="docs/pr-assets/liquid-glass/ios-02.png" width="220" /></td>
    <td><img src="docs/pr-assets/liquid-glass/ios-03.png" width="220" /></td>
    <td><img src="docs/pr-assets/liquid-glass/ios-04.png" width="220" /></td>
  </tr>
  <tr>
    <td><img src="docs/pr-assets/liquid-glass/ios-05.png" width="220" /></td>
    <td><img src="docs/pr-assets/liquid-glass/ios-06.png" width="220" /></td>
    <td><img src="docs/pr-assets/liquid-glass/ios-07.png" width="220" /></td>
    <td><img src="docs/pr-assets/liquid-glass/ios-08.png" width="220" /></td>
  </tr>
</table>

### Android

<table>
  <tr>
    <td><img src="docs/pr-assets/liquid-glass/android-01.png" width="220" /></td>
    <td><img src="docs/pr-assets/liquid-glass/android-02.png" width="220" /></td>
    <td><img src="docs/pr-assets/liquid-glass/android-03.png" width="220" /></td>
    <td><img src="docs/pr-assets/liquid-glass/android-04.png" width="220" /></td>
  </tr>
  <tr>
    <td><img src="docs/pr-assets/liquid-glass/android-05.png" width="220" /></td>
    <td><img src="docs/pr-assets/liquid-glass/android-06.png" width="220" /></td>
    <td><img src="docs/pr-assets/liquid-glass/android-07.png" width="220" /></td>
    <td><img src="docs/pr-assets/liquid-glass/android-08.png" width="220" /></td>
  </tr>
  <tr>
    <td><img src="docs/pr-assets/liquid-glass/android-09.png" width="220" /></td>
    <td><img src="docs/pr-assets/liquid-glass/android-10.png" width="220" /></td>
    <td></td>
    <td></td>
  </tr>
</table>

---

## Features

**Currently available**

- View class schedules filtered by your degree programme (daily and weekly views)
- Lecturer mode — browse your own teaching schedule
- News feed with university announcements
- Native home screen widgets (iOS WidgetKit + Android, three sizes)
- Three languages (Polish, English, Ukrainian), light/dark themes, accent colors

**Planned**

- Push notifications for schedule changes and announcements
- Campus map and navigation
- Grades and academic progress
- Integration with university communication systems
- Secure login with university credentials

---

## Project Structure

The project is split into two parts:

### Frontend — [`frontend/`](frontend/)

A Flutter application targeting Android and iOS. Fetches schedule data from Supabase and presents it in a clean, fast mobile UI.

**Tech:** Flutter (Dart), Supabase client

### Backend — [`backend/`](backend/)

A Python data pipeline that scrapes the university's Virtual Dean's Office website and loads the data into a Supabase database. Also includes a lightweight admin tool for managing in-app news posts.

**Pipeline:**

```
Mapper → Scrapper → Parser → json2db
```

| Step        | What it does                                                        |
| ----------- | ------------------------------------------------------------------- |
| `mapper/`   | Discovers active schedule IDs via HTTP                              |
| `scrapper/` | Scrapes each schedule page via HTTP POST                            |
| `parser/`   | Normalises raw data, deduplicates, extracts teachers/rooms/subjects |
| `json2db/`  | Upserts everything into Supabase                                    |

A separate `structure_updater/` pipeline keeps the university hierarchy (Faculties → Degree Courses → Specialisations) up to date.

The `admin/` package is a local Flask admin panel (news management, pipeline runner with live logs, store stats, environment switching), and `mcp_server/` exposes the backend as MCP tools for AI agents.

**Tech:** Python, BeautifulSoup, Flask, Supabase (PostgreSQL + Storage)

For full backend documentation see [`backend/README.md`](backend/README.md) and the root [`CLAUDE.md`](CLAUDE.md).

---

## Database Access

If you need access to the Supabase project, reach out on Discord: **schoji**

---

## Contributing

Contributions are welcome — bug reports, feature requests, pull requests, translations, everything. This project belongs to the community.

Open an issue or a PR and let's talk.

---

## License

This project is licensed under the **Creative Commons Attribution-NonCommercial 4.0 International (CC BY-NC 4.0)** license.

**In plain words:**

- You are free to use, share, and adapt this project
- You must give appropriate credit to the original authors
- **Commercial use is not permitted**
- This project is and will always remain free — no paywalls, no subscriptions, no monetisation

See the full license at [creativecommons.org/licenses/by-nc/4.0](https://creativecommons.org/licenses/by-nc/4.0/).

---

_From students, for students. Free forever._
