// Structured CV content, migrated verbatim from the legacy site into typed
// data so cv.astro is pure presentation. Prose that contained inline links in
// the legacy markup is kept as plain text here, with the referenced resources
// moved into an explicit `links` list — this keeps the data HTML-free while
// preserving every URL.

export interface CvLink {
  label: string;
  href: string;
}

// A project block nested under a position (used by the Freiburg researcher role).
export interface PositionProject {
  title: string;
  period: string;
  description?: string;
  links?: CvLink[];
  highlights: string[];
  technologies?: string;
}

export interface Position {
  title: string;
  organization: string;
  period: string;
  summary?: string;
  highlights?: string[];
  projects?: PositionProject[];
}

export interface Publication {
  title: string;
  // Single descriptive line, e.g. "Presentation | 9th bwHPC Symposium | October 2023 | Mannheim, DE".
  meta: string;
  links: CvLink[];
}

export interface Education {
  degree: string;
  period: string;
  institution: string;
}

export interface SkillGroup {
  category: string;
  // Comma-joined values on one line, matching the design's skills grid.
  items: string;
}

export interface Certification {
  name: string;
  year: string;
}

// Header block for the CV page (heading, one-line summary, contact/PDF).
export const profile = {
  heading: 'Curriculum vitae',
  // The design mocked "9 years across cloud infrastructure", which only partly
  // fits — the real path runs from research computing (particle physics) into
  // leading a platform engineering team.
  tagline: 'Platform engineering team lead with a background in scientific research computing.',
  location: 'Rotkreuz, Switzerland',
  // TODO(benjamin): produce a downloadable CV PDF, then point this at it. Until
  // then the download button falls back to a no-op href.
  pdfUrl: undefined as string | undefined,
};

// Curated skills inventory, mirroring the groups in the LaTeX CV.
export const skills: SkillGroup[] = [
  { category: 'Containers & orchestration', items: 'Kubernetes, Helm, ArgoCD, Talos Linux, Docker, Podman' },
  { category: 'Infrastructure as code', items: 'Ansible, Terraform, Packer, Puppet' },
  { category: 'Observability & monitoring', items: 'Prometheus, Grafana, Grafana Alloy, Loki, Mimir, Nagios' },
  { category: 'CI/CD & DevOps', items: 'Git, GitLab CI, GitHub Actions, Bitbucket Pipelines' },
  { category: 'Cloud & virtualization', items: 'Azure, AWS, Proxmox' },
  { category: 'Programming & scripting', items: 'Python, Rust, Bash, SQL, C++' },
  { category: 'Spoken languages', items: 'German, English' },
];

export const certifications: Certification[] = [
  { name: 'Certified Kubernetes Administrator (CKA) — The Linux Foundation', year: 'March 2026' },
  { name: 'AWS Certified Solutions Architect – Associate', year: 'June 2024' },
];

export const positions: Position[] = [
  {
    title: 'Teamlead Platform Engineering & Observability',
    organization: 'enovetic ag, Rotkreuz, Switzerland',
    period: 'July 2026 - present',
    highlights: [
      "Lead a team of three engineers responsible for the company's Linux environment and platform engineering, setting technical standards and helping engineers grow",
      "Rethink infrastructure and provisioning from scratch for the company's next-generation product platform, designed around golden paths and self-service from day one",
      'Build the self-service automation that lets development teams provision environments, infrastructure and deployments on their own, with Backstage as the internal developer portal in front of it',
      'Drive the renewal of legacy Linux systems, rebuilding servers on the automated, Ansible-based infrastructure',
      'Deliver a Linux-based development environment for application developers (Linux VMs, Podman, Development Containers)',
      'Own the Flowable workflow platform (Terraform, Helm, AKS), running in production for a product team',
    ],
  },
  {
    title: 'Linux / Cloud Engineer',
    organization: 'enovetic ag, Rotkreuz, Switzerland',
    period: 'July 2024 - June 2026',
    highlights: [
      'Co-managed 120+ Linux VMs across production environments, including load balancers, web, database, FTP, and SMTP servers',
      'Designed and implemented a modular Ansible role structure, replacing manual server administration with fully automated, version-controlled deployments',
      'Migrated monitoring from Nagios to the Grafana LGTM stack: Alloy for centralized log and metrics collection, self-service dashboards for development teams, and synthetic testing of all company SaaS applications via the Prometheus Blackbox exporter',
      'Developed Terraform modules and Helm charts to deploy Flowable workflow engine instances on Kubernetes (AKS), with CI/CD pipelines for automated rollout of new versions',
      'Designed and built an on-prem hyperconverged Proxmox/Ceph cluster to host a new Linux-VM-based development environment for application developers',
      'Migrated legacy load balancers to HAProxy and hardened Rocky Linux 9 and Apache based on CIS benchmarks',
      'Supported development and customer-support teams and took part in the IT infrastructure on-call rotation',
    ],
  },
  {
    title: 'Doctoral / postdoctoral researcher (Wissenschaftlicher Mitarbeiter)',
    organization: 'Physikalisches Institut, Universität Freiburg',
    period: 'February 2018 - June 2024',
    projects: [
      {
        title: 'Administration of a computing cluster for elementary particle physics',
        period: 'June 2019 - June 2024',
        description:
          'The ATLAS-BFG cluster is a high-throughput cluster (HTC) that allows users from local particle physics research groups and global members of the ATLAS collaboration to analyse collision data from the ATLAS experiment. The core of the cluster is a batch system with 3400 CPU cores and a distributed object storage system with 4 PB of storage space. The cluster is part of the World Wide LHC Computing Grid (WLCG).',
        links: [
          { label: 'ATLAS-BFG cluster', href: 'https://www.hpc.uni-freiburg.de/atlas-bfg' },
          { label: 'ATLAS experiment', href: 'https://atlas.cern/' },
        ],
        highlights: [
          'Participation in the operation and maintenance of the cluster',
          "Integration of new and existing services into the cluster's IaC solution.",
          "Maintenance and further development of the cluster's monitoring infrastructure",
          'Support for local users',
        ],
        technologies: 'Puppet, Packer, Docker, Prometheus, Grafana, Nagios, Slurm, CentOS 7, Alma 9',
      },
      {
        title: 'Framework for the accounting of shared and opportunistic resources',
        period: 'April 2023 - June 2024',
        description:
          'AUDITOR (AccoUnting DatahandlIng Toolbox for Opportunistic Resources) is a flexible and extensible framework for the accounting of shared and opportunistic resources.',
        links: [
          { label: 'AUDITOR', href: 'https://alu-schumacher.github.io/AUDITOR/latest/' },
        ],
        highlights: [
          'Planning of new features and technical management of contributing developers',
          'Release management: Publishing new releases, communication with users',
          'Operation of multiple AUDITOR instances within the ATLAS-BFG cluster',
        ],
        technologies: 'Rust, Python, PostgreSQL, Docker, GitHub Actions',
      },
      {
        title: 'Monitoring of WLCG grid sites',
        period: 'January 2022 - June 2024',
        description:
          'HammerCloud is a monitoring and testing framework, that is developed and used by the ATLAS collaboration to monitor the availability and performance of the global grid infrastructure of the WLCG.',
        links: [
          { label: 'HammerCloud', href: 'http://hammercloud.cern.ch' },
        ],
        highlights: [
          'Migrating from Python 2/Django 1 to Python 3/Django 4',
          "Migration to CERN's new OIDC-based single sign-on solution",
          'Redesign of the architecture to a container-based setup',
        ],
        technologies: 'Python, Django, Docker, Docker Compose',
      },
      {
        title:
          'PhD Thesis: Search for Higgs-Boson Pair-Production in the bbll+ETMiss final state with the ATLAS detector at √s = 13 TeV',
        period: 'February 2018 - May 2023',
        highlights: [
          'Measurement of the cross section and signal strength of non-resonant Higgs-boson pair-production',
          'Measurement of the trilinear Higgs-boson self-coupling',
          'Analysis of ~100TB of data',
          'Improving the event selection with neural networks',
          'Statistical analysis (confidence intervals, hypothesis testing)',
          'Improved sensitivity by a factor of three compared to previous analysis',
          'Six-month research stay at CERN',
        ],
        // TODO(benjamin): technologies line for PhD thesis (legacy had a copy-paste error)
      },
      {
        title: 'Teaching duties',
        period: 'April 2018 - June 2024',
        highlights: [
          'Correction of weekly exercises and final exams',
          'Discussion of the exercises with the students in weekly tutorials',
        ],
      },
    ],
  },
  {
    title: 'Research assistant (Wissenschaftliche Hilfskraft / HiWi)',
    organization: 'Physikalisches Institut, Universität Freiburg',
    period: 'March 2017 - December 2017',
    summary: 'Assisting the administrators of the ATLAS-BFG cluster',
  },
];

export const publications: Publication[] = [
  {
    title: 'Fair sharing of resources between clusters with AUDITOR',
    meta: 'Presentation | 9th bwHPC Symposium | October 2023 | Mannheim, DE',
    links: [
      { label: 'Slides', href: 'https://indico.scc.kit.edu/event/3635/contributions/14547/' },
    ],
  },
  {
    title: 'Bringing the ATLAS HammerCloud setup to the next level with containerization',
    meta: 'Conference talk | 26th International Conference On Computing In High Energy & Nuclear Physics (CHEP) | May 2023 | Norfolk, VA, USA',
    links: [
      { label: 'Slides', href: 'https://indico.jlab.org/event/459/contributions/11486/' },
      { label: 'Proceedings', href: 'https://cds.cern.ch/record/2871988' },
    ],
  },
  {
    title:
      'Opportunistic extension of a local compute cluster with NEMO resources for HEP workflows',
    meta: 'Presentation | 14th Annual meeting of the Helmholtz Alliance "Physics at the terascale" | November 2021 | DESY Hamburg, DE (online)',
    links: [
      { label: 'Slides', href: 'https://indico.desy.de/event/31325/contributions/112490/' },
    ],
  },
  {
    title:
      'Search for Higgs-Boson Pair-Production in the bbll+ETMiss final state with the ATLAS detector at √s = 13 TeV',
    meta: 'PhD thesis | May 2023 | Freiburg, DE',
    links: [
      { label: 'Publication', href: 'https://freidok.uni-freiburg.de/data/238604' },
    ],
  },
  {
    title:
      'Search for non-resonant Higgs boson pair production in the 2b+2l+ETMiss final state in pp collisions at √s = 13 TeV with the ATLAS detector',
    meta: 'Publication | October 2023 | CERN',
    links: [
      { label: 'JHEP 02 (2024) 037', href: 'https://link.springer.com/article/10.1007/JHEP02(2024)037' },
    ],
  },
];

export const education: Education[] = [
  {
    degree: 'Dr. rer. nat. Physik',
    period: 'February 2018 - May 2023',
    institution: 'University of Freiburg, DE',
  },
  {
    degree: 'M. Sc. Physik',
    period: 'October 2015 - November 2017',
    institution: 'University of Freiburg, DE',
  },
  {
    degree: 'B.Sc. Physics',
    period: 'October 2012 - September 2015',
    institution: 'University of Freiburg, DE',
  },
  {
    degree: 'Abitur',
    period: 'June 2012',
    institution: 'Oken-Gymnasium Offenburg, DE',
  },
];
