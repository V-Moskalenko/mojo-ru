/**
 * Сообщает поисковикам об изменённых страницах по протоколу IndexNow.
 *
 * IndexNow поддерживают Яндекс и Bing (https://www.indexnow.org/): вместо
 * того чтобы ждать, пока робот сам заглянет на сайт, мы сразу после
 * публикации говорим, какие адреса обновились. Для молодого сайта это
 * заметно ускоряет попадание новых глав в выдачу. Google протокол
 * не поддерживает — ему хватает карты сайта с честным lastmod.
 *
 * Отправляются не все страницы, а только те, у которых lastmod в собранной
 * карте сайта новее момента, переданного в INDEXNOW_SINCE (ISO-дата —
 * в CI это время предыдущего опубликованного коммита). Без INDEXNOW_SINCE
 * скрипт только печатает, что отправил бы.
 *
 * Ключ — публичный по замыслу протокола: файл public/<ключ>.txt доказывает,
 * что адреса присылает владелец сайта.
 *
 *   INDEXNOW_SINCE=2026-11-01T00:00:00Z node scripts/indexnow.mjs
 */
import { readFileSync, existsSync } from 'node:fs';

const KEY = 'cce2cfb808704781bc597d04b05c0eb0';
const SITE = process.env.SITE_URL ?? 'https://mojo-lang.ru';
const SITEMAP = new URL('../dist/sitemap-0.xml', import.meta.url);

if (!existsSync(SITEMAP)) {
  console.error('Нет dist/sitemap-0.xml — сначала соберите сайт: npm run build');
  process.exit(1);
}

const xml = readFileSync(SITEMAP, 'utf-8');
const pages = [...xml.matchAll(/<url><loc>([^<]+)<\/loc>(?:<lastmod>([^<]+)<\/lastmod>)?/g)].map(
  ([, loc, lastmod]) => ({ loc, lastmod: lastmod ? new Date(lastmod) : undefined })
);

const since = process.env.INDEXNOW_SINCE ? new Date(process.env.INDEXNOW_SINCE) : undefined;
if (since && Number.isNaN(since.getTime())) {
  console.error(`INDEXNOW_SINCE не похоже на дату: ${process.env.INDEXNOW_SINCE}`);
  process.exit(1);
}

const changed = pages
  .filter(({ lastmod }) => !since || !lastmod || lastmod > since)
  .map(({ loc }) => loc);

if (!since) {
  console.log(`INDEXNOW_SINCE не задан — ничего не отправляю. Страниц в карте: ${pages.length}.`);
  process.exit(0);
}

if (changed.length === 0) {
  console.log('Изменённых страниц нет — поисковикам сообщать нечего.');
  process.exit(0);
}

const response = await fetch('https://api.indexnow.org/indexnow', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json; charset=utf-8' },
  body: JSON.stringify({
    host: new URL(SITE).host,
    key: KEY,
    keyLocation: `${SITE}/${KEY}.txt`,
    urlList: changed,
  }),
});

console.log(
  `IndexNow: ${response.status} ${response.statusText}, отправлено адресов: ${changed.length}`
);
for (const url of changed) console.log(`  ${url}`);

// 200 и 202 — принято. Всё остальное не должно ронять публикацию:
// сайт уже выложен, а робот всё равно придёт по карте сайта.
if (response.status !== 200 && response.status !== 202) {
  console.warn('Поисковик не принял список — обход по карте сайта это не отменяет.');
}
