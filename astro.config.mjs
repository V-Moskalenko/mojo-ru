// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';
import starlightLinksValidator from 'starlight-links-validator';
import sitemap from '@astrojs/sitemap';
import { readFileSync, readdirSync, statSync, existsSync } from 'node:fs';
import { writeFile } from 'node:fs/promises';
import { execFileSync } from 'node:child_process';
import { rehypeBaseLinks } from './src/plugins/rehype-base-links.mjs';

/**
 * Адрес сайта. Собственный домен, сайт лежит в корне — поэтому BASE = '/'.
 *
 * Механика базового пути осталась в проекте на случай переезда: если сайт
 * снова окажется в подпапке, достаточно поменять эти две строки, и ссылки
 * в главах, ассеты и sitemap подстроятся сами. Значения можно переопределить
 * переменными окружения, не трогая файл.
 */
const SITE = process.env.SITE_URL ?? 'https://mojo-lang.ru';
const BASE = process.env.SITE_BASE ?? '/';

/** Репозиторий проекта — используется для ссылок «редактировать страницу». */
const REPO = 'https://github.com/V-Moskalenko/mojo-ru';

/**
 * Адреса страниц, которые реально переведены на английский.
 *
 * Всё, чего в `src/content/docs/en/` нет, Starlight отдаёт по-английскому
 * адресу с русским текстом. Такие страницы не должны попадать в карту сайта:
 * для поисковика это дубли. Список собирается из файлов, поэтому обновляется
 * сам по мере появления переводов.
 */
function translatedEnglishRoutes() {
  const dir = new URL('./src/content/docs/en/', import.meta.url).pathname;
  if (!existsSync(dir)) return new Set();

  const routes = new Set();
  const walk = (current, prefix) => {
    for (const name of readdirSync(current)) {
      const full = `${current}/${name}`;
      if (statSync(full).isDirectory()) {
        walk(full, `${prefix}${name}/`);
        continue;
      }
      if (!/\.mdx?$/.test(name)) continue;
      const slug = name.replace(/\.mdx?$/, '');
      routes.add(slug === 'index' ? `/en/${prefix}` : `/en/${prefix}${slug}/`);
    }
  };
  walk(dir.replace(/\/$/, ''), '');
  return routes;
}

const EN_ROUTES = translatedEnglishRoutes();

/**
 * Адреса глав-заглушек (`wip: true` во frontmatter).
 *
 * Заглушка полезна читателю: видно, куда движется курс, и можно попросить
 * написать главу раньше. Но для поисковика три десятка почти одинаковых
 * страниц «глава пишется» — это тонкий контент, который тянет вниз оценку
 * всего сайта. Поэтому такие страницы не попадают в карту сайта и получают
 * noindex; ссылки на них и навигация при этом работают как обычно.
 */
function draftRoutes() {
  const dir = new URL('./src/content/docs/', import.meta.url).pathname.replace(/\/$/, '');
  const routes = new Set();

  const walk = (current, prefix) => {
    for (const name of readdirSync(current)) {
      const full = `${current}/${name}`;
      if (statSync(full).isDirectory()) {
        walk(full, `${prefix}${name}/`);
        continue;
      }
      if (!/\.mdx?$/.test(name)) continue;
      const frontmatter = readFileSync(full, 'utf-8').split(/^---$/m)[1] ?? '';
      if (!/^wip:\s*true\s*$/m.test(frontmatter)) continue;
      const slug = name.replace(/\.mdx?$/, '');
      routes.add(slug === 'index' ? `/${prefix}` : `/${prefix}${slug}/`);
    }
  };

  walk(dir, '');
  return routes;
}

const DRAFT_ROUTES = draftRoutes();

/**
 * Дата последнего изменения страницы — берётся из истории git.
 *
 * Поисковику она говорит, что перечитывать в первую очередь. Врать здесь
 * нельзя: если поставить «сегодня» всем страницам разом, Google просто
 * перестанет верить полю. Поэтому дата настоящая — коммит, в котором главу
 * правили последний раз.
 *
 * На мелкой копии репозитория (`fetch-depth: 1`) истории нет, дата не
 * определится — тогда поле просто не выводится, сборка не падает.
 */
function lastModified(route) {
  const clean = route.replace(/^\/en/, '').replace(/^\/|\/$/g, '');
  const base = `./src/content/docs/${clean || 'index'}`;
  const file = ['.mdx', '.md'].map((ext) => `${base}${ext}`).find((path) => existsSync(path));
  if (!file) return undefined;

  try {
    const date = execFileSync('git', ['log', '-1', '--format=%cI', '--', file], {
      encoding: 'utf-8',
      stdio: ['ignore', 'pipe', 'ignore'],
    }).trim();
    return date || undefined;
  } catch {
    return undefined;
  }
}

/**
 * TextMate-грамматика Mojo взята из официального расширения VS Code
 * https://github.com/modular/vscode-mojo (Apache-2.0).
 * Shiki не содержит Mojo среди встроенных языков, поэтому регистрируем вручную.
 * Лицензия сохранена в src/grammars/LICENSE-vscode-mojo.txt
 */
const mojoGrammar = JSON.parse(
  readFileSync(new URL('./src/grammars/mojo.tmLanguage.json', import.meta.url), 'utf-8')
);

/** Версия Mojo, на которой проверены все примеры сайта. */
export const MOJO_VERSION = '1.0.0';

export default defineConfig({
  site: SITE,
  base: BASE,
  trailingSlash: 'always',
  markdown: {
    // внутренние ссылки в тексте глав получают базовый путь автоматически
    rehypePlugins: [rehypeBaseLinks(BASE)],
  },
  integrations: [
    /**
     * robots.txt собирается на сборке, а не лежит в public/, чтобы адрес
     * карты сайта не разъехался с доменом: и то и другое берётся из SITE.
     */
    {
      name: 'robots-txt',
      hooks: {
        'astro:build:done': async ({ dir, logger }) => {
          const base = BASE === '/' ? '' : BASE;
          const body = [
            '# Курс «Mojo по-русски»',
            '# Индексировать можно всё: сайт публичный и бесплатный.',
            '#',
            '# Английские адреса без перевода закрыты мета-тегом noindex',
            '# в самой странице. Через robots.txt их закрывать нельзя:',
            '# запрет обхода помешал бы роботу увидеть noindex.',
            '',
            'User-agent: *',
            'Allow: /',
            '',
            `Sitemap: ${new URL(`${base}/sitemap-index.xml`, SITE).href}`,
            '',
          ].join('\n');
          await writeFile(new URL('robots.txt', dir), body, 'utf-8');
          logger.info('robots.txt создан');
        },
      },
    },
    /**
     * Свой @astrojs/sitemap вместо встроенного: нужен фильтр, который
     * выкидывает непереведённые английские адреса.
     */
    sitemap({
      i18n: {
        defaultLocale: 'root',
        locales: { root: 'ru', en: 'en' },
      },
      filter: (page) => {
        const path = new URL(page).pathname.replace(BASE === '/' ? '' : BASE, '') || '/';
        // главы-заглушки в карту сайта не попадают
        if (DRAFT_ROUTES.has(path.replace(/^\/en/, ''))) return false;
        if (!path.startsWith('/en/') && path !== '/en') return true;
        return EN_ROUTES.has(path);
      },
      serialize: (item) => {
        const path = new URL(item.url).pathname.replace(BASE === '/' ? '' : BASE, '') || '/';
        const lastmod = lastModified(path);
        return lastmod ? { ...item, lastmod } : item;
      },
    }),
    starlight({
      title: 'Mojo по-русски',
      tagline: 'Полный курс по языку Mojo 1.0 на русском языке',
      description:
        'Бесплатный учебник по языку программирования Mojo 1.0 на русском языке: установка на Windows через WSL, настройка VS Code, основы синтаксиса, владение значениями, SIMD и практические проекты.',
      logo: {
        src: './src/assets/logo.svg',
        alt: 'Mojo по-русски',
        replacesTitle: false,
      },
      favicon: '/favicon.svg',
      defaultLocale: 'root',
      locales: {
        root: { label: 'Русский', lang: 'ru' },
        en: { label: 'English', lang: 'en' },
      },
      social: [
        {
          icon: 'github',
          label: 'GitHub',
          href: REPO,
        },
      ],
      editLink: {
        baseUrl: `${REPO}/edit/main/`,
      },
      head: [
        // Картинка-превью для Telegram, Хабра и прочих мест, куда кинут ссылку.
        // Пересобрать после смены домена: node scripts/make-og.mjs
        {
          tag: 'meta',
          attrs: { property: 'og:image', content: `${SITE}${BASE === '/' ? '' : BASE}/og.png` },
        },
        { tag: 'meta', attrs: { property: 'og:type', content: 'website' } },
        { tag: 'meta', attrs: { name: 'twitter:card', content: 'summary_large_image' } },
        { tag: 'meta', attrs: { name: 'theme-color', content: '#14110f' } },
      ],
      lastUpdated: true,
      pagination: true,
      customCss: [
        '@fontsource-variable/inter',
        '@fontsource-variable/jetbrains-mono',
        './src/styles/theme.css',
      ],
      components: {
        // Бейдж «проверено на Mojo X» в подвале страницы
        Footer: './src/components/Footer.astro',
        // Тёмная тема по умолчанию
        ThemeProvider: './src/components/ThemeProvider.astro',
        // Базовый путь в кнопках на главной
        Hero: './src/components/Hero.astro',
        // noindex для английских страниц, которые ещё не переведены
        Head: './src/components/Head.astro',
      },
      plugins: [
        // Ломаная внутренняя ссылка роняет сборку — лучше поймать её в CI,
        // чем получить 404 у читателя.
        starlightLinksValidator({
          errorOnRelativeLinks: false,
          /**
           * Исключение ровно одно: ссылки кнопок на главной. Они живут во
           * frontmatter, базовый путь к ним подставляет src/components/Hero.astro
           * уже при рендере, поэтому валидатор видит их «без префикса».
           * Ссылки внутри текста глав проверяются как обычно.
           */
          exclude: ({ link }) =>
            BASE !== '/' && link.startsWith('/') && !link.startsWith(`${BASE}/`) && link !== BASE,
        }),
      ],
      expressiveCode: {
        themes: ['github-dark-default', 'github-light'],
        shiki: {
          langs: [mojoGrammar],
        },
        styleOverrides: {
          borderRadius: '0.6rem',
          codeFontFamily: "'JetBrains Mono Variable', ui-monospace, monospace",
          codeFontSize: '0.875rem',
          codeLineHeight: '1.7',
          // Тёплый фон кода вместо синеватого github-dark — чтобы блоки
          // кода не выпадали из общей гаммы страницы.
          codeBackground: '#1b1714',
          borderColor: '#2a2521',
          frames: {
            shadowColor: 'transparent',
            editorTabBarBackground: '#16130f',
            editorActiveTabBackground: '#1b1714',
            editorActiveTabIndicatorTopColor: '#ff7a2f',
            terminalBackground: '#1b1714',
            terminalTitlebarBackground: '#16130f',
          },
        },
      },
      sidebar: [
        {
          label: 'Начало',
          translations: { en: 'Getting started' },
          items: [{ autogenerate: { directory: 'start' } }],
        },
        {
          label: 'Установка и окружение',
          translations: { en: 'Installation' },
          items: [{ autogenerate: { directory: 'install' } }],
        },
        {
          label: 'Из Python в Mojo',
          translations: { en: 'From Python to Mojo' },
          items: [{ autogenerate: { directory: 'python-to-mojo' } }],
        },
        {
          label: 'Базовый Mojo',
          translations: { en: 'Mojo basics' },
          items: [{ autogenerate: { directory: 'basics' } }],
        },
        {
          label: 'Владение значениями',
          translations: { en: 'Value ownership' },
          items: [{ autogenerate: { directory: 'ownership' } }],
        },
        {
          label: 'Метапрограммирование',
          translations: { en: 'Metaprogramming' },
          items: [{ autogenerate: { directory: 'meta' } }],
        },
        {
          label: 'Производительность',
          translations: { en: 'Performance' },
          items: [{ autogenerate: { directory: 'performance' } }],
        },
        {
          label: 'Интеграция',
          translations: { en: 'Interop' },
          items: [{ autogenerate: { directory: 'interop' } }],
        },
        {
          label: 'Практика',
          translations: { en: 'Projects' },
          items: [{ autogenerate: { directory: 'projects' } }],
        },
        {
          label: 'Справочник',
          translations: { en: 'Reference' },
          items: [{ autogenerate: { directory: 'reference' } }],
        },
      ],
    }),
  ],
});
