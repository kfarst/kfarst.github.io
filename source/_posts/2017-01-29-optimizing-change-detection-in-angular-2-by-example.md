---
layout: post
title: "Optimizing Change Detection in Angular 2 By Example"
date: 2017-01-29 13:18:52
comments: true
description: ""
keywords: ""
categories:
- Angular
tags:
- angular2
---

One of the things Angular boasts about is the ability to have automatic change detection by default,
meaning that when an object or object property is changed at runtime, the change will be reflected in the
view without having to explicity set up any manual mechanism for doing so. In version 2, Angular has attempted
to empower the developer with more control over how and when to check for changes. I demonstrated this in an
example from a class I taught online, which I would like to share to hopefully give more of a concrete
understanding of this idea.

## Change detection in Angular 1

First, let's see how Angular 1 accomplished the same thing. For each expression in the app, a watcher would
be assigned to it when registered on the `$scope`, then each time a change occured Angular would run through the
list of *every* watcher making sure the value returned from the expression had not changed. This was described
as a *digest cycle* and for each change found in the list, another digest cycle would run until a successful
pass through the list yielded no changes. This approach had a couple of downside however, particiulary

<ul>
  <li>If an expression always had a changing value each digest cycle, for example, if you were accidentally
  creating a new object each time the expression was evaluated, you would eventually receive this all too familiar
  error:

  <strong>
    <pre>
      10 $digest() iterations reached. Aborting!
    </pre>
  </strong>

  Angular would throw an error after 10 digest cycles to prevent an infinite loop.
  </li>
  <li>More pertient to this post, there was no guaranteed order to which the watchers would run, so you could potentially
  run into a situation where change detection in a child direcive/component would be evaulated *before* its parent,
  leading to some weird results. In a visual tree structure, change detection may very well end up traversing
  each node like so:
  <img src="http://i.imgur.com/PgCQycv.png" width="100%">
  </li>
</ul>

## Happy Trees

<img src="http://glasstire.com/wp-content/uploads/2015/10/BobRoss1.jpg?bdc2e0" width="100%">

Since Angular 2, apps are by definition built with a nested tree structue, starting with the root component. Therefore,
no more potiential for the "chicken or egg" dilemma in terms of change detection between parent/child components.
Angular 2 change detection uses a directional tree graph, which basically means changes are guaranteed to propogate
unidirectionally, and will always traverse each component instance once starting from the root.

<img src="https://i.imgur.com/6giapZA.png" width="100%">

## Sounds great, what's the issue?

The directed tree graph makes things much faster, and this built-in behavior will usually be the only thing you'll need
in your Angular 2 app. However, since the focus of this post is optimization, what happens when a node (nested component)
further down the tree registers a change?

<img src="http://i.imgur.com/r26Z31H.png" width="100%">

As mentioned above, Angular will always traverse each component instance once starting from the root. Additionally,
since JavaScript does not have object immutability, Angular must be conservative and check that each component
instance hasn't changed since change detection was last run.

<img src="https://i.imgur.com/Fs2GVDB.png" width="100%">

What if we want to only run change detection under certain circumstances. There's actually a couple ways to do this,
but we'll cover the most basic version below.

## Learning by example

Let's take a look at a small sample app that lists movies of different categories (New, Upcoming, Top Rated, etc).
The `MovieDetailsComponent` takes an `@Input()` object representing the `movie` to list details for.

{% highlight typescript %}
import {
  Component,
  Input,
  ...
} from '@angular/core';

@Component({
  selector: 'movie-details',
  ...
})
export class MovieDetailsComponent {
  @Input('movie') movieData: Movie;
  ...
}
{% endhighlight %}

{% highlight html %}
<movie-details
  [movie]="movie"
  *ngFor="let movie of movies">
</movie-details>
{% endhighlight %}

The `Movie` type is an interface with movie detail-related properties, as well as a flag labeled `markedToSee`.

{% highlight typescript %}
export interface Movie {
  id: number;
  title: string;
  release_date: string;
  overview: string;
  ...
  markedToSee: boolean;
}
{% endhighlight %}

Let's alias the `movie` object to the variable `movieData` inside the `MovieDetailsComponent`
so we can "hook into" the `movie` object being called and insert a statement to log to the console.
ES6 allows us to use the <a href="https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Functions/get">get</a>
syntax to "bind an object property to a function that will be called when that property is looked up".

{% highlight typescript %}
import {
  Component,
  Input,
  ...
} from '@angular/core';

@Component({
  selector: 'movie-details',
  ...
})
export class MovieDetailsComponent {
  @Input('movie') movieData: Movie;

  get movie() {
    console.log(`GET movie: ${this.movieData.title}`);
    return this.movieData;
  }
  ...
}
{% endhighlight %}

In our list of movies, we have a link at the top that, when clicked, will randomly select
a movie for us to see, which it will mark with some text and a background highlight color. Also,
we can see the change detection being triggered on *every* `MovieDetailsComponent` instance
when the `markToSee` flag is flipped on only one movie.

The event function tied to this action looks like this:

{% highlight typescript %}
  // In parent component
  pickMovie(event: any) {
    event.preventDefault();
    let movie: Movie = this.movies.find(movie => movie.markedToSee);
    // If a movie was already marked to see, set the flag back to false
    if (movie) {
      movie.markedToSee = false;
    }
    // Mark a random movie to see, mark the flag as true
    this.movies[Math.floor(Math.random() * this.movies.length)].markedToSee = true;
  }
{% endhighlight %}

And testing it out in the browser...

<img src="https://i.imgur.com/LbvGLbe.gif" width="100%">

We see that both times we clicked **Pick random movie to see** it called the getter function
for the `movie` object of *every* `MovieDetailsComponent`. It also calls the getter multiple times
for each property binding in the view (title, overview, etc), but that's just a side note. Ideally,
we only want to see the getter function called again on one or two of the components
(one if it's the first time we're picking a movie to see, two if we've clicked it again and
the `markedToSee` flag will be flipped off for the old movie and flipped on for the new movie).

## Taking change detection into our own hands (sort of)

We can tell Angular to be more aggressive about deciding when to use change detection by changing
the <a href="https://angular.io/docs/ts/latest/api/core/index/ChangeDetectionStrategy-enum.html">ChangeDetectionStrategy</a>.
We are using the default value right now which will always check for updates on a componennt, but if we
explicitly mark it as `OnPush` it will only run change detection if

<ul>
  <li>The reference to an `@Input()` object is changed</li>
  <li>An event is triggered internally within the component</li>
</ul>

{% highlight typescript %}
import {
  Component,
  Input,
  ChangeDetectionStrategy,
  ...
} from '@angular/core';

@Component({
  selector: 'movie-details',
  changeDetection: ChangeDetectionStrategy.OnPush,
  ...
})
{% endhighlight %}

## IT BROKED!!!!1!!1!

<img src="https://i.imgur.com/Wm798FO.gif" width="100%">

Sure enough, if you go check in the browser again, you'll see that clicking the link to pick a random movie
no longer chooses a movie for us, and we don't see the logger statements in the console either as another
verification. `markedToSee` is a property on the `movie` object, and the `movie` object is an `@Input()`
property, so the object "changed" right?

Well, yes and no. The object itself changed but the *reference* to the object didn't change, it's still the same
object. As mentioned above, change detection will only occur if the object reference changes. How do we tweak
this so we get the results we want?

An easy way is looking at the `markedToSee` property itself. This logic doesn't really belong on the `Movie` type
as it relates to view logic and user-specific logic, so what if we moved it out into a separate `@Input()` property
on the `MovieDetailsComponent` since it's the parent component's responsibility for updating that flag anyways.

First the component...


{% highlight typescript %}
  ...
  export class MovieDetailsComponent {
    @Input('movie') movieData: Movie;
    @Input() markedToSee: boolean;
    ...
  }
{% endhighlight %}

Then the HTML tag...

{% highlight typescript %}
  <movie-details
    [movie]="movie"
    [markedToSee]="index === selectedMovieIndex"
    *ngFor="let movie of movies; let index = index">
  </movie-details>
{% endhighlight %}

And finally the function for updating the `markedToSee` movie...

{% highlight typescript %}
// In parent component
...
export class MoviesComponent {
  selectedMovieIndex: number;

  pickMovie(event: any) {
    event.preventDefault();
    this.selectedMovieIndex = Math.floor(Math.random() * this.movies.length);
  }
}
{% endhighlight %}

## Success!

<img src="https://i.imgur.com/UiVaHzA.gif" width="100%">

We see that the first time the link is clicked, only one component instance is triggered for update. Then, on
each subsequent click of the link, we see change detection triggered for the previously selected movie, as well
as the newly selected movie, greatly reducing the number of check that are needed for a relatively simple change.

Also, if our `MovieDetailsComponent` had nested components within it as child components, we could hypothetically
skip entire subtrees while doing change detection by using `ChangeDetectionStrategy.OnPush`.

<img src="http://i.imgur.com/y3mafMD.png" width="100%">

## Further reading

Finally, as I mentioned previously, there are a few ways to take more control over Angular's change detection, and
we covered one of them. For greater control over the individual change detection mechanism of a component instance,
check out the documentation for <a href="https://angular.io/docs/ts/latest/api/core/index/ChangeDetectorRef-class.html">ChangeDetectorRef</a>.

## Conclusion

Angular 2 and above gives us greater control over change detection than we've ever had with the Angular ecosystem,
a major boost from simply running through a huge list of watchers every time a change is made. Though the default
mechanism is already fast, we can further tune our change detection engine when and where it's needed. The example
I used leaves out a lot of code for the purposes of this article, but you can find the full source code as part of
an online Angular 2 class I taught <a href="https://github.com/kfarst/ng2-intro-movie-app/tree/week4">here</a>. Happy coding!
