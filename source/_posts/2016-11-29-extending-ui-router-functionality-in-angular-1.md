---
layout: post
title: "Extending UI-Router Functionality in Angular 1"
date: 2016-11-29 07:43:19
comments: true
description: "Extending UI-Router Functionality in Angular 1"
keywords: "angular,angular1,ui-router,ui.router,es5,javascript"
categories:
- Angular
tags:
- angular1
---

<a href="https://ui-router.github.io/ng1/">UI-Router</a> is an alternative to the
de-facto Angular 1 router, basing its functionality around *states* as opposed
to routes. I won't be going into the details of the router, but I wanted to demonstrate
the flexibility and potential of it, using a concept called *decorators*.

From the documentation itself, a decorator

<blockquote>
Allows you to extend (carefully) or override (at your own peril) the stateBuilder
object used internally by $stateProvider. This can be used to add custom functionality to
ui-router, for example inferring templateUrl based on the state name.
</blockquote>

The example the documentation gives is perfect, because that's exactly what we're going
to implement.

## Getting started

We have a very simple app with 5 routes. One top-level abstract state, two second-level states,
(Route1 and Route2), and two nested states showing an unordered list under each of the two second-level
routes.

<img src="http://i.imgur.com/3ThVmav.gif" width="100%">

Since two of the five routes are duplicates, I'll show three of them each demonstrating a different
case to account for in terms of how the view is rendered.

{% highlight javascript %}
angular.module('app', ['ui.router'])
.config(function ($stateProvider) {
  ...
  $stateProvider
  .state('app', {
    abstract: true,
    url: ''
  })
  .state('app.route1', {
    url: '/route1',
    templateUrl: 'route1.html'
  })
  .state('app.route1.list', {
    url: '/list',
    views: {
      'list@app.route1': {
        templateUrl: 'route1.list.html',
        controller: function ($scope) {
          $scope.items = ['A', 'list', 'of', 'things'];
        }
      }
    }
  })
  ...
});
{% endhighlight %}

The three types of states we have are

<ul>
  <li>Abstract state with no view</li>
  <li>A state with a `templateUrl`</li>
  <li>A state with a nested `views` object</li>
</ul>

## Creating the decorator

Any decorators that are created need to be declared in the `config` block just as the state definitions are.
We'll be adding it before the state definitions. The basic skeleton looks like this:

{% highlight javascript %}
  $stateProvider.decorator('templateUrl', function(state) {
    // Implementation here
  });
{% endhighlight %}

The `state` parameter is an object, containing information pertaining to the state. If we look at the `self`
property on the `state` object, it will essentially look exactly like the state definition itself. For instance,
if we look at the state

{% highlight javascript %}
  ...
  .state('app.route1.list', {
    url: '/list',
    views: {
      'list@app.route1': {
        templateUrl: 'route1.list.html',
        controller: function ($scope) {
          $scope.items = ['A', 'list', 'of', 'things'];
        }
      }
    }
  })
  ...
{% endhighlight %}

calling `state.self` would return

{% highlight javascript %}
  {
    url: '/list',
    views: {
      'list@app.route1': {
        templateUrl: 'route1.list.html',
        controller: function ($scope) {
          $scope.items = ['A', 'list', 'of', 'things'];
        }
      }
    }
  }
{% endhighlight %}

which is just the object part of the `state` implementation. You can access the state name with,
you guessed it, `state.name`. To interpolate the `templateUrl`, we'll take the state name, remove
the `app.` prefix, and append `.html` to the end. If you follow this convention, you shouldn't need
to explicitly define a `templateUrl` on a `state` object.

{% highlight javascript %}
  $stateProvider.decorator('templateUrl', function(state) {
    // Separate the period-separated pieces of the state name
    var stateName = state.name.split('.');

    // Remove the first part of the state name, which is 'app'
    stateName.shift();

    // Assemble the state name into a period-separated string again,
    // with the HTML suffix appended
    return stateName.concat('html').join('.');
  });
{% endhighlight %}

With the code above, a state named `app.foo.bar.baz` without a `templateUrl` would interpolate the URL
as `foo.bar.baz.html`. However, when we reload the server and page with the new decorator defintion, we
get this error in the console:

<blockquote>GET http://localhost:8000/html 404 (Not Found)</blockquote>

It looks like the abstract state has its `templateUrl` interpolated as just the `html` suffix, which makes
sense since the state name is only `app`, so it gets removed during this process. For simplicity's sake,
let's tell the decorator that if the state is abstract to just ignore any `templateUrl` interpolating.

## Restricting the decorator scope

Updating our decorator to ignore abstract states, we have

{% highlight javascript %}
  $stateProvider.decorator('templateUrl', function(state) {
    angular.forEach(Object.keys(state.self), angular.bind(state, function (key) {
      if (key === 'abstract') {
        return;
      }
    }));

    // Separate the period-separated pieces of the state name
    var stateName = state.name.split('.');

    // Remove the first part of the state name, which is 'app'
    stateName.shift();

    // Assemble the state name into a period-separated string again,
    // with the HTML suffix appended
    return stateName.concat('html').join('.');
  });
{% endhighlight %}

Next up, let's check out the `app.route` state:

{% highlight javascript %}
  ...
  .state('app.route1', {
    url: '/route1',
    templateUrl: 'route1.html'
  })
  ...
{% endhighlight %}

If we look at the `templateUrl`, we can verify that this is the URL for the HTML template that would
get generated if the key was missing, so we can just remove `templateUrl`, confident that the decorator
will find the right template. However, this brings up a good point, what if you *do* want to override
the default functionality of the decorator and declare your own template name? In that case, we should
probably tell the decorator to also fall back to default UI-Router functionality if a `templateUrl` is already
defined, just like we're doing for abstract states.

{% highlight javascript %}
  $stateProvider.decorator('templateUrl', function(state) {
    angular.forEach(Object.keys(state.self), angular.bind(state, function (key) {
      if (['abstract', 'templateUrl'].indexOf(key) > -1) {
        return;
      }
    }));

    // Separate the period-separated pieces of the state name
    var stateName = state.name.split('.');

    // Remove the first part of the state name, which is 'app'
    stateName.shift();

    // Assemble the state name into a period-separated string again,
    // with the HTML suffix appended
    return stateName.concat('html').join('.');
  });
{% endhighlight %}

Since `templateUrl` isn't the only way to declare a template in UI-Router, we should add `template` and `templateProvider`
to the list of keys to ignore also.

{% highlight javascript %}
  $stateProvider.decorator('templateUrl', function(state) {
    angular.forEach(Object.keys(state.self), angular.bind(state, function (key) {
      if (['abstract', 'templateUrl', 'template', 'templateProvider'].indexOf(key) > -1) {
        return;
      }
    }));

    // Separate the period-separated pieces of the state name
    var stateName = state.name.split('.');

    // Remove the first part of the state name, which is 'app'
    stateName.shift();

    // Assemble the state name into a period-separated string again,
    // with the HTML suffix appended
    return stateName.concat('html').join('.');
  });
{% endhighlight %}

Finally, we have the `views` object, which is its own nested declarations of keys related to rendering a view. Sure we can
drill down into it and execute the same logic, but what template names do we fall back to if one of the template-related
keys isn't found? `list@app.route1.html` is pretty weird for a template name, so I guess we should leave out the `views`
key from our decorator as well.

{% highlight javascript %}
  $stateProvider.decorator('templateUrl', function(state) {
    angular.forEach(Object.keys(state.self), angular.bind(state, function (key) {
      if (['abstract', 'templateUrl', 'template', 'templateProvider', 'views'].indexOf(key) > -1) {
        return;
      }
    }));

    // Separate the period-separated pieces of the state name
    var stateName = state.name.split('.');

    // Remove the first part of the state name, which is 'app'
    stateName.shift();

    // Assemble the state name into a period-separated string again,
    // with the HTML suffix appended
    return stateName.concat('html').join('.');
  });
{% endhighlight %}

## That was a lot of work for very little payoff...

Sadly, this is true. We could create another decorator specifically for the `views` object,
[which they've actually done in the documentation](https://ui-router.github.io/ng1/docs/0.3.1/index.html#/api/ui.router.state.$stateProvider),
but hiding away this default UI-Router functionallity can introduce problems of its own. Sometimes it's just better
to be explicit so as to not cause confusion and difficult debugging situations. As powerful as decorators are,
it's quickly apparent why the documentation states that you should add them "carefully" and "at your own peril".

## Conclusion

I hope you enjoyed this deep dive into UI-Router functionality, and although what we created ended up not being
that practically useful, it was a good exercise in learning more about the internals of how the third-party router works,
and sometimes just tinkering with code that you don't end up using can help tremendously in your understanding
of a language, framework, or package. Ideally, you would use decorators to *extend* (again, carefully) functionality
of UI-Router, as opposed to overriding functionality which already works very well. Good luck in your coding
adventures!
