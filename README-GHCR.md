## Keycloak Custom Build → GitHub Container Registry (GHCR)

Repo ini dibuat untuk **custom build Keycloak** lalu **publish image Docker ke GHCR** via GitHub Actions, sehingga user cukup `docker pull` dan langsung bisa menjalankan Keycloak.

### Image
- **Registry**: `ghcr.io`
- **Image name**: `ghcr.io/<your-username>/keycloak`
- **Tags**:
  - `latest` (push ke `main`)
  - `sha-<short>` (traceability per commit)
  - `vX.Y.Z`, `X.Y`, `X` (saat push tag semver `vX.Y.Z`)

---

## 1) Cara Pull Image

```bash
docker pull ghcr.io/<your-username>/keycloak:latest
```

## 2) Cara Run (minimal / dev)

```bash
docker run --rm -p 8080:8080 \
  -e KEYCLOAK_ADMIN=admin \
  -e KEYCLOAK_ADMIN_PASSWORD=admin \
  ghcr.io/<your-username>/keycloak:latest start-dev \
  --spi-theme--default=keycloakify-starter \
  --spi-theme--welcome-theme=keycloak
```

- **Admin console**: `http://localhost:8080/admin`
- **Health endpoint**: `http://localhost:8080/health` (enable dengan env, lihat bawah)

> Port default Keycloak: **8080 (HTTP)**, **8443 (HTTPS)**. Pada mode production, HTTP bisa nonaktif jika konfigurasi HTTPS/hostname belum benar—gunakan `start-dev` untuk quick test.

---

## 3) Production Deployment (Docker Compose + PostgreSQL)

File siap pakai: `docker-compose.yml`

### Jalankan

```bash
set KEYCLOAK_IMAGE=ghcr.io/<your-username>/keycloak:latest
docker compose up -d
```

Lalu akses:
- `http://localhost:8080/admin`

### Environment variables penting
- **Bootstrap admin**
  - `KEYCLOAK_ADMIN`
  - `KEYCLOAK_ADMIN_PASSWORD`
- **Database (production)**
  - `KC_DB` (contoh: `postgres`)
  - `KC_DB_URL` (contoh: `jdbc:postgresql://postgres:5432/keycloak`)
  - `KC_DB_USERNAME`
  - `KC_DB_PASSWORD`
- **Observability**
  - `KC_HEALTH_ENABLED=true`
  - `KC_METRICS_ENABLED=true`
- **Reverse proxy / hostname (umum di production)**
  - `KC_PROXY=edge`
  - `KC_HOSTNAME=auth.example.com`
 - **Theme defaults**
  - `--spi-theme--default=<themeName>` (contoh: `keycloakify-starter`)
  - `--spi-theme--welcome-theme=<themeName>` (recommended: keep `keycloak`)

---

## 4) Customization Support

### A) Tambah Custom Themes
Kalau theme kamu **berbentuk JAR** (misalnya output dari keycloakify), perlakukan dia seperti provider:
- taruh JAR di `docker/providers/*.jar` (recommended), atau
- pada repo ini sudah ada contoh JAR di `js/apps/keycloak-server/server/providers/keycloakify-starter.jar` yang otomatis ikut masuk image.

Kalau theme kamu **berbentuk folder theme** (file-based), gunakan cara di bawah.

Letakkan theme di:

- `docker/themes/<your-theme>/...`

Contoh struktur:
- `docker/themes/mytheme/login/theme.properties`
- `docker/themes/mytheme/login/resources/...`

Theme akan ikut ter-bake ke image di `/opt/keycloak/themes`.

### B) Tambah Custom Providers / SPI
Letakkan JAR provider di:

- `docker/providers/*.jar`

Saat build image, file akan dipindah ke `/opt/keycloak/providers/` dan image akan menjalankan:
- `kc.sh build`

Ini memastikan provider ter-augment dengan benar dan startup lebih cepat.

### C) Pre-configure Realm / Clients (import)
Letakkan file realm export JSON di:

- `docker/realm/*.json`

Saat runtime, jalankan dengan flag import:
- dev: `start-dev --import-realm`
- prod: `start --optimized --import-realm`

Keycloak akan membaca dari:
- `/opt/keycloak/data/import`

---

## 5) CI/CD: GitHub Actions → Build & Push ke GHCR

Workflow: `.github/workflows/build-and-push.yml`

### Trigger
- Push ke branch `main` → push tag `latest` + `sha-...`
- Push tag `vX.Y.Z` → push tag semver juga (`vX.Y.Z`, `X.Y`, `X`)
- Manual: workflow dispatch

### Auth ke GHCR
Workflow menggunakan `GITHUB_TOKEN` dengan permission:
- `packages: write`

---

## 6) Build Lokal (opsional)

Jika mau build image di mesin sendiri:

```bash
docker build -t keycloak-custom:local .
docker run --rm -p 8080:8080 \
  -e KEYCLOAK_ADMIN=admin \
  -e KEYCLOAK_ADMIN_PASSWORD=admin \
  keycloak-custom:local start-dev
```

