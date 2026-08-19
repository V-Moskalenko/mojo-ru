/**
 * Проверка кода курса на настоящем компиляторе Mojo.
 *
 * Две части:
 *
 * 1. Файлы `examples/**\/*.mojo` — запускаются, вывод сверяется с лежащим
 *    рядом файлом `<имя>.out`.
 * 2. Полные примеры прямо из текста глав — все блоки ```mojo, содержащие
 *    `def main`, компилируются. Так код на сайте не может разойтись
 *    с реальностью, даже если его забыли вынести в examples/.
 *
 * Запуск локально (Linux, macOS или WSL с установленным Mojo):
 *   npm run examples:check
 *
 * Явный путь к компилятору:
 *   MOJO_CMD=/путь/к/.venv/bin/mojo npm run examples:check
 *
 * В CI то же самое запускается на каждый pull request и раз в неделю
 * по расписанию: если Mojo обновится и что-то сломается, мы узнаем об этом
 * раньше читателей.
 */
import {
  readdirSync,
  readFileSync,
  existsSync,
  statSync,
  writeFileSync,
  unlinkSync,
} from 'node:fs';
import { join, extname, relative } from 'node:path';
import { execFileSync } from 'node:child_process';
import { tmpdir } from 'node:os';

const ROOT = new URL('../', import.meta.url).pathname;
const EXAMPLES = join(ROOT, 'examples');
const DOCS = join(ROOT, 'src/content/docs');
const MOJO = process.env.MOJO_CMD ?? 'mojo';

/**
 * Главы, где код намеренно НЕ должен компилироваться: там показаны
 * устаревшие конструкции из версий до 1.0 — в этом и смысл страницы.
 */
const SKIP_FILES = ['python-to-mojo/outdated.mdx'];

/** Рекурсивно собирает файлы с нужным расширением. */
function collect(dir, ext) {
  if (!existsSync(dir)) return [];
  const out = [];
  for (const name of readdirSync(dir)) {
    const full = join(dir, name);
    if (statSync(full).isDirectory()) out.push(...collect(full, ext));
    else if (extname(name) === ext) out.push(full);
  }
  return out;
}

/** Перевод строки и хвостовые пробелы не значимы. */
const norm = (s) =>
  s
    .replace(/\r\n/g, '\n')
    .split('\n')
    .map((line) => line.trimEnd())
    .join('\n')
    .trim();

/** Запускает mojo и возвращает { ok, stdout, stderr }. */
function runMojo(file) {
  try {
    const stdout = execFileSync(MOJO, [file], {
      encoding: 'utf-8',
      timeout: 300_000,
      stdio: ['ignore', 'pipe', 'pipe'],
    });
    return { ok: true, stdout, stderr: '' };
  } catch (error) {
    return {
      ok: false,
      stdout: String(error.stdout ?? ''),
      // предупреждение про Crashpad появляется в контейнерах и ни на что не влияет
      stderr: String(error.stderr ?? error.message)
        .split('\n')
        .filter((line) => !line.includes('Crashpad'))
        .join('\n'),
    };
  }
}

let failed = 0;
let checked = 0;

// --- 1. Примеры-файлы: компилируются, запускаются, вывод сверяется ---------

for (const file of collect(EXAMPLES, '.mojo')) {
  const rel = relative(EXAMPLES, file);
  const expectedFile = file.replace(/\.mojo$/, '.out');

  // Файлы без точки входа — это модули многофайлового примера. Запустить их
  // отдельно нельзя (`module does not define a 'main' function`), но они
  // проверяются вместе с той программой, которая их импортирует.
  if (!/\bdef main\b/.test(readFileSync(file, 'utf-8'))) {
    console.log(`· ${rel}: модуль, проверяется через импорт`);
    continue;
  }

  checked++;

  if (!existsSync(expectedFile)) {
    console.error(`✗ ${rel}: нет файла с ожидаемым выводом`);
    failed++;
    continue;
  }

  const result = runMojo(file);
  if (!result.ok) {
    console.error(`✗ ${rel}: не компилируется или падает`);
    console.error(result.stderr.trim());
    failed++;
    continue;
  }

  const expected = readFileSync(expectedFile, 'utf-8');
  if (norm(result.stdout) !== norm(expected)) {
    console.error(`✗ ${rel}: вывод отличается от ожидаемого`);
    console.error('  ожидалось:', JSON.stringify(norm(expected)));
    console.error('  получено: ', JSON.stringify(norm(result.stdout)));
    failed++;
    continue;
  }

  console.log(`✓ ${rel}`);
}

// --- 2. Полные примеры из текста глав: должны хотя бы компилироваться ------

for (const file of collect(DOCS, '.mdx')) {
  const rel = relative(DOCS, file);
  if (SKIP_FILES.includes(rel)) continue;

  const source = readFileSync(file, 'utf-8');
  const blocks = [...source.matchAll(/```mojo[^\n]*\n([\s\S]*?)```/g)]
    .map((match) => match[1])
    // фрагменты без точки входа компилировать нельзя — это куски кода,
    // а не программы
    .filter((code) => /\bdef main\b/.test(code));

  for (const [index, code] of blocks.entries()) {
    const tmp = join(tmpdir(), `mojo-ru-${process.pid}-${checked}.mojo`);
    writeFileSync(tmp, code, 'utf-8');
    checked++;

    const result = runMojo(tmp);
    unlinkSync(tmp);

    if (!result.ok) {
      console.error(`✗ ${rel} (блок кода #${index + 1}): не компилируется`);
      console.error(result.stderr.trim());
      failed++;
      continue;
    }

    console.log(`✓ ${rel} (блок кода #${index + 1})`);
  }
}

console.log(`\nПроверено: ${checked}, ошибок: ${failed}`);
process.exit(failed > 0 ? 1 : 0);
