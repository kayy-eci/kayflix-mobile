# Kayflix Mobile

A Netflix-style Flutter client for the Kayflix Express API
(`../WEBDEV/kayflix-BE`). Dark UI, hero banner, horizontal movie rows, search,
My List, profile management with Cloudinary avatar upload, and a role-gated
admin dashboard for the movie catalogue.

## Features

| Area | What it does |
| --- | --- |
| Auth | Login, register, session restore, auto sign-out on expired/invalid JWT |
| Home | Hero banner + Popular / Recommended / My List / Newest rows |
| Browse | Search by title, genre, or year, plus genre chips |
| New & Hot | Ranked "Top 10" list sorted by release year |
| Detail | Metadata, genres, similar titles, mock player |
| My List | Local favorites stored per user on device |
| Likes | Local thumbs-up stored per user on device |
| Profile | View account, edit username/email/password, upload avatar, delete account |
| Admin | Add / edit / delete movies (visible only when the JWT role is `admin`) |

## Backend prerequisites

The app talks to the Express backend at port `8000`.

1. Start MySQL and make sure the `db_express` database exists.
2. In `../WEBDEV/kayflix-BE`, create `.env` with `JWT_SECRET` and the
   Cloudinary keys, then run:

   ```bash
   npm install
   npm run dev
   ```

3. To test the admin screens, promote an account:

   ```sql
   UPDATE users SET role = 'admin' WHERE email = 'you@example.com';
   ```

4. Log out and log in again so the JWT contains the `admin` role.

> The backend stores passwords in plain text and has no video streaming
> endpoint. The Play button opens a simulated player; poster artwork is
> rendered as a deterministic gradient per movie.

## Running the app

The API base URL defaults to the dev tunnel:

- All platforms → `https://hfvwgq71-8000.asse.devtunnels.ms`

No trailing slash needed: Dio joins `baseUrl + path` and collapses the repeated
`//` that would otherwise appear (`dio` `options.dart`, `RequestOptions.uri`),
so either form works.

To point the app at a different backend, override it at build time:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000
```

Cleartext HTTP is still enabled for Android (`usesCleartextTraffic`) and iOS
(`NSAllowsArbitraryLoads`) so a local `http://` override keeps working.

> The tunnel must allow anonymous access. A private Dev Tunnel answers with a
> `302` to the GitHub sign-in page, and the client then sees an empty
> catalogue ("Katalog masih kosong") instead of an error. See
> `ALUR-APLIKASI.md` section 26, note 11.

### Useful commands

```bash
flutter pub get
flutter analyze
flutter test
flutter run
flutter build apk --debug
```

## Project structure

```
lib/
  core/                 config, networking, storage, theme, shared widgets
  features/
    auth/               splash, login, register, profile picker
    session/            JWT session controller + repository
    home/               hero and rows
    movies/             model, repository, detail, player
    new_hot/            ranked list
    search/             client-side search
    my_list/            local My List + likes
    profile/            profile and edit screens
    admin/              movie CRUD
    shell/              bottom navigation shell
  router/               go_router configuration and auth redirects
```

## API endpoints used

| Method | Endpoint | Purpose |
| --- | --- | --- |
| POST | `/api/auth/login` | Sign in, returns JWT |
| POST | `/api/auth/logout` | Sign out (no-op server side) |
| POST | `/api/users` | Register |
| GET | `/api/profile` | Current account |
| PUT | `/api/users/:id` | Update account |
| DELETE | `/api/users/:id` | Delete account |
| POST | `/api/users/:id/profile-image` | Avatar upload (`profileImage`) |
| GET | `/api/movies` | Catalogue |
| POST | `/api/movies` | Create movie (admin) |
| PUT | `/api/movies/:id` | Update movie (admin) |
| DELETE | `/api/movies/:id` | Delete movie (admin) |
