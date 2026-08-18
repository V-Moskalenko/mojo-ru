/**
 * Приводит внутреннюю ссылку к базовому пути сайта.
 *
 * Ссылки в тексте глав правит автоматически rehype-плагин, но пути, которые
 * передаются в компоненты пропсом (`<LinkCard href="/install/…">`), — это
 * обычные строки, и их плагин не видит. Для них используется эта функция:
 *
 *   import { withBase } from '../../utils/link';
 *   <LinkCard href={withBase('/install/windows-wsl/')} … />
 *
 * Когда сайт переедет на собственный домен и base станет `/`,
 * функция превратится в тождественную — менять вызовы не нужно.
 */
export function withBase(path: string): string {
  const base = import.meta.env.BASE_URL.replace(/\/+$/, '');

  if (!base) return path;
  if (!path.startsWith('/') || path.startsWith('//')) return path;
  if (path === base || path.startsWith(base + '/')) return path;

  return base + path;
}
