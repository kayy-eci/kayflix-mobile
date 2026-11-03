# Dokumentasi Alur — Kayflix Mobile (Flutter)

Dokumen ini memetakan **setiap alur** di aplikasi klien: dari startup, autentikasi JWT,
pembacaan katalog, sampai CRUD admin. Untuk tiap langkah disebutkan **file + fungsi/baris**
yang bertanggung jawab dan **cara kerjanya**.

> **Cakupan:** seluruhnya sisi klien. Backend yang dirujuk README (`../WEBDEV/kayflix-BE`)
> tidak ada di mesin ini, jadi kontrak endpoint (bentuk response, aturan otorisasi server)
> **tidak diverifikasi** — yang dijelaskan di sini adalah apa yang klien kirim dan harapkan.

---

## 1. Peta arsitektur

```
Widget (presentation)
   │  ref.watch(...) / ref.read(...)
   ▼
Riverpod provider  ── state & cache
   │
   ▼
Repository  ── bentuk request/response per endpoint
   │
   ▼
ApiClient (Dio)  ── base URL, header Bearer, mapping error → ApiException
   │
   ▼
Backend Express (via https://hfvwgq71-8000.asse.devtunnels.ms)
```

Tiga lapisan itu konsisten dipakai:

| Lapisan | Contoh | Tanggung jawab |
| --- | --- | --- |
| Presentation | `lib/features/home/presentation/home_page.dart` | render, gesture, dialog |
| Provider / controller | `lib/features/session/presentation/session_controller.dart` | state, invalidasi cache, orkestrasi |
| Repository | `lib/features/movies/data/movie_repository.dart` | endpoint + parsing |
| Core | `lib/core/**` | config, network, storage, tema, widget bersama |

---

## 2. Peta file inti

| File | Isi |
| --- | --- |
| `lib/main.dart` | entrypoint, system UI |
| `lib/app.dart` | `MaterialApp.router` + tema |
| `lib/router/app_router.dart` | semua route + redirect auth |
| `lib/core/config/api_config.dart` | resolusi base URL |
| `lib/core/network/api_client.dart` | Dio, interceptor JWT, mapping error |
| `lib/core/network/api_exception.dart` | error yang bisa ditampilkan |
| `lib/core/auth/jwt_payload.dart` | decode payload JWT, cek expiry |
| `lib/core/storage/token_storage.dart` | simpan/baca/hapus token |
| `lib/features/session/presentation/session_controller.dart` | provider sesi + semua aksi akun |
| `lib/features/session/data/session_repository.dart` | endpoint auth & user |
| `lib/features/movies/data/movie_repository.dart` | endpoint CRUD film |
| `lib/features/movies/presentation/movie_providers.dart` | cache katalog + turunannya |
| `lib/features/my_list/presentation/*_controller.dart` | My List & Likes lokal |
| `lib/features/admin/presentation/*.dart` | layar CRUD admin |

---

## 3. Alur A — Startup & restore sesi

**Tujuan:** menentukan apakah user langsung masuk, harus login, atau server bermasalah.

| # | Langkah | Kode | Cara kerja |
| --- | --- | --- | --- |
| A1 | App dijalankan | `lib/main.dart:8-20` | `WidgetsFlutterBinding.ensureInitialized()`, atur edge-to-edge, lalu `runApp(ProviderScope(child: KayflixApp()))`. |
| A2 | Root widget | `lib/app.dart:9-24` | `ref.watch(routerProvider)` lalu `MaterialApp.router(routerConfig: router)`. Router dibuat sekali dan di-dispose bersama provider. |
| A3 | Router dibuat | `lib/router/app_router.dart:23-26` | `initialLocation: '/splash'`. `ref.listen(sessionControllerProvider, ...)` menaikkan `ValueNotifier refresh`, yang dipasang sebagai `refreshListenable` → setiap perubahan sesi memicu evaluasi ulang `redirect`. |
| A4 | `sessionControllerProvider` pertama kali dibaca | `lib/features/session/presentation/session_controller.dart:28-59` | `AsyncNotifier.build()`: baca token dari secure storage. Jika `null` → state `AsyncData(null)`. |
| A5 | Validasi klaim | `lib/core/auth/jwt_payload.dart:26-48` | `tryParse` memecah `header.payload.signature`, decode base64url bagian payload, ambil `id`, `email`, `role`, `exp`. Gagal decode → `null`. |
| A6 | Cek kedaluwarsa | `jwt_payload.dart:19-24` | `isExpired` bandingkan `exp` dengan `now + 30 detik` (token yang hampir habis dianggap habis). `exp` tidak ada → dianggap belum expired. |
| A7 | Token rusak/expired | `session_controller.dart:38-42` | `storage.clear()` lalu kembalikan `null` → user diarahkan ke `/login`. |
| A8 | Ambil profil | `session_controller.dart:44-51` → `session_repository.dart:48-55` | `GET /api/profile` dengan Bearer. Response harus `{ "data": {...} }`, diparsing `User.fromJson` (`lib/features/session/domain/user.dart:17-25`). Lalu bentuk `Session(token, user, role, expiresAt)`. |
| A9 | 401 saat ambil profil | `session_controller.dart:52-57` | `ApiException.isUnauthorized` (`api_exception.dart:15`) → token dihapus, state `null`. |
| A10 | Error lain (mis. server mati) | `session_controller.dart:57` | `rethrow` → provider masuk state error. Router menahan user di `/splash` (`app_router.dart:39-41`), dan `SplashPage` menampilkan `ErrorStateView` + tombol coba lagi (`lib/features/auth/presentation/splash_page.dart:29-37`). |
| A11 | Redirect | `app_router.dart:32-50` | `isLoading`/`hasError` → `/splash`; `value == null` → `/login`; sudah login tapi di `/login` atau `/splash` → `/profiles`; selain itu `null` (lanjut). |

**Catatan:** `SplashPage` tidak melakukan request sendiri — ia hanya me-render state provider.

---

## 4. Alur B — Login

| # | Langkah | Kode | Cara kerja |
| --- | --- | --- | --- |
| B1 | Validasi form lokal | `lib/features/auth/presentation/login_page.dart:41-48` | `unfocus()`, `_formKey.currentState!.validate()`. Aturan ada di `lib/core/utils/validators.dart` (email format, password minimal 6). |
| B2 | Panggil controller | `login_page.dart:50-54` | `ref.read(sessionControllerProvider.notifier).login(email, password)`. |
| B3 | Request login | `session_controller.dart:66-70` → `session_repository.dart:14-31` | `POST /api/auth/login` body `{email (trim+lowercase), password}`. Response harus punya **key top-level** `token`; kalau tidak ada/ kosong → `ApiException('Server tidak mengirim token login.')`. |
| B4 | Simpan token | `session_controller.dart:70` → `token_storage.dart:22-29` | Tulis ke `flutter_secure_storage` key `kayflix.auth.token`. Error storage ditelan (desktop/web bisa tidak tersedia) agar sesi tetap jalan untuk run ini. |
| B5 | Ambil profil | `session_controller.dart:72-83` | Parse payload, `GET /api/profile`, bentuk `Session`. `role` diambil dari JWT dulu, fallback ke `user.role`, lalu `'user'`. |
| B6 | Gagal ambil profil | `session_controller.dart:84-87` | Token yang sudah tersimpan **dihapus lagi** supaya tidak ada sesi setengah jadi, lalu error dilempar ke form. |
| B7 | Tampilkan error | `login_page.dart:56-63` | `ApiException` → banner merah berisi `error.userMessage` (utamakan pesan field dari backend, `api_exception.dart:18-21`). Error tak terduga → "Gagal masuk. Coba lagi." |
| B8 | Pindah layar | `app_router.dart:25,48` | Perubahan state memicu `refreshListenable`; `redirect` melihat sesi tidak null dan lokasi `/login` → `/profiles`. Tidak ada `context.go` di halaman login. |

---

## 5. Alur C — Register

| # | Langkah | Kode | Cara kerja |
| --- | --- | --- | --- |
| C1 | Validasi form | `lib/features/auth/presentation/register_page.dart:43-50` | Username, email, password, dan konfirmasi. Konfirmasi dibandingkan manual dengan `_password.text` (`:142-146`). |
| C2 | Kirim data | `register_page.dart:53-57` → `session_controller.dart:90-100` → `session_repository.dart:33-46` | `POST /api/users` body `{username, email, password}`. Tidak ada token yang dikembalikan. |
| C3 | Setelah sukses | `register_page.dart:59-66` | Snackbar "Akun berhasil dibuat", lalu `context.go('/login?email=...')`. Email dibawa sebagai query param. |
| C4 | Prefill email | `app_router.dart:56-61` → `login_page.dart:27-28` | Route membaca `state.uri.queryParameters['email']`, `LoginPage.initialEmail` mengisi controller. User tetap harus mengetik password. |
| C5 | Gagal | `register_page.dart:67-75` | Sama seperti login: `userMessage` di banner, error lain → pesan generik. |

---

## 6. Alur D — Setiap request API (penyisipan JWT)

| # | Langkah | Kode | Cara kerja |
| --- | --- | --- | --- |
| D1 | Base URL | `lib/core/config/api_config.dart:20-23` | Default `_tunnel` (`:18`) = `https://hfvwgq71-8000.asse.devtunnels.ms`, satu alamat untuk semua platform. `--dart-define=API_BASE_URL=...` menimpanya tanpa mengubah kode. |
| D2 | Klien dibuat | `session_controller.dart:14-22` | `apiClientProvider` membuat satu `ApiClient` dan mengaitkan `onUnauthorized` ke `forceLogout()`. `ref.onDispose(client.close)` menutup koneksi. |
| D3 | Interceptor request | `api_client.dart:25-31` | Sebelum tiap request, baca token dari storage; kalau ada, set `Authorization: Bearer <token>`. Tidak ada header token di level widget. |
| D4 | Method pembungkus | `api_client.dart:52-73` | `get/post/put/delete/upload` semuanya lewat `_request`. `upload` memakai `FormData` (multipart). |
| D5 | Normalisasi response | `api_client.dart:75-87` | `Map` → dikembalikan apa adanya; tipe lain → dibungkus `{'data': data}`. Repository kemudian membaca key `data` / `token`. |
| D6 | Mapping error | `api_client.dart:89-132` | Tanpa response: timeout → pesan timeout; selain itu pesan "tidak dapat terhubung ke `<baseUrl>`". Dengan response: pakai `body['message']` bila ada, kumpulkan `body['errors'][].message` (Zod) ke `details`. |
| D7 | Timeout | `api_client.dart:17-18` | connect 15 s, receive 25 s. |

**Konsekuensi:** storage dibaca **setiap request** (async), bukan di-cache di memori.

---

## 7. Alur E — Token ditolak (401) → logout paksa

| # | Langkah | Kode | Cara kerja |
| --- | --- | --- | --- |
| E1 | Deteksi | `api_client.dart:32-37` | Interceptor `onError` memeriksa `response.statusCode == 401`, memanggil `onUnauthorized`, lalu tetap meneruskan error ke pemanggil. |
| E2 | Handler | `session_controller.dart:16-19` | `onUnauthorized` → `ref.read(sessionControllerProvider.notifier).forceLogout()`. |
| E3 | Bersihkan | `session_controller.dart:167-174` | Dijalankan dalam `microtask` (401 bisa terjadi saat sesi masih loading), cek `ref.mounted`, hapus token, set state `null`. Tidak memanggil endpoint logout. |
| E4 | Navigasi | `app_router.dart:43-46` | State jadi `null` → `redirect` mengarahkan ke `/login` dari layar mana pun. |
| E5 | Pesan | `api_client.dart:138-139` | Default untuk 401: "Sesi kamu sudah berakhir. Silakan masuk kembali." (bisa ditimpa `message` dari backend). |

---

## 8. Alur F — Logout manual

| # | Langkah | Kode | Cara kerja |
| --- | --- | --- | --- |
| F1 | Pemicu | `lib/features/profile/presentation/profile_page.dart:109-117` (`_signOut`), `lib/features/auth/presentation/profiles_page.dart:86-94` | Dialog konfirmasi dulu (profile), lalu panggil controller. |
| F2 | Logout backend | `session_controller.dart:161-163` → `session_repository.dart:101-107` | `POST /api/auth/logout`; kegagalan **diabaikan** (backend no-op), sign-out tidak boleh terblokir. |
| F3 | Hapus token | `session_controller.dart:164` | `storage.clear()` → `_storage.delete(key)`, error ditelan (`token_storage.dart:31-37`). |
| F4 | Reset state | `session_controller.dart:165` | `state = AsyncData(null)` → router ke `/login`. |
| F5 | Efek samping | `my_list_controller.dart:14-16`, `likes_controller.dart:15-17` | Kedua controller `ref.watch(sessionControllerProvider)`, jadi ikut rebuild saat sesi berubah dan memuat set untuk user baru. |

---

## 9. Alur G — Update profil (username/email/password)

| # | Langkah | Kode | Cara kerja |
| --- | --- | --- | --- |
| G1 | Isi awal form | `lib/features/profile/presentation/edit_profile_page.dart:30-40` | `didChangeDependencies` mengisi username/email sekali dari sesi (`_initialized` mencegah overwrite saat rebuild). |
| G2 | Validasi | `edit_profile_page.dart:50-57` | `Validators.username/email/password`. Password **wajib** karena backend mensyaratkannya (teks bantuan di `:96,130`). |
| G3 | Kirim | `edit_profile_page.dart:60-64` → `session_controller.dart:114-131` | Controller mengambil `current.user.id` dari state, lalu `PUT /api/users/:id` body `{username, email, password}`. |
| G4 | Segarkan tampilan | `session_controller.dart:130` → `:102-112` | `refreshProfile()` memanggil `GET /api/profile` dan `state = AsyncData(current.copyWith(user: user))`. Kegagalan refresh ditelan agar profil lama tetap tampil. |
| G5 | Selesai | `edit_profile_page.dart:66-70` | Snackbar lalu `context.pop()`. Error → `_error` di banner (`:71-79`). |

**Catatan:** token JWT lama tetap dipakai setelah update; `role` di sesi tidak dihitung ulang
dari server, hanya `user` yang diganti.

---

## 10. Alur H — Upload avatar

| # | Langkah | Kode | Cara kerja |
| --- | --- | --- | --- |
| H1 | Pilih sumber | `profile_page.dart:25-62` | Bottom sheet: galeri atau kamera → `ImageSource`. |
| H2 | Ambil gambar | `profile_page.dart:67-71` | `ImagePicker().pickImage(maxWidth: 1200, imageQuality: 85)`; `null` (dibatalkan) → berhenti. |
| H3 | Batas ukuran | `profile_page.dart:74-81` | Baca bytes; > 5 MB → snackbar, batal upload. |
| H4 | Bentuk multipart | `session_repository.dart:73-95` | Field `profileImage`, `MultipartFile.fromBytes` dengan `filename` dan `contentType` dari `mimeTypeForFilename` (`lib/core/utils/mime.dart`). |
| H5 | Kirim | `session_repository.dart:87` | `POST /api/users/:id/profile-image` lewat `ApiClient.upload`. |
| H6 | Baca hasil | `session_repository.dart:88-94` | Butuh `{ "data": { "profileImageUrl": "..." } }`; kalau tidak ada → `ApiException`. URL-nya sendiri tidak dipakai langsung. |
| H7 | Segarkan | `session_controller.dart:143-149` | `refreshProfile()` → `GET /api/profile` mengembalikan `profile_image_url` yang baru, sehingga `UserAvatar` ikut berubah (`user.dart:22`). |
| H8 | Status UI | `profile_page.dart:83-106` | `_uploading` menampilkan spinner di atas avatar dan menonaktifkan tap. |

---

## 11. Alur I — Hapus akun

| # | Langkah | Kode | Cara kerja |
| --- | --- | --- | --- |
| I1 | Konfirmasi | `profile_page.dart:119-127` | Dialog destruktif (`_confirm`, `:143-187`) dengan tombol merah. |
| I2 | Hapus di server | `session_controller.dart:152-157` → `session_repository.dart:97-99` | `DELETE /api/users/:id`. |
| I3 | Bersihkan lokal | `session_controller.dart:157-158` | Hapus token, state `null` → router ke `/login`. Error hanya ditampilkan sebagai snackbar (`profile_page.dart:135-140`). |

---

## 12. Alur J — Membaca katalog (satu sumber data)

| # | Langkah | Kode | Cara kerja |
| --- | --- | --- | --- |
| J1 | Provider repositori | `lib/features/movies/presentation/movie_providers.dart:7-9` | `MovieRepository` dibuat dari `apiClientProvider`. |
| J2 | Provider katalog | `movie_providers.dart:13-15` | `FutureProvider` memanggil `GET /api/movies` sekali; hasilnya di-cache Riverpod dan dipakai bersama semua layar. |
| J3 | Parsing | `lib/features/movies/data/movie_repository.dart:9-19` | Hanya `response['data']` yang harus `List`. Elemen non-Map dibuang (`whereType<Map>()`). |
| J4 | Model | `lib/features/movies/domain/movie.dart:19-30` | `fromJson` memberi nilai default aman: judul kosong → "Tanpa Judul", rating/durasi kosong → "-", tahun → 0. |
| J5 | Turunan | `movie.dart:42-52` | `genreList` memecah string koma; `matchPercent` = `80 + (id*7)%19` karena backend tidak menghitung skor. |
| J6 | Loading/error | mis. `home_page.dart:61-76` | `.when(loading:, error:, data:)`. Pesan error mengambil `error.toString()` dan membuang prefix `ApiException: `. |
| J7 | Refresh | `home_page.dart:53-60`, `new_hot_page.dart:26-34`, `admin_movies_page.dart:144-152` | `ref.invalidate(moviesProvider)` lalu `await ...future` agar indikator pull-to-refresh menunggu request selesai. |

---

## 13. Alur K — Turunan data di Home

| # | Langkah | Kode | Cara kerja |
| --- | --- | --- | --- |
| K1 | Baca state | `home_page.dart:20-23` | Watch `moviesProvider`, `myListProvider`, dan `sessionControllerProvider` (hanya untuk `isAdmin`). |
| K2 | Hero | `home_page.dart:110-113` | Salin list, sort `year` menurun, ambil elemen pertama sebagai `featured`. |
| K3 | Baris "Populer" | `home_page.dart:113,128-132` | Salin list **tanpa** sort — urutan mengikuti backend. |
| K4 | Baris "Rekomendasi" | `home_page.dart:114-115,135-139` | Sort `matchPercent` menurun. |
| K5 | Baris "Daftar Saya" | `home_page.dart:116,141-148` | Filter `myList.contains(id)`; kosong → kartu ajakan (`_AddCard`). |
| K6 | Baris "Rilis Terbaru" | `home_page.dart:149-151`, `_ContinueRow` `:449-482` | Sort tahun menurun; komentar di `:447-448` menegaskan ini pengganti "Continue watching" karena tidak ada riwayat. |
| K7 | Tap kartu | `home_page.dart:394`, `:474` | `context.push('/movie/:id')`. |
| K8 | Aksi hero | `home_page.dart:300-302, 323-324` | "Mainkan" → `/movie/:id/play`; "Info" → `/movie/:id`. |
| K9 | Katalog kosong | `home_page.dart:97-108` | Pesan berbeda untuk admin (ada tombol ke `/admin`) dan user biasa. |

---

## 14. Alur L — Pencarian (client-side)

| # | Langkah | Kode | Cara kerja |
| --- | --- | --- | --- |
| L1 | Input | `lib/features/search/presentation/search_page.dart:29-31` | `onChanged` → `_query = value.trim().toLowerCase()` lalu `setState`. Tidak ada request per ketikan. |
| L2 | Filter | `search_page.dart:33-40` | `where`: judul, `genres`, atau `yearLabel` mengandung query. |
| L3 | Chip genre | `search_page.dart:46, 99-127` | `genresProvider` (`movie_providers.dart:35-43`) mengumpulkan semua genre dari katalog, diurutkan alfabetis. Tap chip → isi field + `_update`. |
| L4 | Hasil | `search_page.dart:140-155` | `MovieGrid` dengan `inList` untuk badge bookmark; kosong → `EmptyStateView`. |
| L5 | Buka detail | `search_page.dart:151-152` | `context.push('/movie/:id')`. |

**Keterbatasan:** hanya mencari di data yang sudah diunduh; tidak ada paginasi/filter server.

---

## 15. Alur M — Halaman detail film

| # | Langkah | Kode | Cara kerja |
| --- | --- | --- | --- |
| M1 | Ambil film | `lib/features/movies/presentation/movie_detail_page.dart:21-22` → `movie_providers.dart:17-24` | `movieByIdProvider(id)` melakukan `for` pada katalog yang sudah ada. Tidak ada `GET /api/movies/:id`. |
| M2 | Film belum ada | `movie_detail_page.dart:24-36` | Jika katalog masih loading → `LoadingView`; jika sudah selesai → "Film tidak ditemukan" (mis. baru dihapus). |
| M3 | Status simpan/suka | `movie_detail_page.dart:38-43` | `myListProvider` dan `likesProvider` di-`watch`, cek `contains(id)`. |
| M4 | Film serupa | `movie_detail_page.dart:42` → `movie_providers.dart:26-33` | Filter film lain yang `sharesGenreWith` (`movie.dart:54-59`, perbandingan lowercase), maksimal 10. |
| M5 | Simpan/batal simpan | `movie_detail_page.dart:113-115` | `myListProvider.notifier.toggle(id)` — tanpa request ke server. |
| M6 | Suka | `movie_detail_page.dart:138-139` | `likesProvider.notifier.toggle(id)`. |
| M7 | Mainkan | `movie_detail_page.dart:334-339` | `context.push('/movie/:id/play')`. |
| M8 | Kembali | `movie_detail_page.dart:57-63` | `context.pop()` bila memungkinkan, kalau tidak `context.go('/home')` (mis. dibuka dari deep link). |

---

## 16. Alur N — Baru & Populer

| # | Langkah | Kode | Cara kerja |
| --- | --- | --- | --- |
| N1 | Data | `lib/features/new_hot/presentation/new_hot_page.dart:17-18` | Katalog + My List. |
| N2 | Urutan | `new_hot_page.dart:65-66` | Sort `year` menurun. |
| N3 | Render | `new_hot_page.dart:68-95` | `ListView.separated`; item ke-0 adalah teks "10 teratas…", index `i` menampilkan `sorted[i-1]` dengan nomor peringkat besar bergaris luar (`_RankedTile`, `:103-197`). |
| N4 | Tanda tersimpan | `new_hot_page.dart:182-187` | Ikon bookmark bila `inList`. |
| N5 | Buka detail | `new_hot_page.dart:92` | `context.push('/movie/:id')`. |

---

## 17. Alur O — Daftar Saya (lokal, per user)

| # | Langkah | Kode | Cara kerja |
| --- | --- | --- | --- |
| O1 | Provider | `lib/features/my_list/presentation/my_list_controller.dart:7-8` | `AsyncNotifierProvider<MyListController, Set<int>>`. |
| O2 | Muat | `my_list_controller.dart:13-21` | Watch sesi → `userId = session?.user.id ?? 0`. Baca `SharedPreferences.getStringList('kayflix.mylist.<userId>')`, parse ke `Set<int>`. |
| O3 | Toggle | `my_list_controller.dart:25-39` | Salin set, `remove` (kalau ada) atau `add`, set state dulu (UI langsung berubah), lalu tulis ulang list string ke prefs. |
| O4 | Tampil | `lib/features/my_list/presentation/my_list_page.dart:43-46` | Filter katalog dengan id tersimpan. |
| O5 | Kosong | `my_list_page.dart:48-57` | `EmptyStateView` + tombol ke `/home`. |
| O6 | Kunci per akun | `my_list_controller.dart:11` + `:15` | Karena `build()` men-watch sesi, ganti akun memuat set akun lain. |

**Tidak ada** endpoint backend untuk My List — murni perangkat, hilang saat app di-uninstall
dan tidak tersinkron antar perangkat.

---

## 18. Alur P — Likes (lokal, per user)

Sama persis dengan My List, key berbeda:

| Langkah | Kode |
| --- | --- |
| Provider | `lib/features/my_list/presentation/likes_controller.dart:7-8` |
| Muat dari `kayflix.likes.<userId>` | `likes_controller.dart:14-21` |
| Toggle + simpan | `likes_controller.dart:23-37` |
| Konsumen | `movie_detail_page.dart:40,139`; jumlah di `profile_page.dart:193` |

---

## 19. Alur Q — Pemutar (mock)

| # | Langkah | Kode | Cara kerja |
| --- | --- | --- | --- |
| Q1 | Ambil film | `lib/features/movies/presentation/player_page.dart:64` | `movieByIdProvider`; `null` → layar "Film tidak tersedia". |
| Q2 | Durasi | `player_page.dart:79-80, 154-168` | Regex mengambil jam (`h|j|jam`) dan menit (`m|mnt|menit`) dari `movie.duration`; gagal → default 45 menit. |
| Q3 | Detak waktu | `player_page.dart:29-41` | `Timer.periodic(1s)`: jika `!_playing` berhenti; jika posisi ≥ durasi → pause; selain itu `_position += 1s`. Timer dibatalkan di `dispose` (`:44-47`). |
| Q4 | Play/pause & seek | `player_page.dart:117-133`, `:49-60` | Pause di akhir lalu play → reset ke 0. Seek ±10 s dijepit antara 0 dan durasi. |
| Q5 | Keluar | `player_page.dart:183-192` | `pop()` atau `go('/home')`. |

**Tidak ada streaming** — server tidak menyediakan URL video (komentar `:11-12`, teks `:139`).

---

## 20. Alur R — Admin: tambah & ubah film

| # | Langkah | Kode | Cara kerja |
| --- | --- | --- | --- |
| R1 | Masuk layar | `lib/features/profile/presentation/profile_page.dart:317-324` (hanya admin) → route `/admin`; FAB `admin_movies_page.dart:119-125` → `/admin/movie`. | |
| R2 | Mode form | `app_router.dart:134-139` → `lib/features/admin/presentation/movie_form_page.dart:41` | `state.extra` berisi `Movie` saat edit; `_isEditing` menentukan judul dan aksi. |
| R3 | Isi awal | `movie_form_page.dart:26-47` | Controller diisi dari `widget.existing`, `_rating` dari film lama (opsi tambahan disisipkan bila di luar 1–10). |
| R4 | Validasi | `movie_form_page.dart:143-217` | Judul wajib; tahun angka 1888–2100; rating wajib dipilih (dropdown 1–10); durasi wajib; minimal satu genre. |
| R5 | Bentuk payload | `movie_form_page.dart:75-82` → `movie.dart:32-40` | `toRequestJson()` mengirim `{title, year, rating, duration, genres}` — **tanpa id**. |
| R6 | Kirim | `movie_form_page.dart:84-90` → `movie_repository.dart:21-27` | Create: `POST /api/movies`. Edit: `PUT /api/movies/:id`. |
| R7 | Segarkan katalog | `movie_form_page.dart:92` | `ref.invalidate(moviesProvider)`; semua layar yang memakainya ikut memuat ulang. |
| R8 | Selesai | `movie_form_page.dart:95-104` | Snackbar sesuai mode, `context.pop()`. Error → banner `_error` (`:105-113`). |
| R9 | Guard halaman | `movie_form_page.dart:118-130` | Sesi null atau bukan admin → "Akses ditolak", form tidak dirender. |

---

## 21. Alur S — Admin: hapus film

| # | Langkah | Kode | Cara kerja |
| --- | --- | --- | --- |
| S1 | Daftar | `admin_movies_page.dart:126-183` | `moviesProvider.when`; header jumlah judul, lalu satu baris per film. |
| S2 | Konfirmasi | `admin_movies_page.dart:23-61` | `showDialog<bool>` dengan judul film; batal → berhenti. |
| S3 | Tandai proses | `admin_movies_page.dart:63` | `_deletingId = movie.id` → spinner menggantikan dua ikon di baris itu (`:260-268`). |
| S4 | Kirim | `admin_movies_page.dart:65` → `movie_repository.dart:29-31` | `DELETE /api/movies/:id`. |
| S5 | Sukses | `admin_movies_page.dart:66-70` | `ref.invalidate(moviesProvider)` + snackbar. |
| S6 | Gagal | `admin_movies_page.dart:71-80` | `ApiException.userMessage` atau pesan generik, spinner dilepas di `finally`. |

---

## 22. Alur T — Gating role admin

| # | Lokasi | Kode | Cara kerja |
| --- | --- | --- | --- |
| T1 | Sumber role | `session_controller.dart:49, 80` | `payload.role ?? user.role ?? 'user'` — klaim JWT diutamakan. |
| T2 | Predikat | `lib/features/session/domain/session.dart:17` | `isAdmin => role == 'admin'`. |
| T3 | Menu profil | `profile_page.dart:317` | Item "Kelola Film" hanya dirender untuk admin. |
| T4 | Badge | `profile_page.dart:261-281` | Chip ADMIN/MEMBER. |
| T5 | Guard halaman | `admin_movies_page.dart:91-104`, `movie_form_page.dart:120-130` | Bukan admin → `EmptyStateView` "Akses ditolak". |
| T6 | Route | `app_router.dart:130-139` | Tidak ada guard di level router — `/admin` tetap bisa dibuka, penolakan terjadi di dalam halaman. |

**Penting:** klien hanya **membaca** klaim tanpa memverifikasi tanda tangan. Semua penolakan
di atas bersifat tampilan; otorisasi sebenarnya harus ditegakkan backend.

---

## 23. Matriks CRUD

| Entitas | Create | Read | Update | Delete | Penyimpanan |
| --- | --- | --- | --- | --- | --- |
| Movie | `POST /api/movies` (`movie_repository.dart:21`) | `GET /api/movies` (`:9`) | `PUT /api/movies/:id` (`:25`) | `DELETE /api/movies/:id` (`:29`) | backend |
| User | `POST /api/users` (`session_repository.dart:33`) | `GET /api/profile` (`:48`) | `PUT /api/users/:id` (`:57`) | `DELETE /api/users/:id` (`:97`) | backend |
| Avatar | `POST /api/users/:id/profile-image` (`:73`) | ikut `/api/profile` | (upload ulang) | — | backend |
| My List | toggle lokal (`my_list_controller.dart:25`) | prefs `kayflix.mylist.<uid>` (`:13`) | toggle lokal | toggle lokal | perangkat |
| Likes | toggle lokal (`likes_controller.dart:23`) | prefs `kayflix.likes.<uid>` (`:14`) | toggle lokal | toggle lokal | perangkat |

Tidak ada endpoint daftar user / baca user per id; profil hanya milik sendiri.

---

## 24. Siklus hidup JWT

| Tahap | Kode | Perilaku |
| --- | --- | --- |
| Terbit | backend `POST /api/auth/login` | Klaim `{id, email, role, jti}`, umur 1 jam (menurut komentar `jwt_payload.dart:3-5`). |
| Simpan | `token_storage.dart:22` | `flutter_secure_storage`, key `kayflix.auth.token`. |
| Pakai | `api_client.dart:26-29` | Dibaca ulang tiap request → header `Authorization: Bearer`. |
| Validasi klien | `jwt_payload.dart:19-24, 26-48` | Hanya decode + cek `exp`; **tanda tangan tidak diverifikasi**. |
| Cek saat start | `session_controller.dart:38-42` | Token invalid/expired → dihapus. |
| Cek saat berjalan | — | **Tidak ada timer.** Token 1 jam yang habis saat app terbuka baru terdeteksi ketika server membalas 401 → `forceLogout`. |
| Segarkan | — | **Tidak ada refresh token**; sesi berakhir setelah 1 jam, user login ulang. |
| Hapus | `token_storage.dart:31` | Logout, hapus akun, 401, dan token rusak. |

---

## 25. Tabel route & redirect

| Path | Layar | Kode |
| --- | --- | --- |
| `/splash` | `SplashPage` | `app_router.dart:52-55` |
| `/login` | `LoginPage` (query `email`) | `:56-61` |
| `/register` | `RegisterPage` | `:62-67` |
| `/profiles` | `ProfilesPage` | `:68-71` |
| `/home` | `HomePage` (branch 0) | `:76-83` |
| `/new` | `NewHotPage` (branch 1) | `:84-91` |
| `/my-list` | `MyListPage` (branch 2) | `:92-99` |
| `/profile` | `ProfilePage` (branch 3) | `:100-107` |
| `/search` | `SearchPage` | `:110-113` |
| `/profile/edit` | `EditProfilePage` | `:114-117` |
| `/movie/:id/play` | `PlayerPage` | `:118-123` |
| `/movie/:id` | `MovieDetailPage` | `:124-129` |
| `/admin` | `AdminMoviesPage` | `:130-133` |
| `/admin/movie` | `MovieFormPage` (opsional `extra: Movie`) | `:134-139` |

Aturan `redirect` (`app_router.dart:32-50`):

```
isLoading / hasError      → /splash
sesi null                 → /login   (kecuali sudah di /login atau /register)
sesi ada & di /login|/splash → /profiles
selain itu                → tetap
```

Bottom navigation: `lib/features/shell/presentation/app_shell.dart:14-20` mendefinisikan
4 tab; `StatefulShellRoute.indexedStack` menjaga state tiap tab.

---

## 26. Catatan & celah yang diketahui

1. **Expiry tidak dipantau saat app berjalan** — hanya di `build()` (startup) dan lewat 401.
2. **Tanpa refresh token** — sesi 1 jam, lalu login ulang.
3. **Signature JWT tidak diverifikasi** — `role` di klien hanya untuk tampilan.
4. **Guard admin di dalam halaman, bukan di router** — `/admin` masih bisa dibuka, isinya
   menolak; otorisasi sesungguhnya wajib di backend.
5. **Token dibaca dari storage tiap request** — `api_client.dart:26`, tidak ada cache memori.
6. **My List & Likes tidak tersinkron** — hanya `SharedPreferences`, per perangkat.
7. **Katalog tanpa paginasi** — satu `GET /api/movies`, semua turunan di klien.
8. **Tidak ada `GET /api/movies/:id`** — detail dicari dari cache katalog; film yang belum
   termuat tampil "tidak ditemukan".
9. **Kontrak response tidak seragam** — login memakai `token` top-level, profil dan upload
   memakai `data`.
10. **Default sudah HTTPS (dev tunnel)**, tetapi cleartext masih diizinkan untuk dev (Android
    `usesCleartextTraffic`, iOS `NSAllowsArbitraryLoads`) agar override `http://localhost:8000`
    tetap jalan. Jangan dipakai untuk produksi.
11. **Tunnel devtunnel butuh autentikasi.** Tanpa akses anonim, request klien dibalas `302`
    ke halaman login GitHub. Dio mengikuti redirect dan menerima HTML, sehingga
    `movie_repository.dart:13` (`data is! List`) mengembalikan list kosong: aplikasi tampil
    "Katalog masih kosong" **tanpa pesan error**. Jalankan tunnel dengan akses anonim atau
    kirim header token devtunnel.
12. **Edit profil mewajibkan password** setiap simpan (kebutuhan backend).
13. **Backend `../WEBDEV/kayflix-BE` tidak ada di mesin ini** — semua kontrak di atas adalah
    asumsi klien berdasarkan kode, bukan hasil pengujian terhadap server.

---

## 27. Verifikasi

Test yang sudah ada (`test/widget_test.dart`):

- `Movie.fromJson` — parsing normal (`:9-24`) dan toleransi field hilang (`:26-32`).
- `JwtPayload.tryParse` — klaim lengkap (`:42-55`), token kedaluwarsa (`:57-64`), token rusak
  (`:66-68`).

Perintah:

```bash
flutter analyze
flutter test
```

Pemeriksaan manual yang belum tercakup test otomatis:

1. Matikan backend → buka app → splash harus menampilkan error + tombol coba lagi.
2. Login → tutup app → buka lagi → harus langsung ke `/profiles`.
3. Ubah `exp` token di storage menjadi masa lalu → buka app → harus ke `/login`.
4. Hapus/ubah token agar server membalas 401 saat request → harus logout otomatis.
5. Login sebagai non-admin → menu "Kelola Film" tidak muncul; buka `/admin` manual → "Akses
   ditolak".
6. Tambah/edit/hapus film → daftar dan Home ikut berubah tanpa restart.
7. Simpan film di Daftar Saya → ganti akun → daftar harus terpisah per user.