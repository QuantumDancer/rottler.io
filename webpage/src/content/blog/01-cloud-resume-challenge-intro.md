---
title: "The Cloud Resume Challenge: Introduction"
description: "Overview of the Cloud Resume Challenge."
tags: ["cloud-resume-challenge"]
publishDate: 2024-01-02
---

Recently, I discovered the [Cloud Resume Challenge](https://cloudresumechallenge.dev/docs/the-challenge/aws/),
an open-source project designed to assist individuals in building and showcasing their proficiency in cloud computing and associated technologies.

To align the challenge with my preferences, I've reorganized and consolidated the suggested steps. Here's the refined set of steps I've developed:

1. Create a basic webpage using HTML, CSS, and Javascript.
2. Establish a cloud infrastructure (S3, CloudFront, DNS) for hosting the webpage.
3. Deploy the webpage to the cloud.
4. Implement automation for the deployment of both the cloud infrastructure and the webpage.
5. Integrate a backend service and a database to track page views.
6. Enhance the webpage by incorporating a CV page and providing an overview of recent work experience.
7. Attain the _AWS Certified Solutions Architect_ certification and include it on the CV.

I will delve into the specifics of each step in individual blog posts.

For now, let's just do some general setup.
I've decided that I won't store the different components (frontend, backend, infrastructure) in separate repositories.
So I've created a [GitHub repository](https://github.com/QuantumDancer/rottler.io) where I will store all my code.
I will put each component into its own directory structure. So right now, the repository looks like this on my local machine:

```
$ tree .
.
├── backend-counter
├── infra
└── webpage
```

That's all for now.
Next, I'm going to build the frontend, including this blog.
