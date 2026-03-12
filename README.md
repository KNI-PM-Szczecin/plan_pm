# PM Schedule

**PM Schedule** is a free, open-source mobile application giving students of the Maritime University of Szczecin (_Politechnika Morska w Szczecinie_) easy access to their class schedules — no login, no paywall, no subscription. Built by students, for students.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)
![Flask](https://img.shields.io/badge/Flask-000000?style=for-the-badge&logo=flask&logoColor=white)
![Selenium](https://img.shields.io/badge/Selenium-43B02A?style=for-the-badge&logo=selenium&logoColor=white)

---

## Screenshots

<p float="left">
  <img src="screenshots/1.png" width="22%" />
  <img src="screenshots/2.png" width="22%" />
  <img src="screenshots/3.png" width="22%" />
  <img src="screenshots/4.png" width="22%" />
</p>

---

## Features

**Currently available**

- View class schedules filtered by your degree programme

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
| `scrapper/` | Scrapes each schedule page using Selenium/Chrome                    |
| `parser/`   | Normalises raw data, deduplicates, extracts teachers/rooms/subjects |
| `json2db/`  | Upserts everything into Supabase                                    |

A separate `structure_updater/` pipeline keeps the university hierarchy (Faculties → Degree Courses → Specialisations) up to date.

The `news_tool/` is a local Flask admin UI for creating and managing news posts shown in the app.

**Tech:** Python, Selenium, BeautifulSoup, Flask, Supabase (PostgreSQL + Storage)

For full backend documentation see [`backend/docs/agent.md`](backend/docs/agent.md).

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
