import { defineCollection, z } from 'astro:content';
import { docsLoader } from '@astrojs/starlight/loaders';
import { docsSchema } from '@astrojs/starlight/schema';

export const collections = {
  docs: defineCollection({
    loader: docsLoader(),
    schema: docsSchema({
      extend: z.object({
        /** Версия Mojo, на которой проверены примеры этой страницы. */
        mojoVersion: z.string().optional(),
        /** Заглушка: структура зафиксирована, текст ещё не написан. */
        wip: z.boolean().optional().default(false),
        /** Примерное время чтения, мин. */
        readingTime: z.number().optional(),
      }),
    }),
  }),
};
