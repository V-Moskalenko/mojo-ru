/**
 * Проверка кода курса на настоящем компиляторе Mojo.
 *
 * Три части:
 *
 * 1. Файлы `examples/**\/*.mojo` — запускаются, вывод сверяется с лежащим
 *    рядом файлом `<имя>.out`.
 * 2. Полные примеры прямо из текста глав — все блоки ```mojo, содержащие
 *    `def main`, компилируются. Так код на сайте не может разойтись
 *    с реальностью, даже если его забыли вынести в examples/.
 * 3. Фрагменты без `def main` — хотя бы разбираются.
 * 4. Программы для видеокарты — ещё и собираются под GPU NVIDIA и AMD.
 * 5. Примеры ошибок (`examples/reference/compiler-errors`) — наоборот,
 *    обязаны упасть, и именно с тем сообщением, что записано в первой
 *    строке файла: `# ожидается: <текст>`. Так справочник ошибок на сайте
 *    не устареет: если Mojo поменяет формулировку, проверка это заметит.
 *    Видеокарты у CI нет, поэтому в шагах 1–2 ветка
 *    `comptime if has_accelerator()` для GPU только проверяется на типы,
 *    а собирается и запускается ветка для процессора. Флаг
 *    `--target-accelerator` заставляет компилятор собрать и ветку для GPU,
 *    вместе с ядрами, — запустить её нельзя, но собраться она обязана.
 *
 * Программе из examples/ можно передать аргументы командной строки: они
 * лежат рядом в файле <имя>.args (через пробел, без кавычек), а запускается
 * программа из своего каталога. Файлы test_*.mojo считаются тестами:
 * им достаточно завершиться с кодом 0. Файлы bench_*.mojo — замеры:
 * их вывод зависит от машины, поэтому он не сверяется; замер собирается,
 * а если рядом есть .args — ещё и запускается на маленьких данных.
 *
 * Везде предупреждение компилятора «deprecated» считается ошибкой: курс
 * не должен учить тому, что уже помечено к удалению.
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
import { join, extname, relative, basename, dirname } from 'node:path';
import { spawnSync } from 'node:child_process';
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

/** Строки stderr, которые ни на что не влияют. */
const quiet = (text) =>
  String(text ?? '')
    .split('\n')
    // предупреждение про Crashpad появляется в контейнерах и ни на что не влияет
    .filter((line) => !line.includes('Crashpad'))
    .join('\n');

/**
 * Запускает mojo и возвращает { ok, stdout, stderr }.
 * `args` — флаги компилятора (до имени файла), `programArgs` — аргументы
 * самой программы (после имени файла), `cwd` — рабочий каталог.
 */
function runMojo(file, args = [], { programArgs = [], cwd } = {}) {
  const run = spawnSync(MOJO, [...args, file, ...programArgs], {
    cwd,
    encoding: 'utf-8',
    timeout: 300_000,
    stdio: ['ignore', 'pipe', 'pipe'],
  });
  return {
    ok: run.status === 0,
    stdout: String(run.stdout ?? ''),
    stderr:
      quiet(run.stderr) ||
      String(run.error?.message ?? '') ||
      (run.status === 0 ? '' : `код выхода ${run.status}, сигнал ${run.signal}`),
  };
}

/**
 * Код курса не должен учить устаревшему: если компилятор предупреждает,
 * что конструкция deprecated, пример считается сломанным, даже когда
 * он компилируется и печатает правильный ответ.
 */
function deprecation(result) {
  const lines = result.stderr.split('\n').filter((line) => /deprecated/i.test(line));
  return lines.length ? lines.join('\n') : null;
}

let failed = 0;
let checked = 0;

/** Первая строка примера ошибки: `# ожидается: <текст сообщения>`. */
const EXPECT_PREFIX = '# ожидается: ';
/** Все ожидаемые сообщения — для сверки со справочником ошибок. */
const expectedErrors = [];

// --- 1. Примеры-файлы: компилируются, запускаются, вывод сверяется ---------

for (const file of collect(EXAMPLES, '.mojo')) {
  const rel = relative(EXAMPLES, file);
  const expectedFile = file.replace(/\.mojo$/, '.out');

  const source = readFileSync(file, 'utf-8');

  // Пример ошибки: программа обязана НЕ сработать, а сообщение компилятора
  // (или ошибка при запуске) — содержать текст из первой строки.
  if (source.startsWith(EXPECT_PREFIX)) {
    checked++;
    const expected = source.split('\n')[0].slice(EXPECT_PREFIX.length).trim();
    expectedErrors.push({ rel, expected });
    const result = runMojo(file, [], { cwd: dirname(file) });
    const output = `${result.stdout}\n${result.stderr}`;
    if (result.ok) {
      console.error(`✗ ${rel}: должен был упасть, а отработал без ошибки`);
      failed++;
    } else if (!output.includes(expected)) {
      console.error(`✗ ${rel}: сообщение об ошибке изменилось`);
      console.error('  ожидалось:', expected);
      console.error('  получено: ', result.stderr.trim().split('\n').slice(0, 6).join('\n'));
      failed++;
    } else {
      console.log(`✓ ${rel} (ошибка воспроизводится)`);
    }
    continue;
  }

  // Модуль расширения для Python: точки входа main у него нет, зато есть
  // PyInit_. Запустить нельзя, но собрать в разделяемую библиотеку можно —
  // это ловит почти всё, что может сломаться.
  if (/@export[\s\S]*?\bPyInit_/.test(source)) {
    checked++;
    const so = join(tmpdir(), `mojo-ru-ext-${process.pid}-${checked}.so`);
    const built = runMojo(file, ['build', '--emit', 'shared-lib', '-o', so]);
    if (!built.ok) {
      console.error(`✗ ${rel}: модуль расширения не собирается`);
      console.error(built.stderr.trim());
      failed++;
      continue;
    }
    if (existsSync(so)) unlinkSync(so);
    if (deprecation(built)) {
      console.error(`✗ ${rel}: устаревший API`);
      console.error(deprecation(built));
      failed++;
      continue;
    }
    console.log(`✓ ${rel} (расширение Python, сборка)`);
    continue;
  }

  // Файлы без точки входа — это модули многофайлового примера. Запустить их
  // отдельно нельзя (`module does not define a 'main' function`), но они
  // проверяются вместе с той программой, которая их импортирует.
  if (!/\bdef main\b/.test(source)) {
    console.log(`· ${rel}: модуль, проверяется через импорт`);
    continue;
  }

  checked++;

  // Замер: печатает время, которое у каждой машины своё. Сверять нечего,
  // а гонять долго — достаточно, чтобы он собирался.
  if (/^bench_.*\.mojo$/.test(basename(file))) {
    const exe = join(tmpdir(), `mojo-ru-bench-${process.pid}-${checked}`);
    const built = runMojo(file, ['build', '-o', exe]);
    if (existsSync(exe)) unlinkSync(exe);
    if (!built.ok) {
      console.error(`✗ ${rel}: замер не собирается`);
      console.error(built.stderr.trim());
      failed++;
      continue;
    }
    if (deprecation(built)) {
      console.error(`✗ ${rel}: устаревший API`);
      console.error(deprecation(built));
      failed++;
      continue;
    }
    // Если рядом лежит <имя>.args, прогоняем замер на маленьких данных:
    // вывод не сверяем, но падение во время работы поймаем.
    const benchArgs = file.replace(/\.mojo$/, '.args');
    if (existsSync(benchArgs)) {
      const ran = runMojo(file, ['run'], {
        programArgs: readFileSync(benchArgs, 'utf-8').trim().split(/\s+/).filter(Boolean),
        cwd: dirname(file),
      });
      if (!ran.ok) {
        console.error(`✗ ${rel}: замер падает при запуске`);
        console.error(ran.stderr.trim());
        failed++;
        continue;
      }
      console.log(`✓ ${rel} (замер: сборка и пробный запуск)`);
      continue;
    }
    console.log(`✓ ${rel} (замер, только сборка)`);
    continue;
  }

  // Файл с тестами: вывод содержит время выполнения и потому каждый раз
  // разный. Сверять его не с чем — достаточно, чтобы все тесты прошли.
  // Пакет, который тестируется, лежит по соседству в ../src.
  if (/^test_.*\.mojo$/.test(basename(file))) {
    const src = join(dirname(file), '..', 'src');
    // -D ASSERT=all: тесты гоняются и со всеми debug_assert, как советует глава.
    const tested = runMojo(
      file,
      existsSync(src) ? ['run', '-D', 'ASSERT=all', '-I', src] : ['run', '-D', 'ASSERT=all']
    );
    if (!tested.ok) {
      console.error(`✗ ${rel}: тесты не проходят`);
      console.error(tested.stderr.trim());
      failed++;
      continue;
    }
    if (deprecation(tested)) {
      console.error(`✗ ${rel}: устаревший API`);
      console.error(deprecation(tested));
      failed++;
      continue;
    }
    console.log(`✓ ${rel} (тесты)`);
    continue;
  }

  if (!existsSync(expectedFile)) {
    console.error(`✗ ${rel}: нет файла с ожидаемым выводом`);
    failed++;
    continue;
  }

  // Программе нужны аргументы командной строки? Они лежат рядом в <имя>.args,
  // а запускается она из своего каталога, чтобы находить свои входные файлы.
  const argsFile = file.replace(/\.mojo$/, '.args');
  const result = existsSync(argsFile)
    ? runMojo(file, ['run'], {
        programArgs: readFileSync(argsFile, 'utf-8').trim().split(/\s+/).filter(Boolean),
        cwd: dirname(file),
      })
    : runMojo(file);
  if (!result.ok) {
    console.error(`✗ ${rel}: не компилируется или падает`);
    console.error(result.stderr.trim());
    failed++;
    continue;
  }

  if (deprecation(result)) {
    console.error(`✗ ${rel}: устаревший API`);
    console.error(deprecation(result));
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

/**
 * Обращения, дающие на разных машинах разный ответ: версия интерпретатора,
 * ширина векторного регистра, число ядер, часы. Проверять такой вывод
 * сравнением нельзя.
 */
const MACHINE_SPECIFIC =
  /sys\.version|platform\.|simd_width_of|num_physical_cores|num_performance_cores|num_logical_cores|perf_counter|monotonic|time\.now|getenv|os\.environ/;

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

    if (deprecation(result)) {
      console.error(`✗ ${rel} (блок кода #${index + 1}): устаревший API`);
      console.error(deprecation(result));
      failed++;
      continue;
    }

    // Ищем <Result output={"..."} /> в ближайших строках после блока.
    const tail = block.after.slice(0, 400);
    const promised = tail.match(
      /^\s*(?:\{\/\*[^]*?\*\/\}\s*)?<Result output=\{"((?:[^"\\]|\\.)*)"\}\s*\/>/
    );

    const marked = tail.slice(0, promised ? promised[0].length : 0).includes(UNSTABLE);

    // Вывод, зависящий от машины, нельзя записывать в <Result>: у CI и у
    // автора он разный. Такое уже случалось дважды — с версией Python
    // и с шириной SIMD-вектора.
    if (promised && !marked && MACHINE_SPECIFIC.test(block.code)) {
      console.error(
        `✗ ${rel} (блок кода #${index + 1}): вывод зависит от машины, ` + `а сверяется с <Result>`
      );
      console.error(
        '  Уберите машинно-зависимую часть из блока либо пометьте ' +
          `результат строкой ${UNSTABLE} перед <Result>.`
      );
      failed++;
      continue;
    }

    if (promised && !marked) {
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
    } else if (deprecation(result)) {
      console.error(`✗ ${rel} (фрагмент #${index + 1}): устаревший API`);
      console.error(deprecation(result));
      failed++;
    }
  }
}

// --- 4. Ядра GPU: сборка под видеокарты, которых у CI нет ----------------
//
// Без видеокарты `has_accelerator()` ложно, и ветку с ядрами компилятор
// только проверяет на типы, но не собирает. Проверки, зависящие от
// видеокарты (можно ли передать аргумент в ядро, подходит ли он по типу),
// в шагах 1 и 2 не выполняются. Собираем такие программы под конкретные
// архитектуры — эти ошибки всплывут здесь.

/** Архитектуры для проверки: NVIDIA Ampere (RTX 30xx) и AMD RDNA3 (RX 7900). */
const GPU_TARGETS = ['sm_86', 'gfx1100'];

const USES_GPU = /\bfrom max\.gpu\b|\bimport max\.gpu\b/;

/** Собирает файл под каждую архитектуру; возвращает текст ошибки или null. */
function gpuBuildError(file) {
  for (const target of GPU_TARGETS) {
    const exe = join(tmpdir(), `mojo-ru-gpu-${process.pid}-${checked}-${target}`);
    const built = runMojo(file, ['build', `--target-accelerator=${target}`, '-o', exe]);
    if (existsSync(exe)) unlinkSync(exe);
    if (!built.ok) return `${target}:\n${built.stderr.trim()}`;
    if (deprecation(built)) return `${target}: устаревший API\n${deprecation(built)}`;
  }
  return null;
}

for (const file of collect(EXAMPLES, '.mojo')) {
  const source = readFileSync(file, 'utf-8');
  if (!USES_GPU.test(source) || !/\bdef main\b/.test(source)) continue;
  const rel = relative(EXAMPLES, file);
  checked++;
  const error = gpuBuildError(file);
  if (error) {
    console.error(`✗ ${rel}: не собирается под GPU`);
    console.error(error);
    failed++;
    continue;
  }
  console.log(`✓ ${rel} (сборка под GPU: ${GPU_TARGETS.join(', ')})`);
}

for (const file of collect(DOCS, '.mdx')) {
  const rel = relative(DOCS, file);
  if (SKIP_FILES.includes(rel)) continue;

  const blocks = [...readFileSync(file, 'utf-8').matchAll(/```mojo[^\n]*\n([\s\S]*?)```/g)]
    .map((match) => match[1])
    .filter((code) => /\bdef main\b/.test(code) && USES_GPU.test(code));

  for (const [index, code] of blocks.entries()) {
    const tmp = join(tmpdir(), `mojo-ru-gpu-${process.pid}-${checked}.mojo`);
    writeFileSync(tmp, code, 'utf-8');
    checked++;
    const error = gpuBuildError(tmp);
    unlinkSync(tmp);
    if (error) {
      console.error(`✗ ${rel} (блок с GPU #${index + 1}): не собирается под GPU`);
      console.error(error);
      failed++;
      continue;
    }
    console.log(`✓ ${rel} (блок с GPU #${index + 1}, сборка под GPU)`);
  }
}

// --- 5. Справочник ошибок сверяется с примерами ---------------------------
//
// Каждое сообщение на странице reference/compiler-errors записано строкой
// вида **`` текст ``** и должно подтверждаться примером из шага 1, а каждый
// пример — встречаться на странице. Иначе справочник и проверка разойдутся.

const ERRORS_PAGE = join(DOCS, 'reference/compiler-errors.mdx');
if (existsSync(ERRORS_PAGE)) {
  const onPage = [...readFileSync(ERRORS_PAGE, 'utf-8').matchAll(/^\*\*`` (.+?) ``\*\*$/gm)].map(
    (match) => match[1]
  );
  for (const message of onPage) {
    checked++;
    if (!expectedErrors.some(({ expected }) => message.includes(expected))) {
      console.error(`✗ reference/compiler-errors.mdx: нет примера для «${message}»`);
      failed++;
    }
  }
  for (const { rel, expected } of expectedErrors) {
    if (!onPage.some((message) => message.includes(expected))) {
      console.error(`✗ ${rel}: ошибки «${expected}» нет в справочнике`);
      failed++;
    }
  }
  console.log(`✓ reference/compiler-errors.mdx: ${onPage.length} сообщений сверено с примерами`);
}

console.log(`\nПроверено: ${checked}, ошибок: ${failed}`);
process.exit(failed > 0 ? 1 : 0);
