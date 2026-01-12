# Plan Renaming FE: “Keycloak” → “Identity” (Scope: `js/` saja)

Dokumen ini adalah rencana praktis untuk rebrand **frontend** dengan mengganti **teks yang tampil ke user** dari “Keycloak” menjadi “Identity”, **tanpa** mengubah:
- nama package / import path (npm)
- nama artifact / Maven coordinates (Java)
- API publik (nama tipe/class yang jadi kontrak)
- endpoint / base path protokol

> Target: orang yang buka Admin UI / Account UI melihat “Identity” (judul, label, footer, dsb), tapi sistem tetap kompatibel karena identifier teknis tetap “Keycloak”.

---

## Scope yang Dikerjakan

### Folder yang termasuk
- `js/apps/admin-ui/`
- `js/apps/account-ui/`
- `js/libs/ui-shared/` (kalau ada label/copy yang muncul di UI)

### Folder yang tidak termasuk (walau masih di `js/`)
- `js/libs/keycloak-admin-client/` (**jangan** rename simbol/API; ini library)
- `js/apps/keycloak-server/` (dev server helper; rename branding text boleh, tapi jangan sentuh hal teknis)
- `js/apps/create-keycloak-theme/` (tooling; rename nama package/import/artifact **jangan**)
- `js/themes-vendor/` (vendor build; **hindari** edit kecuali memang ada teks UI yang kamu butuhkan)

---

## Aturan Utama: Apa yang BOLEH dan TIDAK BOLEH di-rename

## 1) Yang BOLEH di-rename (aman, user-facing)

### A. UI copy (string yang tampil)
Contoh target umum:
- “Keycloak” pada halaman login/admin/account
- “Keycloak Admin Console”
- “Keycloak Account Console”
- teks footer, label menu, heading, helper text

Lokasi umum:
- `js/apps/admin-ui/src/**`
- `js/apps/account-ui/src/**`
- `js/libs/ui-shared/src/**`

### B. i18n resources
Kalau ada resource terjemahan yang mengandung “Keycloak” sebagai teks tampilan, aman untuk diganti.

### C. (Skip) HTML title / metadata dan asset branding
Untuk repo kamu, bagian ini **sudah ditangani oleh custom theme** (logo/favicon/title/branding), jadi **plan renaming FE ini tidak menyentuh**:
- HTML title / metadata
- logo/favicon/asset branding

---

## 2) Yang TIDAK BOLEH di-rename (high risk / kontrak teknis)

### A. Nama package npm / import path
**Jangan** ubah hal seperti:
- `keycloak-js`
- `@keycloak/*`
- `keycloak-admin-client`
- path import internal monorepo yang memang bernama keycloak

Alasan: itu kontrak dependency/build. Mengubahnya akan merambat ke seluruh workspace dan pihak ketiga.

### B. Public API symbols yang dipakai sebagai kontrak
Contoh:
- nama tipe, class, function yang diexport sebagai API (terutama di `js/libs/keycloak-admin-client`)
- struktur folder/package yang dipublish

Kalau kamu “rename class KeycloakSomething → IdentitySomething” di library: itu **breaking change**.

### C. Identifiers teknis yang dipakai runtime (walau muncul di FE)
Beberapa string terlihat seperti “teks biasa”, tapi sebenarnya identifier, contoh:
- keys untuk config/env
- nama route/path yang harus match server (mis. `/realms/...`)
- nama param/query yang dibaca server

Jika string itu dipakai untuk komunikasi ke server: treat sebagai kontrak, **jangan rename sembarangan**.

### D. Path protokol / endpoint
Jangan ubah:
- `/realms/{realm}`
- `/protocol/openid-connect`
- dan path API lain yang merupakan surface server

---

## Strategi Eksekusi (Aman dan Terukur)

## Step 0 — Definisikan kamus rename
Biar konsisten, buat mapping yang jelas:
- **Brand name**: `Keycloak` → `Identity`
- **Lowercase** (untuk teks biasa): `keycloak` → `identity`

Catatan:
- Lowercase sering muncul di URL/path/import. Untuk scope ini, **lowercase hanya diganti kalau itu benar-benar teks tampilan**, bukan identifier teknis.

## Step 1 — Cari semua kemunculan “Keycloak” yang user-facing
Fokus pattern yang aman:
- `"Keycloak"` (Title Case) di file TS/TSX
- teks di file `.md` di `js/apps/**/README.md`

## Step 2 — Terapkan perubahan bertahap
Urutan yang paling minim risiko:
1) Ganti **judul UI** (header/title/welcome text)
2) Ganti **footer/about/help** text
3) Baru setelah itu ganti kemunculan lain yang jelas “copy”, bukan identifier

## Step 3 — Update test yang bergantung pada teks
Kemungkinan lokasi:
- `js/apps/admin-ui/test/**`
- `js/apps/account-ui/test/**`

Biasanya yang perlu diubah:
- assertions yang mencari label “Keycloak …”
- snapshot/expected strings

## Step 4 — Verifikasi cepat
Minimum verifikasi:
- build FE (admin-ui & account-ui)
- jalankan test (atau paling tidak subset yang relevan)
- sanity check halaman penting (login/admin/account) secara manual

---

## Checklist “Aman untuk Rename” vs “Skip”

### Aman untuk rename (umumnya)
- UI headings/labels/help text: ✅
- “About/Version/Powered by …” copy: ✅
- README di folder FE: ✅

### Wajib skip (kecuali kamu memang siap breaking changes)
- `package.json` name/deps yang mengandung `keycloak-*`: ❌
- semua import path yang mengandung `keycloak`: ❌
- nama folder/library publish (mis. `keycloak-admin-client`): ❌
- route/path/protocol constants untuk komunikasi ke server: ❌
- env var/config keys: ❌ (kecuali benar-benar hanya label)
- logo/favicon/title/meta: ❌ (di-handle custom theme)

---

## Output yang Diinginkan (Definition of Done)
- UI admin/account menampilkan “Identity” pada area-branding utama (header/title/footer).
- Tidak ada perubahan pada package/import/artifact names.
- Build FE tetap hijau.
- Test yang relevan (minimal) lulus atau sudah diupdate sesuai perubahan teks.

