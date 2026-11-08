# NEXORA LAN configuration — validation report

## Checks run in the project workspace

| Check | Result | Notes |
|---|---|---|
| Backend automated test suite | PASS | 14 tests passed. |
| Python module compilation | PASS | `main.py`, recurring worker, Alembic env. |
| Frontend JavaScript syntax | PASS | `node --check frontend/assets/app.js`. |
| Docker Compose and four workflow YAML files parse | PASS | Parsed with YAML BaseLoader. |
| Android manifest and style XML parse | PASS | Both XML files parsed successfully. |
| Local PowerShell runtime execution | NOT RUN | PowerShell is not installed in the workspace. The Quality workflow now parses all `.ps1` scripts on GitHub Actions. |
| `docker compose config` / containers | NOT RUN | Docker CLI/Engine is not installed in the workspace. Quality workflow will run `docker compose config --quiet` after upload. |
| Android Gradle/APK build | NOT RUN | Android SDK/Gradle are not installed in the workspace. Build Android APK workflow is prepared to build the LAN debug APK. |
| Physical Wi-Fi/Android test | NOT RUN | Requires the user's Windows laptop, router, and Android phone. |

## Security properties in the LAN package

- API host port binds to `0.0.0.0` so the phone can reach the laptop on LAN.
- Windows Firewall rule is scoped to `Private` profile and `LocalSubnet` remote addresses.
- PostgreSQL port 5432 is not published to the host/LAN.
- API secret values are generated locally and written to ignored `.env`; they are never printed.
- Android debug workflow opts into cleartext/mixed content for private-LAN HTTP only. Release still disables cleartext.
- No router port-forwarding instructions are included; do not expose this server to the internet.

## User-side acceptance tests after upload

1. `Start-NEXORA-LAN.bat` creates `.env`, starts services, and prints the laptop LAN IPv4.
2. Laptop `http://localhost:8000/health` returns `{"status":"ok",...}`.
3. Phone Chrome `http://<LAPTOP-IP>:8000/health` returns the same JSON.
4. LAN debug APK can save `http://<LAPTOP-IP>:8000/api/v1` as API Base URL.
5. Register a test account; save recovery code; create and confirm a test transaction.
6. Stop/start containers and verify the test transaction remains, proving volume persistence.
7. Confirm that an unrelated device not on the same private subnet cannot reach the API.
