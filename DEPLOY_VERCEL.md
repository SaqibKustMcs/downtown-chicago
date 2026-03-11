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
| **Build Command**  | `flutter build web` |
| **Output Directory** | `build/web` |
| **Install Command** | `git clone https://github.com/flutter/flutter.git -b stable --depth 1 .flutter_sdk && export PATH="$PATH:$(pwd)/.flutter_sdk/bin" && flutter doctor && flutter pub get` |

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
