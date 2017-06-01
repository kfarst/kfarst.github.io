---
layout: post
title: "Slaying the MVC Monster in Rails"
date: 2017-05-29 15:05:31
comments: true
description: "Slaying the MVC Monster in Rails"
keywords: "ruby,rails,refactoring,mvc"
published: false
categories:
- Ruby on Rails
tags:
- Ruby on Rails
---

I've been out of the Rails game for a litle while I'll admit, but I feel like I couldn't have a blog without some
Ruby and Rails-related posts. Having started the first few years of my career using the framework, I thought it
might be nice to ease my way back into it by talking about some of the pitfalls and strategies to overcome what I think all
model-view-controller frameworks suffer from, but more specifically discussing some of the Rails-flavored versions of
those solutions.

What makes this even more difficult is the fact that each topic I'll be discussing isn't isolated within itself, but
very likely shares similar underlying principles. For example, I may talk about a gem that can help clean things up,
but that gem has an underlying design pattern which you could implement yourself for some other purpose. My goal is
just to talk about some high level strategies and ideas that can inspire you to try new ideas, or stumble upon
an existing resource that can help you.

Finally, I'll be leaving a lot out of each topic, as each one could literally have its own book. I'll do my best
to link to resources to help dive into each strategy more in-depth. Really, all I'm trying to accomplish is to
aggregate summaries of larger topics in a quicker and easier read, then setting you loose to explore more into that topic
yourself. So (deep sigh), without further ado, here we go...

## Preface

What?! I thought all that crap above *was* the preface?! Sorry, I just felt the need to clarify what I meant when I'm
talking about cleaning up and refactoring MVC. I didn't want this to be another article scolding you for putting too
much logic in your controllers and into your models, it's more about helping to avoid the next problem that arises
from that. All that logic has to go somewhere, and instead of bloated controllers, you'll just end up with bloated
models. If you can avoid having to refactor huge models from the start, it can make for a much happier development
experience.

### The Model

Since we're on the topic, let's talk about the model. Sure, you're making sure there isn't too much logic in there,
but when it all comes down to it, the name of the game is that everything should have a single responsibility. That
being said, [https://github.com/rails/rails/tree/master/activerecord](ActiveRecord) itself is far from single responsibility, 
but it was designed that way. From the pattern's definition:

<blockquote>
An object carries both data and behavior. Much of this data is persistent and needs to be stored in a database.
Active Record uses the most obvious approach, putting data access logic in the domain object.
This way all people know how to read and write their data to and from the database.
</blockquote>

Let's take a look at a few major responsibilities `ActiveRecord` has, and a possible solution for making things a little
cleaner:

* **Persistence** - Probably the most popular gem solution used for separating business logic from persistence logic would
be the [http://datamapper.org/](DataMapper) object-relational mapper. FYI however, it is a *replacement* for `ActiveRecord`, but it might make
migrations less of a headache for you also! You define the properties of the model *inside* the model, as opposed to migrations. Additionally,
changing those mappings in whatever data source you're using is as simple as running a command. No more generating huge lists of migrations that
you have to manage separately.

* **Validation** - This is a tough one, because there are a few options for handling this.
