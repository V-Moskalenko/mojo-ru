import { chromium } from 'playwright';
import { createServer } from 'node:http';
import { readFileSync, existsSync, statSync } from 'node:fs';
import { join, extname } from 'node:path';

const DIST = new URL('../dist/', import.meta.url).pathname;
const MIME = {
  '.html': 'text/html',
  '.css': 'text/css',
  '.js': 'text/javascript',
  '.svg': 'image/svg+xml',
  '.woff2': 'font/woff2',
  '.json': 'application/json',
  '.png': 'image/png',
};

const server = createServer((req, res) => {
  // сайт собирается с базовым путём (GitHub Pages), локально отдаём как есть
  const raw = decodeURIComponent(req.url.split('?')[0]).replace(/^\/mojo-ru/, '') || '/';
  let p = join(DIST, raw);
  if (existsSync(p) && statSync(p).isDirectory()) p = join(p, 'index.html');
  if (!existsSync(p)) {
    res.writeHead(404);
    return res.end('404');
  }
  res.writeHead(200, { 'Content-Type': MIME[extname(p)] ?? 'application/octet-stream' });
  res.end(readFileSync(p));
});
await new Promise((r) => server.listen(4321, r));

const browser = await chromium.launch({
  executablePath: '/opt/pw-browsers/chromium-1194/chrome-linux/chrome',
});
const shots = [
  ['/mojo-ru/', 'home', 1440, 1000],
  ['/mojo-ru/install/windows-wsl/', 'install', 1440, 1200],
  ['/mojo-ru/basics/first-program/', 'first-program', 1440, 1200],
  ['/mojo-ru/python-to-mojo/outdated/', 'outdated', 1440, 1100],
  ['/mojo-ru/basics/first-program/', 'mobile', 420, 900],
];
for (const [url, name, w, h] of shots) {
  const page = await browser.newPage({ viewport: { width: w, height: h }, deviceScaleFactor: 2 });
  await page.goto('http://localhost:4321' + url, { waitUntil: 'networkidle' });
  await page.waitForTimeout(600);
  await page.screenshot({ path: `../shots/${name}.png` });
  await page.close();
}
// светлая тема
const page = await browser.newPage({
  viewport: { width: 1440, height: 1100 },
  deviceScaleFactor: 2,
});
await page.goto('http://localhost:4321/mojo-ru/basics/first-program/', {
  waitUntil: 'networkidle',
});
await page.evaluate(() => (document.documentElement.dataset.theme = 'light'));
await page.waitForTimeout(400);
await page.screenshot({ path: '../shots/light.png' });
await browser.close();
server.close();
console.log('готово');
