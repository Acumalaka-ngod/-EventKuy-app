# Agent Skills (OpenCode)

Aturan kerja untuk agent di project **EventKuy** (Flutter + Supabase).
File ini dibaca otomatis oleh OpenCode setiap sesi.

## Lokasi skill

| Cakupan | Path | Status |
| --- | --- | --- |
| Global (semua project) | `~/.agents/skills/<nama>/SKILL.md`<br>Windows: `C:\Users\Orang\.agents\skills\` | 35 skill terpasang |
| Project (khusus repo ini) | `.opencode/skills/<nama>/SKILL.md` | belum ada, opsional |
| Bawaan OpenCode | dikelola OpenCode sendiri | `opencode`, `report` |

Repo sumber skill global: `C:\Users\Orang\agent-skills`.

## Aturan inti

1. **Cek skill dulu, baru bertindak.** Untuk setiap perintah user, tentukan apakah
   ada skill yang cocok — walau kemungkinannya kecil.
2. **Panggil dengan parameter `id`, bukan `name`:**

   ```
   skill({ id: "test-driven-development" })
   ```

3. **Ikuti workflow skill secara utuh.** Jangan diterapkan sebagian.
4. **Jangan lewati langkah wajib** (spec, plan, test, verifikasi) yang diminta skill.
5. Kalau tidak ada skill yang cocok, kerjakan langsung dan sebutkan alasannya singkat.

## Intent → skill

| Intent | Skill |
| --- | --- |
| Kebutuhan masih kabur / underspecified | `interview-me` |
| Ide masih mentah, butuh opsi | `idea-refine` |
| Fitur / perubahan baru | `spec-driven-development` → `planning-and-task-breakdown` → `incremental-implementation` → `test-driven-development` |
| Memecah pekerjaan jadi task | `planning-and-task-breakdown` |
| Menulis kode | `incremental-implementation` |
| Kerja UI / layout / komponen | `frontend-ui-engineering` |
| Desain API / kontrak antar modul | `api-and-interface-design` |
| Butuh verifikasi ke dokumentasi resmi | `source-driven-development` |
| Bug / error / perilaku tak terduga | `debugging-and-error-recovery` |
| Menulis atau menjalankan test | `test-driven-development` |
| Test di browser / inspeksi DOM & console | `browser-testing-with-devtools` |
| Code review | `code-review-and-quality` |
| Refactor / menyederhanakan kode | `code-simplification` |
| Audit keamanan | `security-and-hardening` |
| Optimasi performa | `performance-optimization` |
| Commit / branch / PR | `git-workflow-and-versioning` |
| CI/CD | `ci-cd-and-automation` |
| Dokumentasi / ADR | `documentation-and-adrs` |
| Logging / metrics / tracing | `observability-and-instrumentation` |
| Deploy / rilis | `shipping-and-launch` |
| Menyusun standar mutu project | `constraint-driven-development` |
| Migrasi / menghapus sistem lama | `deprecation-and-migration` |
| Deploy ke Vercel | `deploy-to-vercel`, `vercel-cli-with-tokens` |
| Review UI terhadap pedoman web | `web-design-guidelines` |
| Review tulisan/dokumen | `writing-guidelines` |

## Execution model

Untuk setiap permintaan:

1. Tentukan skill yang berlaku (lihat tabel di atas).
2. Muat dengan `skill({ id: "<nama-skill>" })`.
3. Ikuti langkahnya berurutan.
4. Baru implementasi setelah langkah wajib selesai.

Beberapa skill boleh dipakai berurutan. Contoh alur fitur penuh:
`spec-driven-development` → `planning-and-task-breakdown` → `incremental-implementation`
→ `test-driven-development` → `code-review-and-quality` → `git-workflow-and-versioning`.

## Definition of Done project ini

Sebelum menyatakan tugas selesai, jalankan dan laporkan hasilnya:

```powershell
flutter analyze
flutter test
```

Untuk perubahan web, tambahkan:

```powershell
flutter build web --release --dart-define-from-file=supabase.local.json
```

Aturan tambahan project:

- Jangan commit `supabase.local.json` atau service role key.
- Runtime memakai Supabase; `MockApiService` hanya untuk test.
- Data event/tiket dikelola lewat Supabase Studio, bukan panel admin buatan sendiri.
