# Mojo по-русски

[![Сборка и публикация](https://github.com/V-Moskalenko/mojo-ru/actions/workflows/deploy.yml/badge.svg)](https://github.com/V-Moskalenko/mojo-ru/actions/workflows/deploy.yml)
[![Проверка примеров](https://github.com/V-Moskalenko/mojo-ru/actions/workflows/check-examples.yml/badge.svg)](https://github.com/V-Moskalenko/mojo-ru/actions/workflows/check-examples.yml)
[![Mojo 1.0](https://img.shields.io/badge/Mojo-1.0-ff7a2f)](https://mojolang.org/)
[![Лицензия текста: CC BY 4.0](https://img.shields.io/badge/текст-CC%20BY%204.0-blue)](LICENSE-CONTENT)

Бесплатный обучающий курс по языку программирования **Mojo 1.0** на русском языке.
От «у меня Windows и я ничего не понимаю» до собственной библиотеки с SIMD.

**Сайт:** https://v-moskalenko.github.io/mojo-ru/

## Что уже есть

- Каркас на Astro + Starlight: русский как основной язык, английская версия заложена в архитектуру
- Дизайн-система: тёплая тёмная тема по умолчанию, типографика под длинные технические тексты на кириллице
- Подсветка синтаксиса Mojo — грамматика из официального расширения VS Code, потому что в Shiki языка Mojo нет
- Свои компоненты: сравнение «Python → Mojo», блок вывода программы, карточка ошибки компилятора, «Проверь себя», бейдж версии Mojo
- Структура курса целиком: 9 разделов, 54 страницы
- Написаны: установка на Windows через WSL, первая программа, устаревшие конструкции, словарь терминов, «зачем нужен Mojo»
- CI: сборка с проверкой всех внутренних ссылок и еженедельный прогон примеров на настоящем компиляторе Mojo

## Запуск

Нужен Node.js 22+.

```bash
npm install
npm run dev      # локальный сервер разработки
npm run build    # сборка в dist/ (заодно проверяет внутренние ссылки)
npm run preview  # посмотреть собранный сайт
```

Дополнительно:

```bash
npm run stubs           # создать недостающие страницы-заглушки по плану курса
npm run examples:check  # прогнать примеры на настоящем Mojo (нужен Linux/macOS/WSL с Mojo)
npm run format          # причесать исходники (контент глав не трогает)
```

## Структура

```
src/
  content/docs/       контент курса (.mdx): корень — русская версия, en/ — английская
  components/         PyMojo, Result, Quiz, CompilerError, Footer, Hero, ThemeProvider
  styles/theme.css    дизайн-система
  grammars/           TextMate-грамматика Mojo для подсветки
  plugins/            rehype-плагин базового пути для ссылок в главах
  utils/link.ts       withBase() для ссылок, которые передаются в компоненты
  consts.ts           версия Mojo и общие ссылки
examples/             примеры кода: .mojo рядом с .out (ожидаемый вывод)
scripts/              генератор заглушек, проверка примеров, скриншоты
notes/                рабочие заметки авторов, в сайт не попадают
.github/workflows/    сборка и публикация, еженедельная проверка примеров
```

## Развёртывание

Сайт публикуется на GitHub Pages автоматически при пуше в `main`.

Что нужно включить один раз в настройках репозитория:
**Settings → Pages → Build and deployment → Source: GitHub Actions**.

### Переезд на собственный домен

Меняются ровно две строки в `astro.config.mjs`:

```js
const SITE = 'https://ваш-домен.ru';
const BASE = '/';
```

Ссылки внутри глав, ассеты, sitemap и кнопки на главной подстроятся сами —
за это отвечают `src/plugins/rehype-base-links.mjs` и `withBase()`.
Дополнительно нужно положить файл `public/CNAME` с доменом и указать домен
в Settings → Pages.

## Принципы проекта

1. **Ни одного примера, который не компилируется.** Код живёт в `examples/`
   отдельными файлами и прогоняется в CI, а не только внутри markdown.
2. **Опора на официальный мануал.** Теория сверяется с
   [mojolang.org](https://mojolang.org/docs/manual/). Конструкции, устаревшие
   до 1.0 (`fn`, `let`, `inout`, `@value`), явно помечаются как устаревшие.
3. **Единая терминология.** Решение по каждому термину принимается один раз
   и действует на всех страницах — см. [словарь](src/content/docs/reference/glossary.mdx).
4. **Windows — полноценная платформа.** Установка через WSL разобрана
   подробно, а не сноской мелким шрифтом.

## Как помочь

Правки, новые главы и замечания приветствуются — см. [CONTRIBUTING.md](CONTRIBUTING.md).
Самый быстрый способ: ссылка «Редактировать страницу» внизу любой страницы сайта.

## Лицензии

- Тексты курса — [CC BY 4.0](LICENSE-CONTENT)
- Код сайта и примеров — [Apache 2.0](LICENSE-CODE)
- TextMate-грамматика Mojo — Apache 2.0, из [modular/vscode-mojo](https://github.com/modular/vscode-mojo),
  копия лицензии в `src/grammars/LICENSE-vscode-mojo.txt`

## Источники и благодарности

- [Официальный мануал Mojo](https://mojolang.org/docs/manual/) — основной источник фактуры
- [Mojo Miji](https://mojo-lang.com/miji/) Юйхао Чжу — референс по структуре и подаче.
  Книга под лицензией CC BY-NC-ND 4.0, поэтому её текст здесь **не переводится
  и не заимствуется**: используются только идеи организации материала.
