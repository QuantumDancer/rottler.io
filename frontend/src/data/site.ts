// Central site metadata: identity, contact, and the social links surfaced in
// the layout header/footer. Pages and the RSS feed read from here so there is
// one source of truth for name/description/URL.

import type { SocialIconName } from '../components/social-icons';

export interface SocialLink {
  label: string;
  href: string;
  /** Glyph shown left of the label; omitted for plain text links such as nav. */
  icon?: SocialIconName;
}

export const site = {
  name: 'Benjamin Rottler',
  description: 'The personal site of Benjamin Rottler',
  url: 'https://rottler.io',
  email: 'benjamin@rottler.io',
};

export const socialLinks: SocialLink[] = [
  {
    label: 'LinkedIn',
    href: 'https://www.linkedin.com/in/benjamin-rottler',
    icon: 'linkedin',
  },
  { label: 'GitHub', href: 'https://github.com/QuantumDancer', icon: 'github' },
  { label: 'Email', href: 'mailto:benjamin@rottler.io', icon: 'email' },
  // The legacy site also linked an Instagram profile
  // (https://www.instagram.com/quantumdancer93). It was intentionally dropped
  // for the rebuild: an off-topic, dated tone for the new professional site.
];

// Primary navigation shown in the header. Order and the "Writing" label
// follow the Claude Design v1 pages; the blog lives under /writing/.
export const navLinks: SocialLink[] = [
  { label: 'Home', href: '/' },
  { label: 'Writing', href: '/writing/' },
  { label: 'Projects', href: '/projects/' },
  { label: 'CV', href: '/cv/' },
];
