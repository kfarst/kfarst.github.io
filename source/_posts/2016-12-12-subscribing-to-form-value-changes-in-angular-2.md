---
layout: post
title: "Subscribing to Form Value Changes in Angular 2"
date: 2016-12-12 20:00:00
comments: true
keywords: ""
categories:
- Angular
tags:
- angular2
---

In Angular 2, promises have been replaced with *observables*, which offer a way to subscribe to changes in an asynchronous
manner, rather than one-off asynchronous actions. An observable broadcasts a stream of information that can be read by any entity
that is listening to the values the observable is outputting.

Included with the many built-in observables in Angular 2 are observables to subscribe to form value changes. You can subscribe
to individual form inputs, or observe the form as a whole to watch for any changes. I recently taught a [class](https://www.codementor.io/classes/learn-beginner-angular2-live)
online for Angular 2, and as a fun exercise I wanted to come up with a practical way to leverage the form value changes
observable (at least for demonstration purposes).

I thought I might share the steps I went through to persist form values in case of an unexpected page reload or browser window
closing. I know there have been times where I accidentally closed a tab or triggered the reload shortcut in my browser, only
to be filled with a split-second rage when I realize the form I had just filled out was completely wiped.

## Getting started

Firstly, I'm only planning on explaining the concepts in Angular 2 forms that are relevant to this example, but please comment
if you have any questions, or you can check out the [forms guide](https://angular.io/docs/ts/latest/guide/forms.html) in
the Angular documentation. Also, if you are somewhat familiar with forms in the framework already, we'll be building a
[model-driven](https://angular.io/docs/ts/latest/cookbook/dynamic-form.html) form, as opposed to a
[template-driven](https://angular.io/docs/ts/latest/guide/forms.html) form.

## Building the form in HTML

We'll be building out a component to allow the user to sign up for a newsletter to be mailed to the address of their choice.
Starting with the HTML template, which we will aptly name *newsletter.component.html*, we have

{% highlight html %}
  <div class="row newsletter">
    <div class="col-md-12">
      <h1>Get our newsletter</h1>

      <form [formGroup]="registerForm" (submit)="destroyFormValues()" novalidate>
        <div class="form-group">
          <label>First name:</label>
          <input type="text" class="form-control" formControlName="firstName">
        </div>

        <div class="form-group">
          <label>Last name:</label>
          <input type="text" class="form-control" formControlName="lastName">
        </div>

        <div class="form-group">
          <label>Email address:</label>
          <input type="email" class="form-control" formControlName="emailAddress">
        </div>

        <fieldset formGroupName="address">
          <div class="form-group">
            <label>Street:</label>
            <input type="text" class="form-control" formControlName="street">
          </div>

          <div class="form-group">
            <label>Zip:</label>
            <input type="text" class="form-control" formControlName="zip">
          </div>

          <div class="form-group">
            <label>City:</label>
            <input type="text" class="form-control" formControlName="city">
          </div>
        </fieldset>

        <button type="submit" class="btn btn-default add-smaller-space-below">Submit</button>
      </form>
    </div>
  </div>
{% endhighlight %}

which gives us

<img src="https://i.imgur.com/UHQfp4l.png" width="100%">

Angular forms are a collection of `FormControl` objects, bound to the HTML through `<input>` tags and the `formControlName`
attribute on those tags. The `FormControl` objects are grouped into, well, a `FormGroup` object. A `FormGroup` is represented
in the HTML as either a `<fieldset>` or a top-level `<form>` tag. A `FormGroup` can be nested inside another `FormGroup` as
we see above, and the top-level `<form>` is bound to the top-level `FormGroup` by the `[formGroup]` attribute, whereas a
nested `<fieldset>` is bound to the nested `FormGroup` with the `formGroupName` attribute.

## Building the form programmatically

If the above explanation is still a little fuzzy, hopefully this next step will help you visualize it better. We need a JavaScript
form object to bind the HTML form to, so let's do that inside our `NewsletterComponent` class.


{% highlight typescript %}
  import { Component, OnInit } from '@angular/core';
  import {
    FormGroup,
    Validators,
    FormBuilder
  } from '@angular/forms';

  @Component({
    selector: 'newsletter',
    templateUrl: './newsletter.component.html'
  })

  export class NewsletterComponent implements OnInit {
    registerForm: FormGroup;

    constructor(private formBuilder: FormBuilder) {}

    ngOnInit() {
      this.registerForm = this.formBuilder.group({
        firstName: ['', [Validators.required, Validators.minLength(8)]],
        lastName: ['', Validators.required],
        emailAddress: ['', Validators.required],
        address: this.formBuilder.group({
          street: ['', Validators.required],
          zip: ['', Validators.required],
          city: ['', Validators.required]
        })
      });
      ...
  }
{% endhighlight %}

Hopefully the code above will help you see why the HTML form is constructed the way it is. We have the top-level `FormGroup`,
the `registerForm` variable, and when the component is initialized we build out the form as a `FormGroup` with nested `FormControl`
values (and a nested `FormGroup` as well). The array values have a default value for the `FormControl` as the first element, and any validation(s) as the
second element. Note that the built-in `FormBuilder` service will initialize the values as a `FormGroup` or `FormControl` respectively,
even though we don't explicitly see the values being defined as new instances of those classes here.

## Subscribing to form value changes

Finally, we're done with the setup and can start building out our mechanism for persisting form values. For the sake of this demo, we'll save
the form values to the browser's built in `sessionStorage`, and remove those values from the storage when the form is submitted by calling
the `destroyFormValues()` function associated with the `(submit)` attribute on the `<form>` tag.

At the bottom of our `ngOnInit()` function we'll add the following:

{%highlight typescript %}
  ngOnInit() {
    ...
    this.
      registerForm.
      valueChanges.
      subscribe(form => {
        sessionStorage.setItem('form', JSON.stringify(form));
      });
  }
{% endhighlight %}

Let's break this down piece by piece. First, we have the `valueChanges` call being made on the `registerForm` object. `valueChanges` is a reference to
the observable we'll subscribe to, which we're doing on the next line. The observable is added by way of the `registerForm` being an instance
of the `FormGroup` class. The value that gets passed in to the `subscribe()` callback, `form`, is simply a JavaScript object.

{% highlight typescript %}
  {
    firstName: "",
    lastName: "",
    emailAddress: "",
    address: {
      city: "",
      state: "",
      zip: ""
    }
  }
{% endhighlight %}

As the form values change, this same object structure will be passed into the subscription with the updated form values. We get the `sessionStorage`
object from the browser, and we associate the form values object to a key in the storage, in this case `'form'`. We'll run into issues trying to save
the object as-is, so we'll `stringify()` the form values object before saving it.

## Retrieving the form values

Once we've started filling out the form, we can verify the values are being stored in the browser's session storage. Great! Now if we reload
the page, we need to pull those values out of the storage and apply them to each of the `FormControl` values. First, let's add a few lines
above our `valuesChanges` subscription in the `ngOnInit()` function.

{% highlight typescript %}
  ngOnInit() {
    ...
    let formValues = sessionStorage.getItem('form');

    if (formValues) {
      this.applyFormValues(this.registerForm, JSON.parse(formValues));
    }
    ...
  }
{% endhighlight %}

All we're doing here is checking if there is a `'form'` key existing within the `sessionStorage`, and if there is, turn the value back into an object
using `JSON.parse()` and pass that object and the `registerForm` object into the function `applyFormValues()`. Now, let's add a new `private` function
to the component called `applyFormValues()`.

{% highlight typescript %}
  private applyFormValues (group, formValues) {
    Object.keys(formValues).forEach(key => {
      let formControl = <FormControl>group.controls[key];

      if (formControl instanceof FormGroup) {
        this.applyFormValues(formControl, formValues[key]);
      } else {
        formControl.setValue(formValues[key]);
      }
    });
  }
{% endhighlight %}

We're iterating over each of the keys in our form values object and fetching its corresponding `FormControl` from the `group` argument, which is our `registerForm`
in this case. From here, we either set the value of the `FormControl` using the `setValue()` function, or check to see if our `FormControl` is actually a `FormGroup`.

`FormGroup` is a subclass of `FormControl`, so if it is indeed an `instanceof FormGroup`, we need to recursively call our `applyFormValues()` function, this time passing in
our nested `FormGroup` (`address`) instead of our top-level `FormGroup` that represents our `registerForm`. Therefore, once our function gets to the `address` key and discovers it's
actually a `FormGroup`, it will pass that nested object into the function again to iterate through each of the `address` object's keys and set the values of `city`, `state`,
and `zip`.

<img src="http://i.imgur.com/P39zVKJ.gif" width="100%">

Looks like our form values survived a page reload! To finishing things up, let's add a quick function to delete the form values from `sessionStorage` once we submit
the form.

{% highlight typescript %}
  destroyFormValues() {
    sessionStorage.removeItem('form');
    alert('Saved form data deleted');
  }
{% endhighlight %}

Now, when we submit the form we'll see an alert informing us the saved form data has been deleted. When the page is reloaded, we can confirm the values have been removed
from `sessionStorage`.

<img src="http://i.imgur.com/tqnkvrg.gif" width="100%">

## Conclusion

Forms in Angular 2 are pretty powerful, and you can do some neat things with them. I hope in this fun exercise you've come to better understand model-driven forms in
the framework, as well as how observables can be leveraged for subscribing to form value changes. Remember, each `FormControl` can be observed, not just the entire
form, so detecting changes in forms can be even more nuanced than what we've shown. Please post any questions or comments, and happy coding!
