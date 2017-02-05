---
layout: post
title: "Creating a User Input Text Counter in Android"
date: 2017-02-05 00:02:12
comments: true
description: "Creating a User Input Text Counter in Android"
keywords: "android"
categories:
- Android
tags:
- android
---

A little while back I attended an [Android bootcamp](http://codepath.com/) in which we built a handful of apps
as we learned. One of the apps we were tasked with building was a [Twitter](http://twitter.com) app, and one of
the features I wanted to build was the almost iconic character counter for tweet composition, as they are of course limited
to 140 characters. As you type each character, the gray text counts down to zero before turning red and continuing
to count back up in the negative range.

Additionally, since the Twitter API will reject any tweet posted over 140 characters, we need to disable the button
next to the counter to prevent the tweet from attempting to be posted.

<img src="http://i.imgur.com/pm2MYbP.gif" width="50%">

## Getting started

We'll be using data binding, so in our `build.gradle` for our `app` module we'll need to enable it.

{% highlight java %}
  android {
      ...
      dataBinding.enabled = true
      ...
  }
{% endhighlight %}

In the layout file for the fragment, we need to expose a variable to tie logic from the fragment's class to values
inside the layout. Data-binding layout files need to be wrapped in a `layout` tag, followed by a list of `variable` tags
within an opening and closing `data` tag. The `variable` tag we'll add is what Android will use to tie a property in
our `ComposeTweetFragment` to the `fragment_compose_tweet.xml` layout.

{% highlight xml %}
  <?xml version="1.0" encoding="utf-8"?>
  <layout xmlns:android="http://schemas.android.com/apk/res/android"
      xmlns:tools="http://schemas.android.com/tools">

      <data>
          <variable name="tweetViewModel" type="com.kfarst.apps.whispertweetnothings.models.TweetViewModel"/>
      </data>
      ...
  </layout>
{% endhighlight %}

We'll come back to the `TweetViewModel` explanation shortly. Back to our `ComposeTweetFragment` class, we need to add a variable
called `tweetViewModel` to tie our layout-declared variable to the fragment's class. From the documentation,

<blockquote>
By default, a Binding class will be generated based on the name of the layout file, converting it to Pascal case and suffixing "Binding" to it.
</blockquote>

Therefore the variable we'll declare will be of type `FragmentComposeTweetBinding`.

{% highlight java %}
...
public class ComposeTweetFragment extends DialogFragment {
    ...
    private FragmentComposeTweetBinding binding;
    ...
}
{% endhighlight %}

In the `onCreate` method, we inflate the view, assign the binding to our private variable, and set the value of our layout-defined
`tweetViewModel` variable.

{% highlight java %}
  ...
  @Override
  public View onCreateView(LayoutInflater inflater, ViewGroup container,
                           Bundle savedInstanceState) {
      // Inflate the layout for this fragment
      View view = inflater.inflate(R.layout.fragment_compose_tweet, container, false);
      binding = FragmentComposeTweetBinding.bind(view);

      // Bind view model for observing the number of tweet characters
      binding.setTweetViewModel(new TweetViewModel(tweet));
      ...
  }
  ...
{% endhighlight %}

The `tweet` variable comes from a value passed into the fragment class.

## Where did the TweetViewModel come from?

Returning to the `TweetViewModel` class, let's look at part of the definition, as this is a class we're declaring ourselves.

{% highlight java %}
  ...
  public class TweetViewModel {
      private static Integer TOTAL_TWEET_LENGTH = 140;
      private Tweet tweet;
      public ObservableField<Integer> charactersRemaining = new ObservableField<>(TOTAL_TWEET_LENGTH);
      ...
  }
{% endhighlight %}

The notable item to point out here is the `ObservableField` property, which provides a way in which data bound UI can be notified of changes.
The character count changes dynamically based off of user input, so it needs to know when to update. We also need to add a `TextWatcher` to
the class to watch the `EditText` field as the user types.

{% highlight java %}
  ...
  public TextWatcher watcher = new TextWatcher() {
      @Override
      public void afterTextChanged(Editable editable) {
          tweet.setStatus(editable.toString());
          charactersRemaining.set(TOTAL_TWEET_LENGTH - editable.toString().length());
      }
  };
  ...
{% endhighlight %}

Finally, in our `fragment_compose_tweet.xml` layout file (and only showing the properties related to the functionality we're building), we have:

{% highlight xml %}
        <EditText
            android:hint="What's happening?"
            android:text="@{tweetViewModel.tweet.status}"
            android:addTextChangedListener="@{tweetViewModel.watcher}"
            android:id="@+id/etTweet" />

        <TextView
            android:text='@{""+tweetViewModel.charactersRemaining}'
            android:textColor="@{tweetViewModel.charactersRemaining > -1 ? @android:color/darker_gray : @android:color/holo_red_dark}" />

        <Button
            android:text="Tweet"
            android:id="@+id/btnTweet"
            android:alpha="@{tweetViewModel.charactersRemaining == 140 || tweetViewModel.charactersRemaining &lt; 0 ? 0.5f : 1.0f}"
            android:clickable="@{tweetViewModel.charactersRemaining &lt; 140 &amp;&amp; tweetViewModel.charactersRemaining > -1 ? true : false}" />
{% endhighlight %}

We use the `@{}` syntax for interpolating our data-bound expressions, which by element type are

#### EditText

* *text* - The actual tweet body.
* *addTextChangedListener* - The text watcher that determines when to update the character count.

#### TextView

* *text* - The dynamic count of the number of characters remaining (the `""+` casts the `Integer` to type `String`).
* *textColor* - If the number of characters remaining is between 0 and 140, the text color will be gray, otherwise a negative count will turn the text red.

#### Button

* *alpha* - Show a partially faded button indicating that it is disabled if the user hasn't started typing a tweet yet, or if they type more than 140 characters. The `<` needs to be escaped.
* *clickable* - Allow the button to be clicked if the user has typed at least one character and not more than 140. The `<` and `&&` need to be escaped.

## Conclusion

Both data binding and observables are very powerful concepts in Android, and I encourage you to explore the vast array of ways they can be utilized in your
apps. The [official documentation](https://developer.android.com/develop/index.html) is the best place to start, and they are plenty of other tutorials
easily found on the Googles. I've only shown the bare minimum code for explanation of the topic at hand, but if you would like to go through the tutorial
again with the full source, you can find it on my GitHub account [here](https://github.com/kfarst/whispertweetnothings). If you have any questions, or
suggestions for a better way to structure the code above, please don't hesistate to comment. Good luck and thanks for reading!
