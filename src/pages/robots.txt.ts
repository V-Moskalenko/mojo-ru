import type { APIRoute } from 'astro';

/**
 * robots.txt со ссылкой на карту сайта.
 *
 * На GitHub Pages проектный сайт лежит в подпапке, а поисковики читают
 * robots.txt только из корня домена — так что там от этого файла толку нет.
 * Он начнёт работать сразу после переезда на собственный домен, и лучше,
 * чтобы к тому моменту он уже был и содержал правильный адрес sitemap.
 */
export const GET: APIRoute = ({ site }) => {
  const base = import.meta.env.BASE_URL.replace(/\/+$/, '');
  const sitemap = site ? new URL(`${base}/sitemap-index.xml`, site).href : '/sitemap-index.xml';

  return new Response(
    `User-agent: *
Allow: /

Sitemap: ${sitemap}
`,
    { headers: { 'Content-Type': 'text/plain; charset=utf-8' } }
  );
};
