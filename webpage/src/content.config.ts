import { z, defineCollection } from "astro:content"
import { glob } from 'astro/loaders';

export const blogCollection = defineCollection({
    loader: glob({ pattern: '**/[^_]*.{md,mdx}', base: "./src/content/blog" }),
    schema: z.object({
        title: z.string(),
        description: z.string(),
        image: z
            .object({
                src: z.string(),
                alt: z.string(),
            })
            .optional(),
        tags: z.array(z.string()),
        publishDate: z.date(),
    }),
})

export const collections = {
    blog: blogCollection,
}
