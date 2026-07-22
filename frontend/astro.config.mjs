// @ts-check
import { defineConfig } from 'astro/config';
import expressiveCode from 'astro-expressive-code';
import { pluginLineNumbers } from '@expressive-code/plugin-line-numbers';
import mdx from '@astrojs/mdx';
import sitemap from '@astrojs/sitemap';

/*
 * Expressive Code is themed to match the Claude Design v1 code-block spec
 * (Design System §06, Blog Post mockup). Two decisions drive the setup:
 *
 * 1. Chrome (frame background, header, borders, copy button, line highlights)
 *    is expressed as CSS-variable references into base.css tokens via
 *    styleOverrides. Because both themes resolve these to the same var(--…),
 *    the frame automatically follows the site's [data-theme] toggle and accent
 *    hue without EC needing per-theme chrome colors.
 *
 * 2. Syntax token colors cannot be CSS variables (Shiki bakes them into the
 *    theme), so the two themes below mirror the --sx-* token values from
 *    base.css as literal hex — dark and light. themeCssSelector keys them to
 *    the site's [data-theme] attribute (not prefers-color-scheme), so dark/light
 *    syntax follows the same manual toggle as everything else.
 */

// The five-bucket syntax palette from base.css --sx-*. A coarse TextMate theme
// with these buckets reproduces the mockup's deliberately limited code palette.
const darkSyntax = {
  fg: '#cfd2d6', // --text
  keyword: '#8db2d8', // --sx-k
  string: '#9cc48f', // --sx-s
  number: '#c7a1dd', // --sx-n
  function: '#dcb277', // --sx-f
  comment: '#63676e', // --sx-c
};
const lightSyntax = {
  fg: '#3c3f44',
  keyword: '#3d6a99',
  string: '#4e7d41',
  number: '#84549e',
  function: '#9a6a25',
  comment: '#a0a3a9',
};

/**
 * Builds a minimal VS Code / Shiki theme from a five-color palette. Scope
 * groupings follow common TextMate conventions; a small palette across many
 * languages is necessarily approximate, which is on-brand for the design.
 */
function buildTheme(name, type, p) {
  return {
    name,
    type,
    colors: {
      'editor.background': type === 'dark' ? '#16181b' : '#f4f3f0', // --code
      'editor.foreground': p.fg,
    },
    settings: [
      { settings: { foreground: p.fg } },
      {
        scope: ['comment', 'punctuation.definition.comment'],
        settings: { foreground: p.comment },
      },
      {
        scope: [
          'keyword',
          'storage',
          'storage.type',
          'storage.modifier',
          'keyword.control',
          'keyword.operator.expression',
          'variable.language',
          // Markup/data key names read as keywords in the design (YAML/JSON keys).
          'entity.name.tag',
          'support.type.property-name',
        ],
        settings: { foreground: p.keyword },
      },
      {
        scope: [
          'string',
          'string.quoted',
          'string.template',
          'punctuation.definition.string',
          'markup.inserted',
        ],
        settings: { foreground: p.string },
      },
      {
        scope: [
          'constant.numeric',
          'constant.language',
          'constant.character',
          'support.constant',
          'markup.deleted',
        ],
        settings: { foreground: p.number },
      },
      {
        scope: [
          'entity.name.function',
          'support.function',
          'meta.function-call entity.name.function',
          'entity.name.type',
          'support.type',
          'support.class',
        ],
        settings: { foreground: p.function },
      },
    ],
  };
}

/**
 * Appends an uppercase language chip to editor-frame headers (matching the
 * mockup's "HCL"/"YAML" pill next to the file path). Terminal frames use the
 * green-dot titlebar instead, so they are skipped. EC exposes the language on
 * codeBlock but not in the header markup, so the chip must be injected here
 * rather than via CSS attr().
 */
function pluginLanguageChip() {
  return {
    name: 'language-chip',
    hooks: {
      postprocessRenderedBlock: ({ codeBlock, renderData }) => {
        const figure = renderData.blockAst;
        const classNames = figure.properties?.className ?? [];
        if (
          !classNames.includes('has-title') ||
          classNames.includes('is-terminal')
        ) {
          return;
        }
        const header = figure.children.find(
          (node) => node.type === 'element' && node.tagName === 'figcaption',
        );
        if (!header) return;
        header.children.push({
          type: 'element',
          tagName: 'span',
          properties: { className: ['ec-language-chip'] },
          children: [{ type: 'text', value: codeBlock.language.toUpperCase() }],
        });
      },
    },
  };
}

// https://astro.build/config
export default defineConfig({
  // `site` is the root every absolute URL derives from — sitemap entries, RSS
  // links, and canonicals — so building for dev.rottler.io with the prod value
  // would publish a sitemap advertising rottler.io URLs from the dev host.
  //
  // The Makefile passes SITE_URL from the environment's `site_url` Terraform
  // output, which keeps the two in lockstep without a second source of truth.
  // The fallback is prod on purpose: a plain `npm run build` with no setup at
  // all should produce the production site, so forgetting the variable is never
  // the dangerous direction.
  site: process.env.SITE_URL ?? 'https://rottler.io',
  integrations: [
    expressiveCode({
      themes: [
        buildTheme('rottler-dark', 'dark', darkSyntax),
        buildTheme('rottler-light', 'light', lightSyntax),
      ],
      // Key theme CSS to the site's manual [data-theme] toggle, not the OS
      // preference. theme.type is 'dark' | 'light', matching the attribute.
      themeCssSelector: (theme) => `[data-theme='${theme.type}']`,
      useDarkModeMediaQuery: false,
      // Preserve the exact --sx-* palette; EC's contrast pass would otherwise
      // nudge these deliberately soft colors.
      minSyntaxHighlightingColorContrast: 0,
      plugins: [pluginLineNumbers(), pluginLanguageChip()],
      defaultProps: {
        // Line numbers off by default; enable per-block via showLineNumbers.
        showLineNumbers: false,
      },
      styleOverrides: {
        borderColor: 'var(--border2)',
        borderWidth: '1px',
        borderRadius: '11px',
        codeBackground: 'var(--code)',
        codeFontFamily: "'JetBrains Mono Variable', monospace",
        codeFontSize: '13.5px',
        codeLineHeight: '1.75',
        codePaddingBlock: '14px',
        codePaddingInline: '18px',
        uiFontFamily: "'JetBrains Mono Variable', monospace",
        uiFontSize: '12px',
        uiPaddingBlock: '8px',
        uiPaddingInline: '16px',
        frames: {
          frameBoxShadowCssValue: 'none',
          editorBackground: 'var(--code)',
          editorTabBarBackground: 'var(--codehead)',
          editorTabBarBorderBottomColor: 'var(--border2)',
          editorActiveTabBackground: 'var(--codehead)',
          editorActiveTabForeground: 'var(--muted)',
          editorActiveTabBorderColor: 'transparent',
          editorActiveTabIndicatorTopColor: 'transparent',
          editorActiveTabIndicatorBottomColor: 'transparent',
          editorTabsMarginInlineStart: '0',
          terminalBackground: 'var(--code)',
          terminalTitlebarBackground: 'var(--codehead)',
          terminalTitlebarBorderBottomColor: 'var(--border2)',
          terminalTitlebarForeground: 'var(--muted)',
          inlineButtonBorder: 'var(--border)',
          inlineButtonBorderOpacity: '1',
          inlineButtonForeground: 'var(--muted)',
          inlineButtonBackground: 'var(--surface)',
          inlineButtonBackgroundHoverOrFocusOpacity: '0.5',
          tooltipSuccessBackground: 'var(--ok)',
          tooltipSuccessForeground: 'var(--strong)',
        },
        textMarkers: {
          // Highlighted lines: --hl wash with a 3px inset accent bar (mockup §06).
          markBackground: 'var(--hl)',
          markBorderColor: 'var(--accent)',
          lineMarkerAccentWidth: '3px',
          lineMarkerAccentMargin: '0',
          // ins/del reuse the semantic success/warning tokens.
          insBackground: 'var(--ok-bg)',
          insBorderColor: 'var(--ok)',
          delBackground: 'var(--warn-bg)',
          delBorderColor: 'var(--warn)',
        },
      },
    }),
    // @astrojs/mdx MUST be registered after astro-expressive-code so that code
    // blocks in .mdx files pick up EC's highlighting rather than Astro's
    // default Shiki pass. Reordering silently disables EC inside MDX.
    mdx(),
    sitemap(),
  ],
});
