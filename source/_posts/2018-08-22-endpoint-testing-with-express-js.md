---
layout: post
title: "10 Minutes of Code: Enpoint Testing With Express.js"
date: 2018-08-22 9:02:48
comments: true
description: "10 Minutes of Code: Enpoint Testing With Express.js"
keywords: "node,express,testing,10minutesofcode"
categories:
- 10-mins-of-code
tags:
- 10-mins-of-code
---

My team at work was recently tasked with exposing an endpoint externally for a third-party service. The project serves as our
API microservice, which I had built out a unit testing suite for a few months ago. We've been slowly "fleshing out" out our test cases
for various support classes within the project, and adding documentation for the endpoints themselves. However, now that we would start serving data to third-parties, I realized we needed to be testing our actual endpoints and their responses as well.

A quick Google search landed me on the GitHub repository for [SuperTest](https://github.com/visionmedia/supertest), which is a

<blockquote>
super-agent driven library for testing node.js HTTP servers using a fluent API
</blockquote>

as laid out in the project's description. In short, the testing package provides a framework for calling an endpoint and asserting its response matches the expectation based on the data provided to it.

{% highlight javascript %}
  describe('GET /user', function() {
    it('respond with json', function(done) {
      request(app)
        .get('/user')
        .set('Accept', 'application/json')
        .expect('Content-Type', /json/)
        .expect(200, done);
    });
  });
{% endhighlight %}

Looking at this example from the docs, after setting up a request *SuperTest* allows you to modify request headers and bodies, specify complex query strings and other parameters, and validate a response's headers, body, and status code. You might also notice the request setup and response assertions can be combined into a single or multiple chain of method calls. The project is based on [SuperAgent](https://github.com/visionmedia/superagent), the non-testing equivalent of setting up a Node.js HTTP client using the same API. *SuperTest* would then allow to you to set up your test cases with the same structure as an endpoint built with *SuperAgent*, integrating assertion validation into the response.

Despite the influence of *SuperAgent* on *SuperTest*, one is not required for the other. I would still get the benefit of chainable assertions and easy-to-build test requests, even though the endpoints we were testing against were built with [Express.js](https://expressjs.com/). Following an example from the project, I pulled in the dependencies I would need for my test cases and set up the first assertions.

{% highlight javascript %}
var request = require('supertest');
var express = require('express');
var controller = require('../../controllers/embed');

describe('/embed', () => {
  var app;

  beforeEach(() => {
    // set up express app
    app = express();
    // attach embed endpoints to express app
    controller(app);
  });

  describe('with a valid URL', () => {
    it('returns the correct response', (done) => {
      ...
    });
  });
  ...
});
{% endhighlight %}

I originally tried to pass the application entrypoint (`app.js`) into the *Express* instance, but ended up being too much overhead trying to provide all the depencies the app needed to run within the test environment. Conveniently though the endpoints in our API microservice are grouped by similar responsibilities into "controller" modules that accept an *Express* application as a dependency.

{% highlight javascript %}
module.exports = function(app) {
  "use strict";

  app.get('/embed', function(req, res) {
    ...
  });
};
{% endhighlight %}

Because of this, in the test setup I was able to require only the necessry controller module (`var controller = require('../../controllers/embed');`) and pass the *Express* instance into the endpoint module (`controller(app);`). From there I was able to build out my test cases and validate the correct request scenarios and responses.

{% highlight javascript %}
...
it('returns the correct response', (done) => {
  request(app)
    .get('/embed')
    .query({ ... })
    .expect(200)
    .then(res => {
      expect(res.body).toMatchObject({
        ...
      });

      done();
    })
    .catch(err => done.fail(err));
});
...
{% endhighlight %}