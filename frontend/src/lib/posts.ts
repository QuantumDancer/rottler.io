import { getCollection, type CollectionEntry } from 'astro:content';

export type BlogPost = CollectionEntry<'blog'>;

// Returns blog posts newest-first, with drafts filtered out for production
// builds. In dev (`import.meta.env.PROD === false`) drafts stay visible so
// work-in-progress can be previewed; the production build drops them, which
// also keeps their pages out of getStaticPaths and therefore out of `dist/`.
export async function getPublishedPosts(): Promise<BlogPost[]> {
  const posts = await getCollection('blog', ({ data }) => {
    return import.meta.env.PROD ? data.draft === false : true;
  });

  return posts.sort(
    (a, b) => b.data.publishDate.getTime() - a.data.publishDate.getTime(),
  );
}
