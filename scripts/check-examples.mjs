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

// --- 2. Полные примеры из текста глав ------------------------------------
//
// Блок компилируется и запускается. Если сразу за ним стоит
// `<Result output={"..."} />`, вывод ещё и сверяется с этой строкой —
// иначе обещанный результат держался бы только на честном слове автора.
//
// Сверку можно отключить для блока, чей вывод меняется от запуска
// к запуску (замеры времени): поставьте перед `<Result>` строку-комментарий
// `{/* вывод-меняется */}`.

const UNSTABLE = '{/* вывод-меняется */}';

for (const file of collect(DOCS, '.mdx')) {
  const rel = relative(DOCS, file);
  if (SKIP_FILES.includes(rel)) continue;

  const source = readFileSync(file, 'utf-8');
  const blocks = [...source.matchAll(/```mojo[^\n]*\n([\s\S]*?)```/g)]
    .map((match) => ({ code: match[1], after: source.slice(match.index + match[0].length) }))
    // фрагменты без точки входа компилировать нельзя — это куски кода,
    // а не программы
    .filter((block) => /\bdef main\b/.test(block.code));

  for (const [index, block] of blocks.entries()) {
    const tmp = join(tmpdir(), `mojo-ru-${process.pid}-${checked}.mojo`);
    writeFileSync(tmp, block.code, 'utf-8');
    checked++;

    const result = runMojo(tmp);
    unlinkSync(tmp);

    if (!result.ok) {
      console.error(`✗ ${rel} (блок кода #${index + 1}): не компилируется`);
      console.error(result.stderr.trim());
      failed++;
      continue;
    }

    // Ищем <Result output={"..."} /> в ближайших строках после блока.
    const tail = block.after.slice(0, 400);
    const promised = tail.match(
      /^\s*(?:\{\/\*[^]*?\*\/\}\s*)?<Result output=\{"((?:[^"\\]|\\.)*)"\}\s*\/>/
    );

    if (promised && !tail.slice(0, promised[0].length).includes(UNSTABLE)) {
      const expected = JSON.parse(`"${promised[1]}"`);
      if (norm(result.stdout) !== norm(expected)) {
        console.error(`✗ ${rel} (блок кода #${index + 1}): вывод не совпадает с <Result>`);
        console.error('  обещано: ', JSON.stringify(norm(expected)));
        console.error('  получено:', JSON.stringify(norm(result.stdout)));
        failed++;
        continue;
      }
      console.log(`✓ ${rel} (блок кода #${index + 1}) + вывод`);
      continue;
    }

    console.log(`✓ ${rel} (блок кода #${index + 1})`);
  }
}

// --- 3. Фрагменты из глав: хотя бы разбираются ----------------------------
//
// Блок без `def main` запустить нельзя — ему не хватает окружения. Но
// грубые поломки поймать можно: если компилятор ругается не на отсутствие
// контекста, а на что-то другое, код в главе, скорее всего, сломан.
//
// Список ниже — то, что для вырванного из главы куска нормально: он может
// ссылаться на неопределённые имена, стоять вне функции, не иметь return.
// Всё остальное считается поломкой.

/** Ошибки, означающие «фрагменту не хватает окружения» — это нормально. */
const NEEDS_CONTEXT =
  /module does not define|unknown declaration|does not contain|unable to locate|has no attribute|no matching (function|method)|not implement|cannot implicitly convert|use of uninitialized|invalid call|constraint|cannot be converted|does not conform|lacking evidence|violated|recursive reference|non-'Deinitable'|capture convention|abandoned|unqualified access|dynamic value|materialize|implicitly copied|register passible|mutating method|invalid use|invalid bindings|cannot call|cannot use|failed to infer|global variables are not supported|must not appear at file scope|must be contained in a function|return expected at end|has no declaration|argument type must be specified|incompatible origin|expected ':' in function definition/i;

for (const file of collect(DOCS, '.mdx')) {
  const rel = relative(DOCS, file);
  if (SKIP_FILES.includes(rel)) continue;

  const fragments = [...readFileSync(file, 'utf-8').matchAll(/```mojo[^\n]*\n([\s\S]*?)```/g)]
    .map((match) => match[1])
    .filter((code) => !/\bdef main\b/.test(code));

  for (const [index, code] of fragments.entries()) {
    const tmp = join(tmpdir(), `mojo-ru-frag-${process.pid}-${checked}.mojo`);
    writeFileSync(tmp, code, 'utf-8');
    const result = runMojo(tmp);
    unlinkSync(tmp);

    if (!result.ok && !NEEDS_CONTEXT.test(result.stderr)) {
      console.error(`✗ ${rel} (фрагмент #${index + 1}): не разбирается`);
      console.error(result.stderr.trim());
      failed++;
    }
  }
}

console.log(`\nПроверено: ${checked}, ошибок: ${failed}`);
process.exit(failed > 0 ? 1 : 0);
