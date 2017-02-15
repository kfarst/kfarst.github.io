---
layout: post
title: "Refactoring a Twitter-style Text Counter in Android"
date: 2017-02-22 8:00:00
comments: true
description: "Refactoring a Twitter-style Text Counter in Android"
keywords: "android"
categories:
- Android
tags:
- android
---

A few weeks ago I posted [this article](http://kfarst.github.io/android/2017/02/04/creating-a-user-input-text-counter-in-android/)
about creating a user input text counter in Android. I got some great feedback on refactoring improvements, and
I ended up changing so much that I felt like it needed its own blog post. I could re-write the original article,
but I thought it important to take this as an opportunity to use the two posts for a lesson in refactoring, and demonstrate
that programming is a career-long improvement process. Additionally, I hope those who want to take a risk and share
some lessons they've learned or some code they've written will see that it's OK to put something out there, even if
you aren't some "programming god" or feel 100% confident in the examples you're giving. It shows you are willing to
give back to the community by sharing your experiences and lessons-learned, and any constructive feedback you
receive can only help to improve yourself and others.

## Anways, I'll get off my soap box...

Now, on to the refactor. Originally I was making updates to the content the user sees and checking validations by way
of data binding. I'm not saying data binding is the "wrong answer" by any means, it's a really powerful tool to keep
in your Android arsenal; however, my code needed two major improvements:

1. I was exposing too much logic inside the view
2. My view components were not very reusable

Taking a look at my original `fragment_compose_tweet.xml` (with only the related properties listed), I had:

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

Sure, you can look at this and pretty much know what's going on from the context, but it doesn't look very clean, and like I mentioned before, not
very reusable. I did most of my refactoring based around two concepts:

1. Extending Android's built-in view classes
2. Using a common interface to handle view updates

## Extending the TextView

First, I started off by creating a custom `TextView` for the text counter by extending the built-in class, which I called `CounterTextView`. Let's take
a look at the XML (with only the relevant attributes).

{% highlight xml %}
  <com.kfarst.apps.whispertweetnothings.support.CounterTextView
      android:id="@+id/counterTextView"
      ...
      attr:validTextColor="@android:color/darker_gray"
      attr:invalidTextColor="@android:color/holo_red_dark" />
{% endhighlight %}

We have two custom attributes for the `CounterTextView`, the `validTextColor` and `invalidTextColor`. The first color will be used when the counter shows
a valid number, in this case greater than -1, and the second color will be shown when the text is invalid, or less than 0. We have to register these attribute
definitions somewhere so Android will recognize them, so I created a `res/values/attrs.xml` file and added it there.

{% highlight xml %}
<resources>
    <declare-styleable name="CounterTextView">
        <attr name="validTextColor" format="integer" />
        <attr name="invalidTextColor" format="integer" />
    </declare-styleable>
</resources>
{% endhighlight %}

Next, taking a look at our custom `TextView` class, we have:

{% highlight java %}
...
public class CounterTextView extends TextView {
    private TypedArray attributes;
    private int mInvalidTextColor;
    private int mValidTextColor;

    public CounterTextView(Context context, AttributeSet attrs) {
        super(context, attrs);

        attributes = context.getTheme().obtainStyledAttributes(
                attrs,
                R.styleable.CounterTextView,
                0, 0);

        try {
            mValidTextColor = attributes.getInt(R.styleable.CounterTextView_validTextColor, android.R.color.darker_gray);
            mInvalidTextColor = attributes.getInt(R.styleable.CounterTextView_invalidTextColor, android.R.color.holo_red_dark);
            this.setTextColor(mValidTextColor);
        } finally {
            attributes.recycle();
        }
    }
}
{% endhighlight %}

In the constructor the attributes are fetched and stored as instance variables. Note that calling `attributes.getInt()` needs a fallback
value as a second argument, so I chose a dark gray for valid and dark red for invalid.

# Extending the Button

I also needed to create a custom `Button` class, called `TweetSubmitButton`. First the XML, where you'll notice we don't really have any
custom attributes.

{% highlight xml %}
  <com.kfarst.apps.whispertweetnothings.support.TweetSubmitButton
      android:textColor="@android:color/white"
      android:text="Tweet"
      ...
      android:id="@+id/btnTweet" />
{% endhighlight %}

Next comes the `SubmitTweetButton` class. Again, I'm only defining a bare bones class with the necessary default constructors.

{% highlight java %}
  ...
  public class TweetSubmitButton extends Button implements OnCountChangedListener {

      public TweetSubmitButton(Context context) {
          super(context);
      }

      public TweetSubmitButton(Context context, AttributeSet attrs) {
          super(context, attrs);
      }

      public TweetSubmitButton(Context context, AttributeSet attrs, int defStyleAttr) {
          super(context, attrs, defStyleAttr);
      }
  }
{% endhighlight %}

You're probably wonder what the point of overriding the default `Button` class was in this case, and here's why...

## Defining an interface

Since we aren't using data binding anymore, we need a way to tell both the `CounterTextView` and the `TweetSubmitButton` when to update.
The `TextView` needs to know when and what value to update its text and text color, and the `Button` needs to know when to appear faded
to indicate it's disabled, as well as actually disabling the button. We also need a common and re-usable way to interact with these classes,
so we'll do so with an interface. It's very simple, containing one method `countChanged()` that takes in the current text count and a flag indicating
whether we've reached the limit of the text or not.

{% highlight java %}
  public interface OnCountChangedListener {
      void countChanged(int currentCount, boolean hasReachedTheEnd);
  }
{% endhighlight %}

Now, updating the view classes we have:

*CounterTextView.java*
{% highlight java %}
  public class CounterTextView extends TextView implements OnCountChangedListener {
      @Override
      public void countChanged(int currentCount, boolean hasReachedTheEnd) {
          this.setText(""+currentCount);
          this.setTextColor(hasReachedTheEnd ? mInvalidTextColor : mValidTextColor);
      }
      ...
  }
{% endhighlight %}

*SubmitTweetButton.java*
{% highlight java %}
public class TweetSubmitButton extends Button implements OnCountChangedListener {
    @Override
    public void countChanged(int currentCount, boolean hasReachedTheEnd) {
        this.setClickable(!hasReachedTheEnd);
        this.setAlpha(hasReachedTheEnd ? 0.5f : 1.0f);
    }
    ...
}
{% endhighlight %}

On a side note, we can also remove the data bound attributes on the `EditText` widget where the user enters their status.

{% highlight xml %}
  <EditText
    android:hint="What's happening?"
    ...
    android:id="@+id/etTweet" />
{% endhighlight %}


## Updating the view model

One thing I kept around and simply refactored was my `TweetViewModel`. I used this class to bind the view components with
[Butter Knife](http://jakewharton.github.io/butterknife/), then observe changes to the `EditText` where the user is typing out their tweet and
subsequently call the interface-defined methods on both the `CounterTextView` and the `SubmitTweetButton`.

{% highlight java %}
  public class TweetViewModel extends BaseObservable {
      @BindView(R.id.counterTextView)
      CounterTextView counterTextView;
      @BindView(R.id.etTweet)
      EditText tweetBody;
      @BindView(R.id.btnTweet)
      TweetSubmitButton tweetSubmitButton;

      private static Integer TOTAL_TWEET_LENGTH = 140;
      private Tweet tweet;

      public TweetViewModel(View view, Tweet tweet) {
          ButterKnife.bind(this, view);

          this.tweet = tweet;

          tweetBody.addTextChangedListener(new TextWatcher() {
              @Override
              public void beforeTextChanged(CharSequence charSequence, int i, int i1, int i2) {
                 // Not used, must define
              }

              @Override
              public void onTextChanged(CharSequence charSequence, int i, int i1, int i2) {
                 // Not used, must define
              }

              @Override
              public void afterTextChanged(Editable editable) {
                  updateFromStatus(editable.toString());
              }
          });

          tweetBody.setText(tweet.getStatus());
      }

      private void updateFromStatus(String status) {
          counterTextView.countChanged(TOTAL_TWEET_LENGTH - status.length(),
                  TOTAL_TWEET_LENGTH < status.length());

          tweetSubmitButton.countChanged(TOTAL_TWEET_LENGTH - status.length(),
                  TOTAL_TWEET_LENGTH < status.length() || status.length() == 0);

          tweet.setStatus(status);
      }
  }
{% endhighlight %}

Full disclosure, I cheated a little bit in the logic for the `tweetSubmitButton.countChanged()` method. Though the flag is named `hasReachedTheEnd`,
we also need to disable the button if no text has been entered yet, so we cover both cases in the second argument. Also, you probably notice in
the constructor after I set up the `TextWatcher` on the `tweetBody` I explicitly set the text of the widget to the current status of the
`Tweet` object that was passed in. This is done for two reasons:

1. It sets the initial text value for the *CounterTextView*
2. If the tweet currently being composed is in reply to another tweet, clicking the reply button will automatically add the Twitter handle 
of the account the user is responding to. If that's the case, when the *ComposeTweetFragment* is rendering for the user to reply to the tweet, 
part of the text will already be used up, so we need to immediately update the *CounterTextView* with the updated remaining character count

In the `ComposeTweetFragment` class we see the `respondingTweet` being passed in and the user handle being extracted before passing the
new `tweet` object into the `TweetViewModel`.

{% highlight java %}
    ...
    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
        ...
        if (getArguments() != null) {
            respondingTweet = Parcels.unwrap(getArguments().getParcelable(ARG_RESPONDING_TWEET));

            // If responding to a tweet, prepend it with the user's handle who the user is replying to
            if (respondingTweet != null) {
                String replyHandle = "@" + respondingTweet.getUser().getScreenName() + " ";
                tweet.setStatus(replyHandle);
            }
        }

        tweetViewModel = new TweetViewModel(view, tweet);

        return view;
    }
{% endhighlight %}

Finally, we can see this functionality in action below.

<img src="http://i.imgur.com/7aeGq0h.gif" width="50%">

## Conclusion

Thanks for taking the time to follow me on this refactoring journey. It was pretty fascinating how a few comments on my previous article
ended up having such a large impact on how I structured my code. Though it's still not perfect I'm sure, I hope you've learned a little bit,
as I know I've learned quite a bit. So you don't have to go back to the original article and find the link, here's the [source code](https://github.com/kfarst/whispertweetnothings/tree/v_2_0)
for the original data binding method as well as the refactor we just walked through. Questions and comments are always welcome, though I prefer
constructive criticism over "This article sucks!". Sorry, bad joke. Anyways, good luck and happy coding!
