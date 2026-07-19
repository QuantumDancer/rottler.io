// Project cards shown on the Projects page.
//
// Facts come from the real project inventory; the card *structure* — status
// chip, tag chips, optional link — is adopted from the Claude Design v1
// Projects mockup. Where the mockup supplied specifics that aren't confirmed
// yet (stack tags, an OSS repo that may not exist), they carry a
// `TODO(benjamin): verify` so they get reviewed before launch.

export type StatusTone = 'accent' | 'neutral';

export interface Project {
  title: string;
  description: string;
  /** Short status label rendered as a chip, e.g. "running", "demo", "oss". */
  status: string;
  /** accent = active/highlighted (tinted chip); neutral = passive label (outlined chip). */
  statusTone: StatusTone;
  /** Mono tag chips; keep them short (stack or domain). */
  tags: string[];
  /** Card link target. Omitted until there is a real destination to point at. */
  href?: string;
}

export const projects: Project[] = [
  {
    title: 'Homelab',
    description:
      'A self-hosted lab for running and experimenting with services at home — the test bed for most of what ends up in the writing here.',
    status: 'running',
    statusTone: 'accent',
    // TODO(benjamin): verify the actual homelab stack — these tags are carried over from the design mockup.
    tags: ['talos', 'argocd', 'k8s'],
  },
  {
    title: 'Internal Developer Platform',
    description:
      'A worked example of an internal developer platform demonstrating self-service infrastructure patterns.',
    status: 'demo',
    statusTone: 'accent',
    // TODO(benjamin): verify stack tags for the IDP example.
    tags: ['backstage', 'crossplane'],
  },
  {
    title: 'rottler.io',
    description:
      'This site: a fully static build with dual light/dark themes and Markdown-authored writing. You are looking at it.',
    status: 'this site',
    statusTone: 'neutral',
    tags: ['astro', 'ssg'],
  },
  // TODO(benjamin): verify — this project comes from the design mockup and may not exist yet.
  {
    title: 'aks-pool-rollover',
    description:
      'Terraform module and GitHub Actions workflow for blue-green AKS node-pool upgrades, extracted from production.',
    status: 'oss',
    statusTone: 'neutral',
    tags: ['terraform', 'azure'],
  },
];
