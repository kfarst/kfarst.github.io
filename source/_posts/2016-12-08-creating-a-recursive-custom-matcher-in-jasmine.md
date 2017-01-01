---
layout: post
title: "Creating a Recursive Custom Matcher in Jasmine"
date: 2016-12-08 12:00:00
comments: true
keywords: ""
categories:
- Jasmine
tags:
- jasmine
---

I've been writing units tests using Jasmine for quite a while now, and one of the matchers I've wanted would
validate not only that a subset of properties exist on an object, but the property values match the expected
values. Something along the lines of:

{% highlight javascript %}
  expect(actualObj).toIncludeValues({
    foo: 'bar',
    baz: 'blah',
    another: 'value'
   });
{% endhighlight %}

## Working around it

Here are some of the alternatives I tried with the matchers I had available to me.

{% highlight javascript %}
  it('has the expected properties', function () {
    expect(actualObj.foo).toBe(expectedObj.foo);
    expect(actualObj.baz).toBe(expectedObj.baz);
    expect(actualObj.another).toBe(expectedObj.another);
  });
{% endhighlight %}

{% highlight javascript %}
  it('has the expected properties', function () {
    ['foo', 'baz', 'another'].forEach(function (prop) {
      expect(actualObj[prop]).toBe(expectedObj[prop]);
    });
  });
{% endhighlight %}

{% highlight javascript %}
  it('has the expected value for foo', function () {
    expect(actualObj.foo).toBe(expectedObj.foo);
  });

  it('has the expected value for baz', function () {
    expect(actualObj.baz).toBe(expectedObj.baz);
  });

  it('has the expected value for another', function () {
    expect(actualObj.another).toBe(expectedObj.another);
  });
{% endhighlight %}

The first two go against the idea that [each test should only have one assertion](http://betterspecs.org/#single),
and the third can quickly balloon into too many tests and slow down your test suite. Not to mention, these solutions
aren't quite as elegant as the matcher I first described. Needless to say, they didn't really measure up to what I wanted.

## Building the matcher

If I dug around the Googles enough I'm sure I could find something similar to what I was looking for, but I wanted to
try it myself. First, I needed to spec out exactly what I wanted the matcher to do. I wanted the matcher to do
two checks:

<ol>
  <li>Ensure that the property being checked in the expected object also exists on the actual object</li>
  <li>Validate the property being checked in the expected object has the same value as the matching
  property in the actual object</li>
</ol>

The project I created this matcher for uses [Karma](https://karma-runner.github.io), Angular's command line test runner.
I mention this because the setup for the custom matcher may vary based on the configuration you have for your environment.
I created a new file for custom matchers, aply named `spec/customMatchers.js`, and made sure to include the file in my
Karma configuration file. We want the the matcher to be set up before the tests will run, so we'll wrap the matcher in a
`beforeAll()` function.

{% highlight javascript %}
  beforeAll(function () {
    jasmine.Matchers.prototype.toIncludeValues = function (expected) {
      ...
    };
  });
{% endhighlight %}

We get access to the `jasmine` global object, and we'll add a new function to its `Matchers` by adding it to the object's
`prototype`. The subset of properties we're expecting are passed into the function as the `expected` argument. We get access
to the actual object through `this`.

{% highlight javascript %}
  beforeEach(function () {
    jasmine.Matchers.prototype.toIncludeValues = function (expected) {
      var self = this;

      Object.keys(expected).forEach(function (key) {
        ...
      });
    };
  });
{% endhighlight %}

We need to assign `this` to the variable `self` since it will lose context within the `forEach()` function. We'll then
iterate over each of the keys in the `expected` object. The first check we'll do within the `forEach()` loop is to make
sure each expected property is also present in the actual object.

{% highlight javascript %}
  ...
  if (!self.actual.hasOwnProperty(key)) {
    throw new Error("Expected " + JSON.stringify(self.actual) + " to have key '" + key + "'");
  }
  ...
{% endhighlight %}

If it doesn't find a property, we need to throw a descriptive error indicating what key we're missing. An example test failure
on the command line would look like this:

{% highlight bash %}
  Error: Expected {"an":"example","object":"definition"} to have key 'missing'
{% endhighlight %}

For the second check, we need to make sure the expected property value equals the actual property value.

{% highlight javascript %}
  ...
  else if (expected[key] !== self.actual[key]) {
    throw new Error("Expected '" + self.actual[key] + "' to match '" + expected[key] + "' for '" + key + "'");
  }
  ...
{% endhighlight %}

Again, in keeping with good error messages, an example of the above failure would look like this:

{% highlight bash %}
  Error: Expected 'expectedVal' to match 'actualVal' for 'testProp'
{% endhighlight %}

Putting it all together, we have

{% highlight javascript %}
  beforeEach(function () {
    jasmine.Matchers.prototype.toIncludeValues = function (expected) {
      var self = this;

      Object.keys(expected).forEach(function (key) {
        if (!self.actual.hasOwnProperty(key)) {
          throw new Error("Expected " + JSON.stringify(self.actual) + " to have key '" + key + "'");
        } else if (expected[key] !== self.actual[key]) {
          throw new Error("Expected '" + self.actual[key] + "' to match '" + expected[key] + "' for '" + key + "'");
        }
      });
    };
  });
{% endhighlight %}

## Where's the recursion?

This matcher worked just fine until I needed to test the properties of a nested object. If I had

{% highlight javascript %}
  {
    foo: 'bar',
    baz: 'blah',
    nested: {
      object: true
    }
  }
{% endhighlight %}

the `nested` property would fail validation since object equality is checked by reference, not value. We need to dig down into
the nested object to test each property in that object as well. Wrapping the existing *if-else if* in another *if-else*
conditional, we need to check if the current property being tested is an object or not.

{% highlight javascript %}
  ...
  if (typeof(actual[key]) === 'object') {
    self.toIncludeValues(expected[key]);
  } else {
    if (!actual.hasOwnProperty(key)) {
      throw new Error("Expected " + JSON.stringify(actual) + " to have key '" + key + "'");
    } else if (expected[key] !== actual[key]) {
      throw new Error("Expected '" + actual[key] + "' to match '" + expected[key] + "' for '" + key + "'");
    }
  }
  ...
{% endhighlight %}

Recursively passing the nested object into the matcher again allows the property and value matching to continue in
each level of nested objects. This still isn't quite complete, because in each recursive call of the matcher, `this.actual`
will still be the top level object we're testing against. As we pass in each expected nested object, we'll need to pass in
the actual nested object to test against as well. Our final matcher implementation is

{% highlight javascript %}
  jasmine.Matchers.prototype.toIncludeValues = function (expected, nestedActual) {
    var self = this,
      actual = nestedActual || self.actual;

    Object.keys(expected).forEach(function (key) {
      if (typeof(actual[key]) === 'object') {
        self.toIncludeValues(expected[key], actual[key]);
      } else {
        if (!actual.hasOwnProperty(key)) {
          throw new Error("Expected " + JSON.stringify(actual) + " to have key '" + key + "'");
        } else if (expected[key] !== actual[key]) {
          throw new Error("Expected '" + actual[key] + "' to match '" + expected[key] + "' for '" + key + "'");
        }
      }
    });
  };
{% endhighlight %}

In the first pass of the matcher, the `nestedActual` argument is `undefined` and the `actual` variable is set from
`self.actual`. Each time `toIncludeValues()` is recursively called again, it passes in the `nestedActual` argument,
so the `actual` variable will be set to that instead of the top level `self.actual` object.

## Conclusion

The one thing that really tripped me up getting started was figuring out the correct syntax for a custom matcher in
my particular Jasmine configuration. While searching the interwebs for the setup code, I saw a few different ways of
doing so. If you're having trouble with the syntax I used, keep searching and I'm sure you'll be able to find the proper
custom matcher definition you're looking for. Happy coding!
