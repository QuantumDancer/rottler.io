---
title: "The Cloud Resume Challenge: Frontend"
description: "Building a webpage with Astro and Tailwind CSS"
tags: ["cloud-resume-challenge", "astro", "tailwind"]
publishDate: 2024-01-03
---

The first part of the challenge is to build a webpage with HTML and CSS.
To make this easier, I have decided to use two frameworks: [Astro](https://astro.build/) and [Tailwind CSS](https://tailwindcss.com/).
Right now, I will focus on only building parts of the webpage, i.e., the frontpage and the blog section.
Once this is finished, I can continue on setting up the needed AWS infrastructure and CI/CD pipeline that will deploy the infrastructure and webpage content.
The CV section and overview of recent work experience will follow later.

Astro is a web framework that enables the creation of simple content-driven websites.
Furthermore, it supports the generation of static sites, i.e., no backend is needed.
A blog can be easily implemented via Astro's [Content Collections](https://docs.astro.build/en/guides/content-collections/).
It also supports writing content in Markdown which is automatically converted to HTML.
Actually, the text you are reading right now is written in Markdown.

Tailwind CSS is a popular CSS framework that provides a set of utility classes that one can apply directly to HTML elements.
Since I'm no frontend developer I also used a component library for Tailwind CSS ([daisyUI](https://daisyui.com/))
so that I don't need to start from scratch creating the design of the web page.

For the actual implementation both Astro and Tailwind provide an excellent documentation.
I've started by creating the main layout of the web page.
For this I need a header containing the navigation and links to social media and a footer.
I also added a toggle to switch between light and dark mode.
Tailwind makes it easy to create a responsive layout, so the web page should work both on mobile and desktop.
Next, I've added the front page, that contains a short introduction about myself and a link to this blog and the GitHub repository,
where the code of this project is hosted.
Last, I've added the blog section of this web page. It consists of an overview page where all blog entries are listed and the layout for individual blog posts.

With that out of the way, let's create some cloud infrastructure to host this web page.
