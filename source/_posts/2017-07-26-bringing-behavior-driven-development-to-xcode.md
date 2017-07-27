---
layout: post
title: "Bringing Behavior-Driven Development to XCode"
date: 2017-07-26 12:06:25
comments: true
description: "Bringing Behavior-Driven Development to XCode"
keywords: "quick,rspec,ios,swift,testing,tdd,bdd"
categories:
- iOS
tags:
- iOS
---

As a former Ruby on Rails developer, anything I stumble upon that can give me a ride on the nostalgia train with what I’m currently working on
will definitely grab my attention. All joking aside, as I continue to build on my iOS development experience, I couldn't help hearing that nagging
voice in the back of my head that all Rails developers hear: *why aren’t you testing your code?!* As I've been getting more and more comfortable with
common tasks like fetching data from the server with `URLSession`, parsing the JSON response into an `NSObject`-based model class, and displaying
that data in various ways inside a `UIViewController`, I was getting flashbacks of times where, as an app I was working on scaled, it got scarier
and scarier for former co-workers and I to make changes and updates, unsure of what unforeseen functionality or feature we might be breaking
elsewhere due to missing code coverage.

However, I didn't get too far into my career before that quickly changed. Personal experience and being part of a test-centric community quickly
found me (at the very least) writing unit tests to cover the various uses of my classes and methods. I got comfortable with the various steps of
building code coverage like creating test data, how to write tests to handle differing class configurations, and making sure to construct test scenarios
that would cover the multiple logical branching of my methods.

## Rails Unit Testing

Luckily, a Rails app by default generated an integrated test environment, and creating a group of tests is as simple as subclassing the built-in
`ActiveSupport::TestCase` class. It was pretty simple to start building test cases for your classes, and Ruby being the beautiful language that
it is (at least in terms of how closely the syntax can read as plain English, especially compared to a language like Java), it wasn't too hard
for even a novice Rubyist to read a test case and tell what it was doing. However, despite inheriting a clean syntax by way of the language itself,
the way the test cases read still seemed slightly cryptic. Consider this straightforward example:

{% highlight ruby %}
class ArticleTest < ActiveSupport::TestCase
  ...
  test "should not save article without title" do
    article = Article.new
    assert_not article.save, "Saved the article without a title"
  end
  ...
end
{% endhighlight %}

Test cases are evaluated by asserting that some value or method result is either a “truthy” or “falsy” expression, based on how the test data
was being manipulated by the functionality you were testing against. In the scenario above, we are making sure that a new instance of the `Article`
model will fail to be saved if it’s missing a title.

Again, from the context we can tell what's going on, even if you don't really know any Ruby or you're new to unit testing. However, when we
actually break down the syntax, it's still a little clunky. For example, what the heck does `assert_not article.save` actually mean? If I
didn't explain what exactly a unit test does it terms of assertions, it might be pretty confusing for a new developer. Additionally, what if
we start having much more complex testing scenarios? The description portion of the `test “...” do` line may end up becoming very large and
cumbersome to read. You may end up with a description like `new user saves without a name if created by a user with an account creation role`.
Even if a long test description doesn’t bother you, testing similar scenarios may find you duplicating pieces of the description multiple times.

## RSpec to the Rescue

Even before I started weighing the pros and cons of using the built-in testing framework versus something else, I had heard that RSpec was
the go-to unit testing (and even functional testing) framework in Rails. Even though I had a predisposition to using RSpec, I definitely believe
it was a wise piece of advice.

RSpec, though accomplishing the same task as Rails' generic test suite, does things just differently enough
that it can make for a much more enjoyable and readable coding experience. Take for example our original assertion,
`assert_not article.save`. With RSpec, you would handle the same logic using the code snippet `expect(article.save).to be false`
(the `save` method will return `true` when the save was successful, and `false` when it was not). Just a small change
like this can make what's going on much more understandable, as it literally reads almost exactly like an English sentence.
Probably the most important overarching idea though is that as test contexts and scenarios are constructed, they can be
nested and “built up” as a story describing the behavior of the functionality you're testing against. Once you become
comfortable with this idea, you can start to realize how nice this change can really be.

## I Thought this was an Article About Objective-C and Swift?

Right you are, self. I had to remind myself of this as I started to delve deeper into the concepts behind
“behavior-driven development”. Sure I can continue to explain the ins-and-outs of this testing style in RSpec,
but I’d like to start using Swift (and a little bit of Objective-C) code examples as we start migrating our iOS/Cocoa
unit test cases to a behavior-based implementation.

Just to keep things from getting too complex, I think we can cover most of what I wanted to talk about by implementing
a simplified and partial version of the [Set](https://developer.apple.com/documentation/swift/set) data structure built into Swift. 
Since this is much simpler, we'll only cover the `insert` and `remove` functions.

{% highlight swift %}
struct CustomSet<T: Comparable> {
    fileprivate var elements: [T] = [T]()

    mutating func insert(_ element: T) -> T {
        if !elements.contains(element) {
            elements.append(element)
        }
        return element
    }

    mutating func remove(_ element: T) -> T? {
        guard let index = elements.index(of: element) else {
           return nil
        }

        return elements.remove(at: index)
    }
}
{% endhighlight %}

Again, this is a *very* basic, stripped down implementation. Now for testing, we'd create a subclass of `XCTestCase`.

{% highlight swift %}
class CustomSetXCTests: XCTestCase {
    var set: CustomSet<String> = CustomSet<String>()

    func testCustomSet_insert_insertsNonExistingElement() {
        XCTAssertNotNil(set.insert("foo"))
    }

    func testCustomSet_insert_returnsInsertedElement() {
        let insertedValue = set.insert("foo")
        XCTAssertEqual(insertedValue, set.insert("foo"))
    }

    func testCustomSet_remove_returnsNilForNonExistingElement() {
        XCTAssertNil(set.remove("bar"))
    }

    func testCustomSet_remove_returnsRemovedElement() {
        let insertedValue = set.insert("bar")
        XCTAssertTrue(insertedValue == set.remove("bar"))
    }
}
{% endhighlight %}

Some test logic is duplicated, and some assertions are unnecessary, but I wanted to demonstrate a
different assertion for every test case. They definitely get the job done, but just like our `assert_not article.save`
expression in RSpec, it's not very pretty, and maybe even a tiny bit cryptic to a beginner. Additionally, our function
names can start to become very long and convoluted if we want to accuratelyand fully describe our test cases.
Finally, this may be nitpicky, but when you're trying to read a function name to understand what it does, having to
read camel-cased and underscored syntax while at the same time trying to figure out exactly what a test is doing can be a bit of an annoyance.

## Discovering Quick

Naturally, when I stumbled upon [Quick](https://github.com/Quick/Quick), I jumped at the opportunity to be able to write
similar behavior-based unit tests in XCode projects as RSpec offered to Ruby and Rails. If you use [CocoaPods](https://cocoapods.org/),
it can easily be pulled into your project by adding these lines to the test target of your `Podfile`:

{% highlight ruby %}
  pod 'Quick'
  pod 'Nimble'
{% endhighlight %}

[Nimble](https://github.com/Quick/Nimble) comes together with Quick to offer the same `expect(...).to` assertion syntax that
we saw in RSpec. Once we install our pair of CocoaPods, we can create a new test file and get started.

{% highlight swift %}
import Quick
import Nimble
...
class CustomSetQuickTests: QuickSpec {
  override func spec() {
    ...
  }
}
{% endhighlight %}

We need to build our tests inside the `spec()` function. From here, this is where it gets interesting. Like we saw in
Rails unit tests with the `test "..." do` syntax, Quick leverages Swift [closures](https://developer.apple.com/library/content/documentation/Swift/Conceptual/Swift_Programming_Language/Closures.html)
to encapsulate our test functionality (or [blocks](https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/ProgrammingWithObjectiveC/WorkingwithBlocks/WorkingwithBlocks.html) in Objective-C).

{% highlight swift %}
  ...
  override func spec() {
    describe("CustomSet") {
      ...
    }
  }
  ...
}
{% endhighlight %}

Test cases are built up piece by piece by nesting our data setup and assertions within the closures of Quick's domain-specific functions.

#### Describe

Usually with unit tests that cover a single class, it's best to start with a `describe` closure using the class name. Just a quick note,
some of the instruction I'm giving are opinionated best practices pulled from [Better Specs](http://www.betterspecs.org/) originally written
for guidance in RSpec, but can absolutely be applied to Quick as well.

`describe` closures set up *example groups*, which are logical groups of examples. In our top-level case, the logical grouping is the class itself.
From here, we use Quick to describe *how* our public interface should behave. In the context of a single class, that public interface is a series of
functions and properties. Therefore, it would make sense that our nested `describe` closures should cover our instance and class functions for the most part.
From the *Better Specs* site I mentioned above, it suggests that the description be the function name, prefixed with either a `.` for a class function, or
`#` for an instance function. This concept comes from how Ruby documents instance and class methods, and I rather like it, so I do the same in Quick tests.

{% highlight swift %}
...
override func spec() {
  describe("CustomSet") {
    describe("#insert") {
      ...
    }

    describe("#remove") {
      ...
    }
  }
}
...
}
{% endhighlight %}

#### context

`context` closures can be nested within either a `describe` or another `context`. It accomplishes the same goal as a `describe`, and exists
for the purpose of semantic clarity. In fact if you look at the source code for the function inside Quick, it's just a wrapper function calling
the `describe` function:

{% highlight swift %}
  internal func context(_ description: String, flags: FilterFlags, closure: () -> Void) {
      guard currentExampleMetadata == nil else {
          raiseError("'context' cannot be used inside '\(currentPhase)', 'context' may only be used inside 'context' or 'describe'. ")
      }
      self.describe(description, flags: flags, closure: closure)
  }
{% endhighlight %}

I like to use these for setting up variations inside an example group where the same functionality is being tested under different conditions, for example
with different test data. Using it for our `CustomSet` tests might look like this:

{% highlight swift %}
  ...
  override func spec() {
    describe("CustomSet") {
      describe("#insert") {
        context("with a non-existing element") {
        }

        context("with an existing element") {
        }
      }

      describe("#remove") {
        context("with a non-existing element") {
        }

        context("with an existing element") {
        }
      }
    }
  }
  ...
}
{% endhighlight %}

These tests are simple so really a `context` block wouldn't necessarily be needed, but if we had multiple tests per `context` and unique data just for that
`context`, they can really be a powerful tool.

#### beforeEach

In **XCTest** we have a `setUp` function to handle any configuration of test data before a test is run. However, if we need to set up unique test data
for every test, we might find ourselves building helper functions for the sole purpose of creating that data for a single test or group of tests.
We may even find ourselves calling helper functions within helper functions, and that can get messy quickly. Adding a `beforeEach` closure inside a
`describe` or `context` can accomplish the same goal as the `setUp` function, however they can be nested just like `describe` or `context`
closures can. This gives us the ability to

* Inherit setup configuration and data from parent `beforeEach` closures
* Avoid writing helper functions that may need to call other helper functions
* Keep the expressions around our assertions as minimal as possible (more on this in the next section)

{% highlight swift %}
...
  describe("CustomSet") {
    var set: CustomSet<String>

    beforeEach {
      set = CustomSet<String>()
    }

    describe("#insert") {
      context("with a non-existing element") {
      }

      context("with an existing element") {
        beforeEach {
          set!.insert("foo")
        }
      }
    }

    describe("#remove") {
      context("with a non-existing element") {
      }

      context("with an existing element") {
        beforeEach {
          set!.insert("bar")
        }
      }
    }
  }
}
...
{% endhighlight %}

#### it

`it` closures are where the assertions are defined to demonstrate how code should behave. In other words, this is where our tests will "pass" or "fail"
because our `expect(...).to` expressions are declared here. In our final step, let's add our `it` closures with an accurate description and assertion.
You are free to add as many lines of code as you want inside the `it`, however as mentioned in the last bullet point above, if you structure your scenarios
and test data properly, many times you can end up with a one line expectation, like we see for each of our test cases.

{% highlight swift %}
describe("CustomSet") {
    var set: CustomSet<String>?

    beforeEach {
        set = CustomSet<String>()
    }

    describe("#insert") {
        context("with a non-existing element") {
            it("inserts the element") {
                expect(set!.insert("foo")).toNot(beNil())
            }
        }

        context("with an existing element") {
            beforeEach {
                _ = set!.insert("foo")
            }

            it("returns the inserted element") {
                expect(set!.insert("foo")).to(equal("foo"))
            }
        }
    }

    describe("#remove") {
        context("with a non-existing element") {
            it("returns nil") {
                expect(set!.remove("bar")).to(beNil())
            }
        }

        context("with an existing element") {
            var insertedValue: String?

            beforeEach {
                insertedValue = set!.insert("bar")
            }

            it("returns the removed element") {
                expect(set!.remove("bar") == insertedValue).to(beTrue())
            }
        }
    }
}
{% endhighlight %}

Like **XCTest** we still get assertion failure highlighting and messaging.

<img src="http://i.imgur.com/p5L7mFl.png" width="100%">


## Quick in Objective-C

Quick can be used in an Objective-C context (no pun intended) as well. Like I mentioned above, blocks would be substituted
for closures. Also an important note, Swift stdlib will not be linked into your test target unless you have *at least one*
Swift file in your test target.

{% highlight objective-c %}
describe(@"AClass", ^{
    beforeEach(^{
      ...
    });

    describe(@"#aMethod", ^{
        context(@"a context", ^{
          it(@"has an assertion", ^{
            ...
          });
        });
    });
    ...
});
{% endhighlight %}

Unfortunately we can't test against our `CustomSet` struct for a few reasons

* Objective-C doesn't support structs
* Objective-C doesn't support generics, so we would have to remove the `<T: Comparable>` expression and stick
with one type, like `String`
* Once converted to a class, `CustomSet` would also have to subclass an Objective-C type, like `NSObject`

Sorry about that! I guess I leveraged the power of Swift a litle bit too much for this article, but a quick
Google search can help you find further examples of Quick with Objective-C if you're interested in learning more.

## Final Thoughts

Now that we've described the *behavior* of the class, the `describe`, `context`, and `it` descriptions can be
built up to read like full sentences

<blockquote>
CustomSet#insert with a non-existing element inserts the element
CustomSet#insert with an existing element returns the inserted element
CustomSet#remove with a non-existing element returns nothing
CustomSet#remove with an existing element returns the removed element
</blockquote>

Reading these sentences like documentation can be especially helpful to a developer new to the project, or when
a fellow team member encounters a class or functionality for the first time. Quick is also not limited to just unit
tests, it's a way to *structure* tests, not necessarily a DSL for only one type of test. This means you can build your
functional and UI tests using Quick and Nimble, just like we have for unit tests.

## Conclusion

I've barely scratched the surface in terms of the versatility of Quick, and I only covered limited examples of the custom DSL.
You can check out the full documentation [here](https://github.com/Quick/Quick/blob/master/Documentation/en-us/README.md), and
a link to an XCode project with the code referenced in this post [here](https://github.com/kfarst/XCodeTestingExample). I hope
you find delving into behavior-driven development and testing as enjoyable as I have. If you're used to **XCTest**, it may take
some time for you to see the benefit of it, but stick with it, give it an honest shot, and you might be surprised at how much you enjoy
it. Good luck in your testing journey!
