<img width="1600" height="900" alt="image" src="https://github.com/user-attachments/assets/844b44a6-6835-4f3b-b606-a30ae4e2e18d" /># CP Companion

**A decoupled full-stack application built for competitive programmers to track global contests and manage C++ algorithmic templates.**

As an active competitive programmer, I was tired of checking five different websites to see upcoming contests and constantly losing my C++ templates in random text files. I built **CP Companion** to solve this. It serves as a centralized dashboard that aggregates live data from major CP platforms and includes a local database for snippet management.

## Features

* **Global Contest Aggregator:** Fetches and normalizes upcoming contest data concurrently from Codeforces, LeetCode, HackerRank, AtCoder, and CodeChef.
* **Fault-Tolerant Architecture:** Implements a custom fallback mechanism. If the primary third-party aggregator times out, the backend seamlessly intercepts the failure and directly routes requests to official APIs to ensure continuous uptime.
* **The Snippet Vault:** A local SQLite-backed persistent storage system to save, tag, and retrieve C++ templates (like Graph algorithms or standard setups).
* **Premium UI/UX:** Built natively with Flutter, featuring state-managed Light/Dark mode toggling, custom platform branding, and pull-to-refresh data visualization.

## Sneak Peek

> **Note:** Here is what the app looks like running locally! 
>  <img width="800" alt="image1" src="https://github.com/user-attachments/assets/9bf822a4-2bf3-48f6-9373-7d64e3218da1" />
> <img width="800" alt="image2" src="https://github.com/user-attachments/assets/b0a31edb-6d1c-4350-a3cb-0f87e7c23a44" />




## Tech Stack

**Frontend (The Face):**
* **Framework:** Flutter (Dart)
* **State Management:** `ValueNotifier` for real-time dynamic theming
* **Networking:** Async HTTP requests

**Backend (The Brain):**
* **Framework:** FastAPI (Python)
* **API Architecture:** REST and GraphQL integration
* **Database:** SQLite (Local persistent storage)
* **Deployment:** Render (Cloud Hosting)

## Engineering Challenges Overcome

The biggest challenge was dealing with flaky third-party APIs. I initially relied on a single global aggregator, but during development, it went down and crashed the frontend. I engineered a solution by writing a custom concurrent aggregator using Python `requests`. It pings multiple APIs (including LeetCode's GraphQL) with strict timeout parameters. If one platform's server hangs, the Python backend isolates the fault, drops that specific platform, and successfully returns the rest of the data so the user UI never freezes.
