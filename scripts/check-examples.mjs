/**
 * Проверка всех примеров курса на реальном компиляторе Mojo.
 *
 * Каждый пример — это файл `examples/**\/*.mojo` и лежащий рядом файл
 * `<имя>.out` с ожидаемым выводом. Скрипт запускает пример и сравнивает
 * фактический вывод с ожидаемым.
 *
 * Запуск локально (внутри WSL или Linux/macOS, где установлен Mojo):
 *   npm run examples:check
 *
 * В CI этот же скрипт запускается на каждый pull request и раз в неделю
 * по расписанию: если Mojo обновится и что-то сломается, мы узнаем об этом
 * раньше читателей.
 */
import { readdirSync, readFileSync, existsSync, statSync } from 'node:fs';
import { join, extname } from 'node:path';
import { execFileSync } from 'node:child_process';

const ROOT = new URL('../examples/', import.meta.url).pathname;
const MOJO = process.env.MOJO_CMD ?? 'mojo';

/** Рекурсивно собирает все .mojo файлы. */
function collect(dir) {
  const out = [];
  for (const name of readdirSync(dir)) {
    const full = join(dir, name);
    if (statSync(full).isDirectory()) out.push(...collect(full));
    else if (extname(name) === '.mojo') out.push(full);
  }
  return out;
}

/** Нормализуем перевод строки и хвостовые пробелы — они не значимы. */
const norm = (s) =>
  s
    .replace(/\r\n/g, '\n')
    .split('\n')
    .map((l) => l.trimEnd())
    .join('\n')
    .trim();

if (!existsSync(ROOT)) {
  console.log('Папка examples/ не найдена — нечего проверять.');
  process.exit(0);
}

const files = collect(ROOT);
let failed = 0;

for (const file of files) {
  const expectedFile = file.replace(/\.mojo$/, '.out');
  const rel = file.slice(ROOT.length);

  if (!existsSync(expectedFile)) {
    console.error(`✗ ${rel}: нет файла с ожидаемым выводом (${rel.replace(/\.mojo$/, '.out')})`);
    failed++;
    continue;
  }

  let actual;
  try {
    actual = execFileSync(MOJO, [file], { encoding: 'utf-8', timeout: 120_000 });
  } catch (error) {
    console.error(`✗ ${rel}: пример не компилируется или падает`);
    console.error(String(error.stderr ?? error.message).trim());
    failed++;
    continue;
  }

  const expected = readFileSync(expectedFile, 'utf-8');
  if (norm(actual) !== norm(expected)) {
    console.error(`✗ ${rel}: вывод отличается от ожидаемого`);
    console.error('  ожидалось:', JSON.stringify(norm(expected)));
    console.error('  получено: ', JSON.stringify(norm(actual)));
    failed++;
    continue;
  }

  console.log(`✓ ${rel}`);
}

console.log(`\nПроверено примеров: ${files.length}, ошибок: ${failed}`);
process.exit(failed > 0 ? 1 : 0);
