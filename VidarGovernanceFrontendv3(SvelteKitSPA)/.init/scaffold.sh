#!/usr/bin/env bash
set -euo pipefail
# Idempotent scaffold for Vite + Svelte + TypeScript SPA (non-SvelteKit)
WORKSPACE="/home/kavia/workspace/code-generation/vidar-governance-frontend-v3-241585-241643/VidarGovernanceFrontendv3(SvelteKitSPA)"
cd "$WORKSPACE"
# Detect SvelteKit by explicit package.json dependency only
IS_SVELTEKIT=0
if [ -f package.json ]; then
  if node -e "try{const p=require('./package.json'); if((p.dependencies&&p.dependencies['@sveltejs/kit'])||(p.devDependencies&&p.devDependencies['@sveltejs/kit'])) process.exit(0); process.exit(1)}catch(e){process.exit(1)}" >/dev/null 2>&1; then IS_SVELTEKIT=1; fi
fi
if [ "$IS_SVELTEKIT" -eq 1 ]; then
  exit 0
fi
# Ensure package.json exists and add scripts idempotently
if [ ! -f package.json ]; then npm init -y >/dev/null; fi
node -e "const fs=require('fs');const p=JSON.parse(fs.readFileSync('package.json'));p.scripts=p.scripts||{};const want={dev:'vite',build:'vite build',preview:'vite preview --port 5173 --strictPort',test:'vitest'};let ch=false;Object.keys(want).forEach(k=>{if(!p.scripts[k]){p.scripts[k]=want[k];ch=true}});if(ch)fs.writeFileSync('package.json',JSON.stringify(p,null,2));" >/dev/null
# Files: only create if absent
[ -d src ] || mkdir -p src
[ -f src/main.ts ] || cat >src/main.ts <<'TS'
import App from './App.svelte';
const app = new App({ target: document.body });
export default app;
TS
[ -f src/App.svelte ] || cat >src/App.svelte <<'SVE'
<script lang="ts">let msg = 'Hello Vidar';</script>
<main><h1>{msg}</h1></main>
SVE
[ -f index.html ] || cat >index.html <<'HTML'
<!doctype html>
<html>
  <head><meta charset="utf-8"/><meta name="viewport" content="width=device-width,initial-scale=1.0"/></head>
  <body><script type="module" src="/src/main.ts"></script></body>
</html>
HTML
[ -f vite.config.ts ] || cat >vite.config.ts <<'VCFG'
import { defineConfig } from 'vite';
import { svelte } from '@sveltejs/vite-plugin-svelte';
export default defineConfig({plugins:[svelte()]});
VCFG
[ -f tsconfig.json ] || cat >tsconfig.json <<'TSJ'
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "ESNext",
    "moduleResolution": "node",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "jsx": "preserve"
  },
  "include": ["src/**/*"]
}
TSJ
# Minimal non-kit svelte config compatible with @sveltejs/vite-plugin-svelte
[ -f svelte.config.js ] || cat >svelte.config.js <<'SCFG'
// Minimal svelte config for Vite + @sveltejs/vite-plugin-svelte
module.exports = {
  preprocess: []
}
SCFG
[ -f .gitignore ] || cat >.gitignore <<'GIT'
node_modules
dist
.env
GIT
[ -f README.md ] || echo '# VidarGovernanceFrontendv3' > README.md
mkdir -p scripts && [ -f scripts/start.sh ] || cat >scripts/start.sh <<'SH'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$(dirname "$0")")"
npm run preview
SH
chmod +x scripts/start.sh || true
