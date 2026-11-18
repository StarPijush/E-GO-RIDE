# E-GO Workspace Cleanup Plan & Strategy

**Workspace Root:** `D:\E-RICKSHAW RIDE`  
**Date:** November 18, 2026  
**Auditor / Architect:** E-GO Engineering System  
**Status:** Approved for Staging & Execution  

---

## 1. Classification of Workspace Artifacts

| Category | Description | Policy / Action |
|---|---|---|
| **1. Essential source files** | Dart code in `E-go/lib/`, TypeScript/React code in `E-go-web/src/`, HTML/assets in `E-go/web/` | **KEEP & STAGE** |
| **2. Essential configuration files** | `pubspec.yaml`, `pubspec.lock`, `package.json`, `package-lock.json`, `tsconfig.json`, `next.config.ts`, `analysis_options.yaml` | **KEEP & STAGE** |
| **3. Actual test source files** | Dart tests in `E-go/test/` (`unit/`, `widget/`, `integration/`, `helpers/`), web tests in `E-go-web/` | **KEEP & STAGE** (Fixed earlier ignore bug) |
| **4. Important project documentation** | Monorepo architecture, booking flow, help support, navigation, web docs in `docs/` and `E-go/docs/` | **KEEP & STAGE** |
| **5. Intentional design references and assets** | Brand images, fonts, destination photos, web public assets | **KEEP & STAGE** |
| **6. Generated artifacts** | `build/`, `.dart_tool/`, `.next/`, `node_modules/`, `test/screenshots/` | **IGNORE** via `.gitignore` |
| **7. Temporary development files** | `*.log`, `*.tmp`, `*.bak`, `.DS_Store`, `Thumbs.db` | **IGNORE** via `.gitignore` |
| **8. Redundant documentation** | Exact duplicates, temporary scratch notes | **CONSOLIDATE / EXCLUDE** |
| **9. Sensitive files** | `.env.local`, credentials, keystores | **NEVER COMMIT** (Ignored by `.gitignore`) |
| **10. Files requiring manual review** | `rapido-analysis/`, `toto-go-blueprint/`, `EGO-AGENT-INSTRUCTIONS.md` | **PRESERVE ON DISK, KEEP GITIGNORED** |

---

## 2. Key Action Items

### Step 1: Gitignore Refinement (COMPLETED)
- Removed harmful `test/`, `**/test/`, `tests/`, `*.test.*` patterns from root and nested `.gitignore`.
- Removed global blanket `web/` ignore to preserve `E-go/web/index.html` and assets.
- Added explicit ignore rules for generated test screenshots (`**/test/screenshots/`).
- Added robust ignore rules for Next.js, Flutter build, Node modules, and Python caches.

### Step 2: Unstage False Deletions (COMPLETED)
- Unstaged mistakenly staged deletions of `E-go-admin/test/.gitkeep`, `E-go-rider/test/.gitkeep`, `backend/tests/.gitkeep`, and original test files.
- Preserved existing test suites on disk.

### Step 3: Markdown Documentation Audit & Alignment
- Retain all 36 active project Markdown documents across `docs/`, `E-go/docs/`, and `E-go-web/`.
- Update root `README.md` to accurately describe the entire monorepo, including `E-go-web`, architecture, and clear separation of implemented vs planned features.
- Maintain competitive research (`rapido-analysis/`) and blueprint (`toto-go-blueprint/`) safely excluded from public tracking.

### Step 4: Staging Strategy
- Stage modified Flutter files and new assets/fonts: `git add E-go/`
- Stage new Next.js web application: `git add E-go-web/`
- Stage documentation updates: `git add docs/`
- Stage root configuration: `git add .gitignore README.md`
- Verify staged diff with `git diff --cached --stat` to guarantee no secrets, node_modules, or build files are included.

### Step 5: Local Git Commit
- Execute local commit: `chore: prepare E-GO monorepo for GitHub`
- **DO NOT push to remote.**
