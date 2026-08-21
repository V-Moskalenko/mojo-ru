/**
 * Генератор иконок сайта из одного источника — src/assets/icon.svg.
 *
 *   node scripts/make-icons.mjs
 *
 * Что получается и зачем:
 *
 *   favicon.svg          — современные браузеры, векторная, масштабируется;
 *   favicon.ico          — старые браузеры и выдача поисковиков (16/32/48);
 *   apple-touch-icon.png — 180×180, ярлык на домашнем экране iPhone и iPad;
 *   icon-192.png         — Android и вкладки Chrome;
 *   icon-512.png         — установка как приложение, крупные плитки;
 *   icon-maskable.png    — Android с обрезкой под форму системы: рисунок
 *                          сдвинут внутрь, чтобы при обрезке в круг ничего
 *                          важного не отрезали.
 *
 * ICO собирается из трёх PNG утилитой ImageMagick (`convert`), она есть
 * в образе сборки. Если её нет — скрипт честно об этом скажет.
 */
import sharp from 'sharp';
import { readFileSync, writeFileSync, unlinkSync } from 'node:fs';
import { execFileSync } from 'node:child_process';

const SRC = new URL('../src/assets/icon.svg', import.meta.url);
const OUT = new URL('../public/', import.meta.url);

const source = readFileSync(SRC);

/** Кладёт PNG нужного размера в public/. */
async function png(name, size, input = source) {
  const path = new URL(name, OUT).pathname;
  await sharp(input, { density: 384 }).resize(size, size).png({ compressionLevel: 9 }).toFile(path);
  console.log(`✓ ${name} (${size}×${size})`);
}

/**
 * Маскируемая иконка: система может обрезать её в круг или каплю.
 * Безопасная зона — центральные 80%, поэтому рисунок ужимаем и подкладываем
 * сплошной фон вместо скруглённого квадрата.
 */
async function maskable(name, size) {
  const inner = Math.round(size * 0.78);
  const pad = Math.round((size - inner) / 2);
  const art = await sharp(source, { density: 384 }).resize(inner, inner).png().toBuffer();

  await sharp({
    create: {
      width: size,
      height: size,
      channels: 4,
      background: '#1B1714',
    },
  })
    .composite([{ input: art, top: pad, left: pad }])
    .png({ compressionLevel: 9 })
    .toFile(new URL(name, OUT).pathname);

  console.log(`✓ ${name} (${size}×${size}, с полями под обрезку)`);
}

/** Собирает favicon.ico из трёх размеров. */
function ico(sizes) {
  const parts = sizes.map((size) => new URL(`favicon-${size}.png`, OUT).pathname);
  const target = new URL('favicon.ico', OUT).pathname;
  try {
    execFileSync('convert', [...parts, target], { stdio: 'pipe' });
    console.log(`✓ favicon.ico (${sizes.join(', ')})`);
  } catch (error) {
    console.error('✗ не удалось собрать favicon.ico: нужна утилита ImageMagick (convert)');
    throw error;
  } finally {
    for (const part of parts) unlinkSync(part);
  }
}

// Векторная иконка отдаётся как есть — она же источник.
writeFileSync(new URL('favicon.svg', OUT).pathname, source);
console.log('✓ favicon.svg');

const ICO_SIZES = [16, 32, 48];
for (const size of ICO_SIZES) await png(`favicon-${size}.png`, size);
ico(ICO_SIZES);

await png('apple-touch-icon.png', 180);
await png('icon-192.png', 192);
await png('icon-512.png', 512);
await maskable('icon-maskable-512.png', 512);
