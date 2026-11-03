import { defineRouteMiddleware } from '@astrojs/starlight/route-data';
import { getCollection } from 'astro:content';

/**
 * hreflang только для страниц, у которых перевод есть на самом деле.
 *
 * Starlight объявляет `<link rel="alternate" hreflang="…">` для каждого
 * языка сайта на каждой странице. Но английских переводов пока почти нет:
 * по английскому адресу Starlight отдаёт русский текст, и такая страница
 * закрыта `noindex` (см. Head.astro). Ссылка hreflang на неё — противоречивый
 * сигнал: «вот английская версия» указывает на страницу, которая
 * не английская и которую просят не индексировать. Search Console считает
 * это ошибкой hreflang.
 *
 * Поэтому, если перевода нет, альтернативы языков убираются целиком:
 * при единственной версии страницы hreflang не нужен вовсе. Где перевод
 * есть (сейчас — главная), всё остаётся как делает Starlight.
 */

/** Адрес страницы без языкового префикса: 'basics/control-flow', '' для главной. */
const pathKey = (id: string) => id.replace(/^en(\/|$)/, '').replace(/(^|\/)index$/, '');

let translated: Promise<Set<string>> | undefined;

const translatedPages = () =>
  (translated ??= getCollection('docs').then(
    (entries) =>
      new Set(
        entries.filter((entry) => /^en(\/|$)/.test(entry.id)).map((entry) => pathKey(entry.id))
      )
  ));

export const onRequest = defineRouteMiddleware(async (context) => {
  const route = context.locals.starlightRoute;
  const hasTranslation = (await translatedPages()).has(pathKey(route.id));
  if (hasTranslation) return;

  route.head = route.head.filter(
    (item) =>
      !(item.tag === 'link' && item.attrs?.rel === 'alternate' && 'hreflang' in (item.attrs ?? {}))
  );
});
