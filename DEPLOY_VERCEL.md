# Deploy Flutter Web to Vercel

**Recommended:** Build locally and deploy the `build/web` folder. Vercel does not have Flutter installed, so building on Vercel often fails or is slow.

---

## ✅ Recommended: Build locally + Vercel CLI (~30 seconds)

### 1. Build Flutter web

```bash
flutter build web --web-renderer html
```

This creates `build/web/`.

### 2. Install Vercel CLI (one time)

```bash
npm install -g vercel
```

### 3. Deploy

From the project root:

```bash
./scripts/deploy-vercel.sh
```

Or manually:

```bash
flutter build web --web-renderer html
cp config/vercel-build-web.json build/web/vercel.json
cd build/web
vercel
```

For production:

```bash
cd build/web
vercel --prod
```

The script copies `config/vercel-build-web.json` into `build/web/vercel.json` so SPA routing works (no 404 on refresh).

---

## Alternative: GitHub auto-deploy (build on Vercel)

If you want Vercel to build from GitHub, configure the project:

| Setting | Value |
|--------|--------|
| **Build Command** | `bash scripts/vercel-build.sh` |
| **Output Directory** | `build/web` |
| **Install Command** | *(leave empty)* |

The script `scripts/vercel-build.sh` installs Flutter and runs the build in one shell. This can fail on Vercel (memory/time) — if so, use the recommended local build above.

---

## Other platforms

Flutter web is often easier on:

- **Firebase Hosting** – `firebase deploy` after `flutter build web`
- **Netlify** – drag-and-drop `build/web` or connect repo with build command
- **Cloudflare Pages** – connect repo, build command `flutter build web`, output `build/web`

---

## Root `vercel.json`

The `vercel.json` in the project root is used when the repo is connected to Vercel and build runs on their side. For the “deploy only build/web” flow, the config is in `build/web/vercel.json` (copied from `config/vercel-build-web.json` by the script).
