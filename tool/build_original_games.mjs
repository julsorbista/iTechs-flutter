import fs from 'node:fs';
import path from 'node:path';
import {createRequire} from 'node:module';
import {fileURLToPath, pathToFileURL} from 'node:url';
const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const frontend = path.join(root, '.reference/mobile/Frontend');
const dependencies = path.join(root, '.reference/iTechs/Frontend');
const host = path.join(frontend, 'flutter-host');
fs.cpSync(path.join(root, 'tool/original_game_host'), host, {recursive:true});
const require = createRequire(path.join(dependencies, 'package.json'));
const {build} = await import(pathToFileURL(require.resolve('vite')));
const react = (await import(pathToFileURL(require.resolve('@vitejs/plugin-react')))).default;
const outDir = path.join(root, 'assets/original_games');
await build({configFile:false, root:host, base:'./', publicDir:false,
  plugins:[{
    name:'flutter-offline-services', enforce:'pre',
    async resolveId(id) {
      if (/(^|\/)utils\/api(\.js)?$/.test(id)) return path.join(host,'api.js');
      if (/(^|\/)context\/AuthContext(\.jsx)?$/.test(id)) return path.join(host,'auth.jsx');
      if (/games\/game-(two|four|six)\/ui\/GameCanvas/.test(id)) return path.join(host,'unused.jsx');
      // Flutter owns native orientation; no Capacitor runtime is mounted here.
      if (id === '@capacitor/core' || id === '@capacitor/screen-orientation') return path.join(host,'platform.js');
      if (id === 'phaser') return require.resolve('phaser/dist/phaser.js');
      // Reuse the already installed frontend build dependencies for this ZIP.
      if (/^[\w@]/.test(id) && !id.startsWith('@original') && !id.startsWith('@fontsource') && id !== '@flutter-levels') {
        try { return require.resolve(id); } catch { /* Let Vite resolve CSS and virtual imports. */ }
      }
    },
    transform(source,id) {
      if (id.replaceAll('\\','/').endsWith('/src/index.css')) return source.replace(/^@import url\([^\n]+\);\r?\n/m,'');
      // The ZIP gives Game 3 Game 2's scroll class too; landscape rules for
      // Game 2 then clip the memory screen to one viewport.
      if (id.replaceAll('\\','/').endsWith('/components/student/StudentGameOverlay.jsx')) {
        return source.replace('isGameTwo || isGameThree ? "student-game-overlay-game-two-scroll"', 'isGameTwo ? "student-game-overlay-game-two-scroll"');
      }
    },
  },react()],
  resolve:{alias:{'@original':path.join(frontend,'src'), '@flutter-levels':path.join(root,'assets/games/levels.json'), '@fontsource':path.join(root,'.reference/game-fonts/node_modules/@fontsource'), tailwindcss:path.join(dependencies,'node_modules/tailwindcss/index.css')}},
  css:{postcss:{plugins:[require('@tailwindcss/postcss')({base:frontend}), require('autoprefixer')()]}},
  build:{outDir,emptyOutDir:true,assetsInlineLimit:0,
    rollupOptions:{output:{entryFileNames:'game-[hash].js',chunkFileNames:'chunk-[hash].js',assetFileNames:'asset-[hash][extname]'}}},
});
console.log('Mobile ZIP game UI and Phaser runtime bundled locally at',outDir);
