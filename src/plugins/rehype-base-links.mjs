import { visit } from 'unist-util-visit';

/**
 * Добавляет префикс базового пути ко всем внутренним ссылкам в markdown/MDX.
 *
 * Зачем: на GitHub Pages проектный сайт живёт не в корне домена, а по адресу
 * `/mojo-ru/`. Astro сам подставляет базовый путь в свои ссылки (меню,
 * навигация, ассеты), но ссылки, написанные руками в тексте главы
 * (`[установка](/install/windows-wsl/)`), он не трогает — они бы вели в никуда.
 *
 * Плагин решает это один раз и навсегда: в тексте глав пишем обычные пути от
 * корня сайта, а префикс подставляется на сборке. Когда появится свой домен и
 * base станет `/`, плагин просто перестанет что-либо менять — переписывать
 * ссылки в главах не придётся.
 */
export function rehypeBaseLinks(base = '/') {
  const prefix = base.replace(/\/+$/, '');

  return () => (tree) => {
    if (!prefix) return;

    visit(tree, 'element', (node) => {
      if (node.tagName !== 'a') return;

      const href = node.properties?.href;
      if (typeof href !== 'string') return;

      // внешние ссылки, якоря, протоколы и уже префиксованные пути не трогаем
      if (!href.startsWith('/')) return;
      if (href.startsWith('//')) return;
      if (href === prefix || href.startsWith(prefix + '/')) return;

      node.properties.href = prefix + href;
    });
  };
}
