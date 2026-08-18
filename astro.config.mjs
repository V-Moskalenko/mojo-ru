// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';
import starlightLinksValidator from 'starlight-links-validator';
import { readFileSync } from 'node:fs';
import { rehypeBaseLinks } from './src/plugins/rehype-base-links.mjs';

/**
 * Адрес сайта. Сейчас это проектная страница GitHub Pages, поэтому сайт живёт
 * не в корне домена, а в подпапке `/mojo-ru/`.
 *
 * Когда появится свой домен, менять нужно ровно две строки ниже:
 *   SITE = 'https://ваш-домен.ru'
 *   BASE = '/'
 * Всё остальное — ссылки в главах, ассеты, sitemap — подстроится само.
 * Значения можно переопределить переменными окружения, не трогая файл.
 */
const SITE = process.env.SITE_URL ?? 'https://v-moskalenko.github.io';
const BASE = process.env.SITE_BASE ?? '/mojo-ru';

/** Репозиторий проекта — используется для ссылок «редактировать страницу». */
const REPO = 'https://github.com/V-Moskalenko/mojo-ru';

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
