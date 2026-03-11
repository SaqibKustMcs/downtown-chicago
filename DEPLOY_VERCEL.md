# Deploy Flutter Web on Vercel

**Working setup:** Use the build script so Flutter is on PATH (fixes exit 127). Set Build Command in dashboard to `bash scripts/vercel-build.sh`, Install Command empty.

## 1. Import project

1. Go to [Vercel Dashboard](https://vercel.com/dashboard)
2. **Add New** → **Project**
3. Import your GitHub repo: `SaqibKustMcs/downtown-chicago`
4. Click **Import**

## 2. Build settings (in Vercel)

- **Framework Preset:** `Other`
- **Root Directory:** leave empty

| Setting            | Value |
|--------------------|--------|
| **Output Directory** | `build/web` |
| **Build Command**  | `bash scripts/vercel-build.sh` |
| **Install Command** | *(leave empty)* |

`vercel.json` in the repo already sets:
- **outputDirectory:** `build/web`
- **rewrites:** all routes → `/index.html` (SPA)

No need to override these in the dashboard unless you want to build on Vercel with the script below.

### Optional: build on Vercel (if "flutter: command not found")

If the build fails because `flutter` isn’t on PATH, use the single script so install and build run in the same shell:

| Setting            | Value |
|--------------------|--------|
| **Install Command** | *(leave empty)* |
| **Build Command**  | `bash scripts/vercel-build.sh` |

The script installs Flutter and runs `flutter build web --web-renderer html`.

## 3. Deploy

Click **Deploy**. Vercel will install Flutter, run `flutter build web`, and serve `build/web` using `vercel.json` routes.

## 4. Optional: build locally and deploy only `build/web` (recommended if Vercel build fails)

If the build fails on Vercel (e.g. "Failed to compile" or out of memory), build on your machine and deploy the output:

1. **Locally:** Run `flutter build web` (or `flutter build web --web-renderer html`).
2. **Deploy the folder:** In Vercel, set **Build Command** to empty, **Output Directory** to `build/web`, and **Install Command** to empty. Commit the `build/web` folder to a branch (e.g. `deploy`) and connect that branch, or use [Vercel CLI](https://vercel.com/docs/cli) to deploy only `build/web`:

   ```bash
   flutter build web
   cd build/web && vercel --prod
   ```

This avoids running Flutter on Vercel and is more reliable.

---

`vercel.json` in the project root configures static serving and SPA routing (all routes → `index.html`).
