---
layout: post
title: "Getting Started with Open Source Contributing"
date: 2016-12-21 10:00:00
comments: true
keywords: ""
categories:
- Open Source
tags:
- open-source
---

As developers who regularly use open source projects know, those projects need to be updated by the
open source community itself. This includes new features, bug fixes, and ensuring the extension or plugin plays nicely with
other dependencies in a project.

Sometimes it can be hard to know where to start when contributing to open source. Maybe you want to give back and "do your part"
as a member of the open source community, or maybe you found an issue in a plugin you were using and want to update the project 
so others won't have the same problem.

Contributing to open source can also look really good on your resume, and some companies even specifically look for
that when hiring. I wanted to share a few tips I've learned for how to get started in open source contributing, and you may
find it's actually easier than you think!

## I can't come up with a new project, every idea I have has already been implemented!

This is something I've struggled with as well. I would love to start something completely from scratch, maybe a new Ruby gem or
Angular plugin, but a quick Google search will usually help you find an existing project that does exactly what you were thinking
of creating, or at least something close to it.

If you really want to start a new project, you may have success in simply "re-inventing the wheel". I was listening to a podcast
the other day, and the creator of the [Sucker Punch](https://github.com/brandonhilkert/sucker_punch) Ruby gem was explaining how
he got the idea for this project. Sucker Punch is inspired from another Ruby gem, [Sidekiq](https://github.com/mperham/sidekiq),
which both handle background job processing. Each gem depends on multi-threaded Ruby to complete their tasks, however Sucker
Punch came out of a desire to run both the application that was using it and the background jobs on a single processor, whereas 
Sidekiq requires it's own processor for background jobs.

Perhaps digging into an existing project and seeing how it's implemented can inspire something similar for you? Regardless, checking
out the source code for the open source projects you use is a good practice to do anyways, and may even be necessary at times. If you
think you can improve on an existing implementation, give it a shot! If it doesn't work out in the end, you took a risk and probably
learned quite a lot from it, plus you could still put it up on GitHub and explain what it was attempting to do. I've definitely done
the same.

## How can I help on an existing project?

### Contributing to popular projects

If you're wanting to contribute to existing projects, the first thing you'll probably do is look in your `Gemfile` or `package.json`
for a project you've been working on, or maybe check out the [trending repositories](http://github.com/trending) on GitHub. If you can find
a bug or feature that you feel that you can tackle, more power to you! However, I've noticed the items you find listed under the `Issues` tab
are usually very specific bugs related to a very specific project setups, or large and daunting features that require a good amount of existing
knowledge on the project.

Occasionally you will find an issue that has recently been opened in the last few hours that no one has addressed yet, so if you feel that it's 
something you can work on and submit a pull request for in a reasonable amount of time, that might be the way to get your "foot in the door" for 
contributing to a popular repository.

### Finding less-trafficked projects

A lot of time plugins you're using have dependencies on other plugins, so taking a look at what a more popular repo depends on can help you find
a project that has some feature requests or bugs filed that the contributor(s) of that project haven't gotten to yet. You can also look through some of
those projects you stumble upon while Googling solutions to see if you can help in any way.

### Updating documentation

This is probably the easiest way to get started with contributing. Documentation is hard to keep up to date, especially if there's a lot of it. This can
include README files, API documentation, code comments, etc. One of the more recent projects I contributed to was simply assisting in updating some of the
wording for a README file, where it seemed as though the project author may not have spoken English as their first language. Even though I wasn't using the
plugin myself (I was just exploring some repos) and was written in a programming language I wasn't familiar with, it only took about 10 minutes to get a 
pull request open with some grammatical fixes, and the author gladly merged it in.

### Writing tests

There has been a big push over the past decade to write units tests for your projects. You'll find most open source projects already have unit (and integration) tests,
but if you feel comfortable writing tests and you find a project doesn't have them, this would also be a great starting point that both the author and other contributors
would greatly appreciate.

## Contributing guidelines

You'll find a lot of projects will have documenation to guide you in documentation writing, code writing, pull request formatting, and code styling the way the
author prefers. You'll often find Markdown files at the top level of the file structure within a project that have pretty self-explanatory names related to
contributing guidelines. For example, the [Angular](https://github.com/angular/angular) project has a [COMMITTER.md](https://github.com/angular/angular/blob/master/COMMITTER.md) file,
[CONTRIBUTING.md](https://github.com/angular/angular/blob/master/CONTRIBUTING.md) file, [DEVELOPER.md](https://github.com/angular/angular/blob/master/DEVELOPER.md) file,
and [NAMING.md](https://github.com/angular/angular/blob/master/NAMING.md) file to name a few, all related to helping you contribute to the project.


## Conclusion

I hope this post has given you some ideas on how you can get started in contributing to open source, or at least shown you the bar isn't necessarily set as high as you think.
There are challenges out there for any level of developer, and don't be afraid to reach out to the project author(s) either on how you can help! Most of them are more than
happy to show you how you can assist them, and may even be open to pair programming with you on some bug fixes and feature requests. Happy coding!
