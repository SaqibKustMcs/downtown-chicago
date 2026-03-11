# Deploy Flutter Web on Vercel

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
| **Build Command**  | `bash scripts/vercel-build.sh` |
| **Output Directory** | `build/web` |
| **Install Command** | *(leave empty)* |

The script `scripts/vercel-build.sh` installs Flutter and runs the web build **in the same shell**, so `flutter` is on PATH (avoids "flutter: command not found" on Vercel).

**Alternative (if you prefer separate install):** Set Install Command to:
`git clone https://github.com/flutter/flutter.git -b stable --depth 1 .flutter_sdk && ./.flutter_sdk/bin/flutter pub get`
and Build Command to:
`./.flutter_sdk/bin/flutter build web`
(Use the **full path** to `flutter` in the Build Command so it works even when PATH is not set.)

## 3. Deploy

Click **Deploy**. Vercel will install Flutter, run `flutter build web`, and serve `build/web` using `vercel.json` routes.

## 4. Optional: build locally and deploy only `build/web`

Faster and more reliable:

```bash
flutter build web
```

Then in Vercel, set **Output Directory** to `build/web` and use a static build (no install/build commands), or use Vercel CLI to deploy the `build/web` folder.

---

`vercel.json` in the project root configures static serving and SPA routing (all routes → `index.html`).
