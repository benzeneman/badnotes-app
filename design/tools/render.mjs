// Takes a picture of every mockup in design/screens with headless Chromium.
// Usage: node render.mjs <screens dir> <out dir>   (serves the screens on
// port 8765 itself). Runs on GitHub Actions: see design-shots.yml.
import { chromium } from 'playwright';
import { createServer } from 'node:http';
import { readFileSync, readdirSync, mkdirSync, existsSync } from 'node:fs';
import { join, extname } from 'node:path';

const [screens, out] = process.argv.slice(2);
const support = new URL('./support.js', import.meta.url);
mkdirSync(out, { recursive: true });

const server = createServer((req, res) => {
  const path = decodeURIComponent(new URL(req.url, 'http://x').pathname);
  const file = path === '/support.js' ? support : join(screens, path);
  if (!existsSync(file)) {
    res.writeHead(404).end();
    return;
  }
  const type = extname(String(file)) === '.js' ? 'text/javascript' : 'text/html';
  res.writeHead(200, { 'content-type': `${type}; charset=utf-8` });
  res.end(readFileSync(file));
}).listen(8765);

const browser = await chromium.launch();
const names = readdirSync(screens).filter((f) => f.endsWith('.dc.html')).sort();
for (const name of names) {
  const html = readFileSync(join(screens, name), 'utf8');
  const m = html.match(/"\$preview":\{"width":(\d+),"height":(\d+)\}/);
  const [width, height] = m ? [+m[1], +m[2]] : [1280, 800];
  const page = await browser.newPage({ viewport: { width, height }, deviceScaleFactor: 1 });
  page.on('console', (msg) => {
    if (msg.type() === 'error') console.log(`${name}: ${msg.text()}`);
  });
  await page.goto(`http://localhost:8765/${name}`, { waitUntil: 'networkidle' });
  await page.waitForSelector('body[data-rendered]', { timeout: 10000 }).catch(() =>
    console.log(`${name}: not rendered`),
  );
  await page.evaluate(() => document.fonts.ready);
  await page.screenshot({
    path: join(out, name.replace('.dc.html', '.png')),
    clip: { x: 0, y: 0, width, height },
  });
  await page.close();
}
await browser.close();
server.close();
console.log(`rendered ${names.length} screens`);
