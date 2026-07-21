// Project cards shown on the Projects page. The card structure (tag chips,
// optional link) is adopted from the Claude Design v1 Projects mockup.

export interface Project {
  title: string;
  description: string;
  /** Mono tag chips; keep them short (stack or domain). */
  tags: string[];
  /** Card link target. Omitted until there is a real destination to point at. */
  href?: string;
}

export const projects: Project[] = [
  {
    title: "Homelab",
    description:
      "My homelab based on IaC and GitOps: Proxmox for virtualization, Linux VMs created with Terraform and configured with Ansible, and a three-node Talos Kubernetes cluster provisioned with Terraform and managed via ArgoCD.",
    tags: ["kubernetes", "argocd", "ansible"],
    href: "https://github.com/QuantumDancer/Homelab",
  },
  {
    title: "Internal Developer Platform",
    description:
      "A demo implementation of an internal developer platform: self-service infrastructure through Backstage, Crossplane, and Argo CD. Running on AWS and the homelab.",
    tags: ["backstage", "crossplane", "aws"],
    href: "https://github.com/QuantumDancer/idp",
  },
  {
    title: "rottler.io",
    description:
      "This site: a fully static homepage running on (mostly) free AWS infrastructure.",
    tags: ["aws"],
    href: "https://github.com/QuantumDancer/rottler.io",
  },
];
