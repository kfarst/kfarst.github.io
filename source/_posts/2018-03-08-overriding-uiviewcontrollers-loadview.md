---
layout: post
title: "10 Minutes of Code: Overriding UIViewController's loadView"
date: 2018-03-08 11:27:54
comments: true
description: "10 Minutes of Code: Overriding UIViewController's loadView in Objective-C"
keywords: "swift,objective-c,ios,uiviewcontroller,10minsofcode,10minutesofcode"
categories:
- 10-mins-of-code
tags:
- 10-mins-of-code
---

I've really been focusing on building programmatic views lately, and one way of avoiding the
[Massive View Controller problem](http://khanlou.com/2015/12/massive-view-controller/) is
by creating a subclass of `UIView` and overriding the mechanism in which a `UIViewController`
loads its view. In this way the subviews and constraints setup can be extracted out of the `UIViewController`.
By overriding the `loadView` view controller lifecycle hook, you can initialize the view with a custom
subclass.

The Apple documentation does say you [shouldn't do this](https://developer.apple.com/documentation/uikit/uiviewcontroller/1621454-loadview)
unless you are implementing a view manually, which is exactly what I'm doing. However, accomplishing this may not be that intiutive,
so I'd like to demonstrate exactly how to do this.

### Defining the hook

Keep in mind in Swift, since you are overriding a method in the parent class, you'll need to prefix the hook with the `override` keyword.

{% highlight swift %}
override func loadView() {
  ...
}
{% endhighlight %}

And in Objective-C we simply have:

{% highlight objective-c %}
- (void)loadView {
  ...
}
{% endhighlight %}

### Initialize and Assign the View

You'll need to provide the `frame` for your custom view, which we can grab from the `UIScreen.main` bounds.

In Swift, you'll notice that I used a [lazy property](http://mikebuss.com/2014/06/22/lazy-initialization-swift/) to create my view
before assigning it in `loadView`. This is because when interacting with the view after this, you'll need to reference the `myCustomView`
instance to avoid typecasting the `view` property every time you call it.

{% highlight swift %}
override func loadView() {
  view = myCustomView
}
...
lazy private(set) myCustomView: MyCustomView = {
  return MyCustomView(frame: UIScreen.main.bounds)
}()
{% endhighlight %}


In Objective-C, you can accomplish the same thing by creating a property to override the parent `view` property. This will typecast
the `view` property itself, so you can call it with `self.view` everywhere else you need to.

{% highlight objective-c %}
@interface MyCustomViewController ()

@property (nonatomic, strong) MyCustomView *view;

@end

@implementation ZZACalendarEntryPickerViewController
...
- (void)loadView {
   self.view = [[MyCustomView alloc] initWithFrame: [UIScreen main].bounds];
}
...
@end
{% endhighlight %}


### Dynamically Initializing the View

One final thing to note, in Objective-C you'll see a warning on the `view` property declaration.

<blockquote>
Auto property synthesis will not synthesize property 'view'; it will be implemented by its superclass, use @dynamic to acknowledge intention
</blockquote>

Make sure inside your `@implementation` to add `@dynamic view;` to silence this warning.

Thanks for reading, I hope this was useful!
