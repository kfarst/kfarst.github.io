---
layout: post
title: "Dead Simple Dependency Injection in Angular 2"
date: 2016-12-26 13:00:00
comments: true
description: ""
keywords: ""
categories:
- Angular
tags:
- angular2
---

Dependency injection in Angular 2 can quickly get confusing if you're trying to really understand what's going on "under the hood".
Even researching it myself, I'll be the first to admit I don't have the entire picture clearly mapped out, but I wanted to share what I've learned about
dependency injection in Angular 2 in hopes that it will help you understand a little better yourself.

The entire concept of dependency injection in the framework consists of three things.

- **Injector** - The injector object that exposes APIs to us to create instances of dependencies.
- **Provider** - A provider is like a recipe that tells the injector how to create an instance of a dependency. A provider takes a token and maps that to a factory function that creates an object.
- **Dependency** - A dependency is the type of which an object should be created.

<img src="http://blog.thoughtram.io/images/di-in-angular2-5.svg" width="100%">

## Errr, what?

The above might be a confusing on the surface, but it may be a little easier to represent in code.

{% highlight typescript %}
  import { Injector } from '@angular/core';
  import { MyService } from './my_service';

  export class MyClass {
    myService: MyService;

    constructor (injector: Injector) {
      this.myService = this.injector.get(MyService);
    }
  }
{% endhighlight %}

In the scenario above, `this.myService` is the **dependency**, the **injector** instance is imported and passed into the constructor,
which we access with `this.injector`, and the `MyService` class is the **provider**. Angular usually does this for us (we'll get to that
in just a minute), but writing it this way can better explain the diagram and dependency injection description above.

The dependency is passed in (usually) as a singleton instance, and, if this is the first time the dependency is being fetched by the injector,
it will instantiate that singleton. Otherwise, it will fetch the the existing object.

## What Angular does

Normally, you'll declare providers in an `NgModule` like so:

{% highlight typescript %}

  @NgModule({
    ...
    providers: [MyProvider],
    ...
  })
{% endhighlight %}

The token used inside the array, `MyProvider` is actually an alias for

{% highlight typescript %}
  providers: [{ provide: MyProvider, useClass: MyProvider }]
{% endhighlight %}

They key `useClass` makes it seem like you can give different objects for a provider right? Well, that's exactly right!
Here are some other keys you can use:

### useExisting

This would be used for aliasing one provider to another. An example from the Angular docs uses a hypothetical scenario in which
an interface, `OldLogger`, cannot be deleted, but when it's used we actually want it to call `NewLogger` instead. As long as the
two providers have the same interface, the new provider will be called when the old one is called, hence delegating responsibility
to the new provider.

{% highlight typescript %}
  providers: [NewLogger, { provide: OldLogger, useExisting: NewLogger}]
{% endhighlight %}

### useValue

If you want to use a function, string, etc. as a provider, you can do that with this key. A really good use case I've seen for this
is passing around an API key. In your `AppModule` you could create a provider using the `useValue` key.

{% highlight typescript %}
  providers: [{
    provide: 'apiKey',
    useValue: 'a07e22bc18f5cb106bfe4cc1f83ad8ed'
  }]
{% endhighlight %}

Then, to inject the key into a service, you can do the following.

{% highlight typescript %}
import { Inject, Injectable } from '@angular/core';
import { Http } from '@angular/http';

@Injectable()
export class MyApiService {
  apiKey: string;

  constructor(private http: Http, @Inject('apiKey') apiKey) {
    this.apiKey = apiKey;
  }
  ...
}
{% endhighlight %}

### useFactory

If we need to create the provider value dynamically at the last possible second for whatever reason,
we can use a factory provider to do so.

{% highlight typescript %}
  let heroServiceFactory = (logger: Logger, userService: UserService) => {
    return new HeroService(logger, userService.user.isAuthorized);
  };
{% endhighlight %}

In the example above, we're declaring the factory as a function and passing in the dependencies. Because of this,
we need to also pass the dependencies into the provider declaration.

{% highlight typescript %}
  providers: [{ provide: HeroService,
    useFactory: heroServiceFactory,
    deps: [Logger, UserService]
  }]
{% endhighlight %}

## Conclusion

I hope this has helped in your understanding of dependency injection in Angular 2. You can find most of this (and more)
in the [Angular documentation](https://angular.io/docs/ts/latest/guide/dependency-injection.html), and do let me know
if you have any questions or comments. Happy coding!
