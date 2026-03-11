# Understanding Vercel's NOT_FOUND (404) for Flutter Web

This guide explains why you saw `404: NOT_FOUND` on Vercel and how to fix and avoid it.

---

## 1. The fix

### What was changed

1. **`vercel.json`**  
   - Added **`"outputDirectory": "build/web"`** so Vercel knows where your built Flutter web files live.  
   - Kept **`rewrites`** so any path that doesn’t match a real file is served with `index.html` (SPA behavior).

2. **Vercel project settings (Dashboard)**  
   Make sure these match:

   | Setting | Value |
   |--------|--------|
   | **Framework Preset** | `Other` |
   | **Root Directory** | *(empty)* |
   | **Build Command** | `flutter build web` |
   | **Output Directory** | `build/web` |
   | **Install Command** | `git clone https://github.com/flutter/flutter.git -b stable --depth 1 .flutter_sdk && export PATH="$PATH:$(pwd)/.flutter_sdk/bin" && flutter doctor && flutter pub get` |

3. **Deployment logs**  
   In Vercel: Project → **Deployments** → latest deployment → **Building** / **Logs**.  
   Confirm:
   - Install step runs and Flutter is available.
   - Build step runs `flutter build web` and finishes without errors.
   - Output is taken from `build/web` (you should see that path in the logs).

If the build fails or the output directory is wrong, Vercel has nothing to serve → **404 NOT_FOUND**.

---

## 2. Root cause

### What was going wrong

- **What the code / config was doing**  
  - Rewrites were set so that `/(.*)` → `/index.html`, which is correct for an SPA.  
  - The **location of the built files** was not clearly defined in the project (only in the dashboard). If the dashboard had a typo, wrong path, or the build never ran, Vercel would look for files in the wrong place or in an empty directory.

- **What was needed**  
  - The **build** must run (`flutter build web`) and produce a `build/web` folder containing `index.html`, `main.dart.js`, `flutter.js`, assets, etc.  
  - Vercel must use **that folder** as the deployment root (so `/` serves `build/web/index.html`, `/main.dart.js` serves `build/web/main.dart.js`, etc.).  
  - Any request that doesn’t match a real file (e.g. `/login`, `/home`) must be **rewritten** to `/index.html` so Flutter’s router can handle it.

- **What triggered NOT_FOUND**  
  - Either:  
    - The deployment had **no built output** (build failed, or output directory misconfigured), or  
    - The **root URL or a deep link** was requested and Vercel couldn’t find a file at that path and didn’t fall back to `index.html` (e.g. rewrites not applied or wrong output directory).

- **Misconception / oversight**  
  - Assuming that “rewrites to index.html” alone is enough, without ensuring the **build actually runs** and that Vercel is serving from **`build/web`**.  
  - Relying only on the dashboard and not making the output directory explicit in `vercel.json`.

---

## 3. Underlying concept

### Why this error exists

- **404 NOT_FOUND** means: “I looked for a resource at this path and didn’t find it.”  
- For a static/SPA deploy, the “resource” is either:
  - A **file** in the output directory (e.g. `index.html`, `main.dart.js`), or  
  - A **route** that you’ve said should be handled by a single page (e.g. `index.html` via rewrites).

- So the error is “protecting” you from serving something that isn’t there: wrong path, failed build, or misconfigured output.

### Correct mental model

1. **Build** produces a tree of files (e.g. `build/web/`).  
2. **Output directory** tells Vercel: “This folder is the deployment root.”  
   - `/` → `outputDirectory/index.html`  
   - `/main.dart.js` → `outputDirectory/main.dart.js`  
   - etc.  
3. **Rewrites** run when no file matches: “Send this request to this path instead.”  
   - So `/login` → no file → rewrite to `/index.html` → Flutter handles `/login`.

If the output directory is wrong or empty, step 2 fails → NOT_FOUND.

### How it fits

- Vercel is a **static/hybrid** host: it prefers to serve **files** from the output directory, then apply **rewrites** for SPA fallback.  
- Flutter web is a **single-page app**: one `index.html` and JS/assets; routing is client-side.  
- So you must: (1) give Vercel the right output directory, (2) add a rewrite so all non-file paths serve `index.html`.

---

## 4. Warning signs and similar mistakes

### What to watch for

- **404 on the root URL (`/`)**  
  Usually means: no `index.html` in the deployment → build failed or wrong output directory.

- **404 only on deep links (e.g. `/dashboard`), root works**  
  Usually means: rewrites not applied or wrong (e.g. old `routes` instead of `rewrites`).

- **Build logs show “Build completed” but no `build/web`**  
  Wrong build command or output path; Vercel might be uploading from a different folder.

### Similar pitfalls

- **Trailing slash**  
  `build/web` vs `build/web/` — use `build/web` (no trailing slash) in both `vercel.json` and the dashboard.

- **Root Directory**  
  If you set Root Directory (e.g. `app`), then “Output Directory” is relative to that. So you might need `app/build/web` or adjust so that `flutter build web` runs from that root and produces `build/web` there.

- **Other hosts (Netlify, Firebase Hosting)**  
  Same idea: you must set the **publish directory** to the Flutter web build output and configure **rewrites/redirects** so all routes serve `index.html`.

### Code smells / config smells

- `vercel.json` has rewrites but no `outputDirectory` → easy to have a mismatch with the dashboard.  
- No mention of `build/web` in docs or config → future you (or a teammate) might change the dashboard and break the deploy.

---

## 5. Alternatives and trade-offs

| Approach | Trade-off |
|----------|-----------|
| **Build on Vercel** (current: Install + Build + Output `build/web`) | Correct and reproducible. Slower deploys and depends on Flutter install in the environment. |
| **Build locally, deploy only `build/web`** | Faster, more reliable builds; no Flutter on Vercel. You must run `flutter build web` and commit/deploy that folder (or use a small script/CI that builds then deploys). |
| **Put `outputDirectory` only in Dashboard** | Works, but not visible in the repo; easy to break when someone creates a new project from the same repo. |
| **Put `outputDirectory` in `vercel.json`** (recommended) | Single source of truth in the repo; survives project re-imports and documents intent. |

Recommended: keep **`outputDirectory` and rewrites in `vercel.json`**, and align the Vercel project settings with that. Optionally move to “build locally and deploy `build/web`” later if you want faster, simpler deploys.

---

## Quick checklist

- [ ] `vercel.json` has `"outputDirectory": "build/web"` and `rewrites` to `/index.html`.
- [ ] Dashboard: Build Command = `flutter build web`, Output Directory = `build/web`, Install Command installs Flutter and runs `flutter pub get`.
- [ ] Latest deployment logs show a successful build and that files are served from `build/web`.
- [ ] Root URL and a deep link (e.g. `/login`) both load the app (no 404).
