/**
 * Генератор картинки для соцсетей (Open Graph, 1200×630).
 * Ссылку на курс будут кидать в Telegram, на Хабр и в чаты — превью решает,
 * откроют её или пролистают.
 *
 *   node scripts/make-og.mjs
 */
import sharp from 'sharp';
import { readFileSync, writeFileSync } from 'node:fs';

const flame = readFileSync(new URL('../src/assets/logo.svg', import.meta.url), 'utf-8')
  .replace(/<\?xml[^>]*\?>/, '')
  .replace(/width="\d+"\s*height="\d+"/, 'width="180" height="180"')
  .replace(/id="f"/g, 'id="flame"')
  .replace(/url\(#f\)/g, 'url(#flame)');

const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="630" viewBox="0 0 1200 630">
  <defs>
    <linearGradient id="bg" x1="0" y1="0" x2="1200" y2="630" gradientUnits="userSpaceOnUse">
      <stop stop-color="#14110F"/>
      <stop offset="1" stop-color="#241B14"/>
    </linearGradient>
    <linearGradient id="title" x1="90" y1="0" x2="900" y2="0" gradientUnits="userSpaceOnUse">
      <stop stop-color="#FDFAF7"/>
      <stop offset="1" stop-color="#FF9A5C"/>
    </linearGradient>
  </defs>

  <rect width="1200" height="630" fill="url(#bg)"/>
  <rect x="0" y="0" width="1200" height="6" fill="#FF7A2F"/>

  <g transform="translate(90, 150)">${flame}</g>

  <text x="310" y="250" font-family="Inter, Arial, sans-serif" font-size="82" font-weight="700"
        letter-spacing="-2" fill="url(#title)">Mojo по-русски</text>

  <text x="312" y="320" font-family="Inter, Arial, sans-serif" font-size="34" fill="#C6BFB9">
    Полный курс по языку Mojo 1.0 на русском языке
  </text>

  <g transform="translate(312, 380)">
    <rect x="0" y="0" width="196" height="44" rx="22" fill="#2A2521" stroke="#433D38"/>
    <text x="24" y="29" font-family="Inter, Arial, sans-serif" font-size="20" fill="#FF9A5C">Mojo 1.0 · 2026</text>
    <rect x="216" y="0" width="270" height="44" rx="22" fill="#2A2521" stroke="#433D38"/>
    <text x="240" y="29" font-family="Inter, Arial, sans-serif" font-size="20" fill="#C6BFB9">Windows · WSL · VS Code</text>
  </g>

  <text x="312" y="500" font-family="Inter, Arial, sans-serif" font-size="24" fill="#9A918A">
    Бесплатно и открыто · mojo-lang.ru
  </text>
</svg>`;

const out = new URL('../public/og.png', import.meta.url).pathname;
writeFileSync(new URL('../public/og.svg', import.meta.url).pathname, svg);
await sharp(Buffer.from(svg)).png().toFile(out);

console.log('Готово:', out);
