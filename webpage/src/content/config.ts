import { z, defineCollection } from "astro:content"

export const blogCollection = defineCollection({
    type: "content",
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
