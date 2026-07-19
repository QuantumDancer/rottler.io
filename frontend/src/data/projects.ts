// Project cards shown on the Projects page. Descriptions are placeholders until
// the real write-ups land; no links are wired up yet.

export interface Project {
  title: string;
  description: string;
}

export const projects: Project[] = [
  {
    title: 'Homelab',
    // TODO(benjamin): describe the homelab (hardware, services, what it's for)
    description: 'A self-hosted lab for running and experimenting with services at home.',
  },
  {
    title: 'Internal Developer Platform (example implementation)',
    // TODO(benjamin): describe the IDP example (goals, stack, what it demonstrates)
    description:
      'A worked example of an internal developer platform demonstrating self-service infrastructure patterns.',
  },
];
