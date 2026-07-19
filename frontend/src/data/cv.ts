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
  // TODO(benjamin): confirm the tagline. The design mocked "9 years across cloud
  // infrastructure", which only partly fits — the real path runs from research
  // computing (particle physics) into platform engineering.
  tagline: 'Platform engineer with a background in scientific research computing.',
  // TODO(benjamin): current role is in Rotkreuz, CH; confirm which location to show.
  location: 'Freiburg, Germany',
  // TODO(benjamin): produce a downloadable CV PDF, then point this at it. Until
  // then the download button falls back to a no-op href.
  pdfUrl: undefined as string | undefined,
};

// Aggregated from the technologies named across the roles below and grouped to
// match the design's skills grid.
// TODO(benjamin): curate this — it is inferred from the experience section, not
// an authored skills inventory (note cv.ts never mentions Kubernetes/Azure/AWS,
// unlike the home-page bio).
export const skills: SkillGroup[] = [
  { category: 'Infrastructure as code', items: 'Ansible, Terraform, Puppet, Packer, Helm' },
  { category: 'Observability', items: 'Prometheus, Grafana, Loki, Mimir, Alloy, Nagios' },
  { category: 'Containers & delivery', items: 'Docker, Docker Compose, GitHub Actions' },
  { category: 'Languages', items: 'Rust, Python, Bash' },
  { category: 'Platforms & OS', items: 'Rocky Linux, AlmaLinux, HAProxy, Slurm, PostgreSQL' },
];

// TODO(benjamin): add certifications if any. The design mocked CKA / AZ-305 /
// Terraform Associate as samples; none are in the real CV, so the section stays
// hidden (empty array) until this is filled in.
export const certifications: Certification[] = [];

export const positions: Position[] = [
  {
    // Retitled from the legacy "Linux / Cloud Engineer"; same employer.
    title: 'Platform Engineer',
    organization: 'enovetic ag, Rotkreuz, Switzerland',
    period: 'July 2024 - present',
    // TODO(benjamin): update bullets for platform-engineering focus (Azure, Kubernetes)
    highlights: [
      'Co-manage 120+ Linux VMs across diverse production environments, including load balancers, web servers, database servers, FTP servers, and SMTP relays',
      'Provide technical support to development teams and customer support operations',
      'Led strategic migration from legacy load balancer solutions to HAProxy, implementing status monitoring through Grafana dashboards',
      'Architected and implemented modular Ansible role structure for scalable VM management, transforming manual server administration into fully automated, version-controlled infrastructure deployments',
      'Implement Rocky Linux 9 and Apache security hardening configurations based on CIS benchmarks',
      'Orchestrated monitoring infrastructure migration from Nagios to modern Grafana/Loki/Mimir stack, configured Alloy for centralized log and metrics collection, and developed custom dashboards that enable self-service access to application metrics and logs for development teams',
      'Implemented Prometheus Blackbox exporter allowing for synthetic testing across all company SaaS applications',
      'Developed Terraform modules and Helm charts for automated deployment of multiple Flowable workflow engine instances',
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
