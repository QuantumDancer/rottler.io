// @ts-check
import { defineConfig } from 'astro/config';
import expressiveCode from 'astro-expressive-code';
import { pluginLineNumbers } from '@expressive-code/plugin-line-numbers';
import mdx from '@astrojs/mdx';
import sitemap from '@astrojs/sitemap';

// https://astro.build/config
export default defineConfig({
  site: 'https://rottler.io',
  integrations: [
    expressiveCode({
      themes: ['github-light', 'github-dark'],
      plugins: [pluginLineNumbers()],
      defaultProps: {
        // Line numbers off by default; enable per-block via showLineNumbers.
        showLineNumbers: false,
      },
    }),
    // @astrojs/mdx MUST be registered after astro-expressive-code so that code
    // blocks in .mdx files pick up EC's highlighting rather than Astro's
    // default Shiki pass. Reordering silently disables EC inside MDX.
    mdx(),
    sitemap(),
  ],
});
