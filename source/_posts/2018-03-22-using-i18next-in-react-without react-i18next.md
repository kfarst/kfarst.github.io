---
layout: post
title: "10 Minutes of Code: Using i18next in React without react-i18next"
date: 2018-03-22 11:54:10
comments: true
description: "10 Minutes of Code: Using i18next in React without react-i18next"
keywords: "i18n,internationalization,i18next,react,react-i18next"
categories:
- 10-mins-of-code
tags:
- 10-mins-of-code
---

I've been doing some work with internationalization and localization (mostly language translation) which
I first addressed [here](/10-mins-of-code/2018/03/07/fetching-translations-for-unit-testing-react-components/).
In my continuing work with using the *react-i18next* package, I ran into a few places where it wasn't very easy
to use the package's `<I18n />` component. This *I18n* component is significant because, as seen in the article
from the link, it prevents the raw translation strings from being rendered until the translations themselves have been loaded.

{% highlight javascript %}
<I18n>
{
  t => (
    <span>{ t('foo.bar.baz') }</span>
  )
}
</I18n>
{% endhighlight %}

Now, for the majority of cases components can be refactored in such a way that the above implementation can be achieved. However,
there were a few cases as I was going through and adding translations in which I couldn't cleanly use the `<I18n />` component provided
through *react-i18next*.

One such case was a utility function used in multiple places in the app. In a very simplified example, this function would either return
a formatted date/time or "Today" based on the current timestamp.

{% highlight javascript %}
  formattedDateTime(date, today) {
    if (date.isSame(today)) {
      return 'Today';
    } else {
      date.format('YYY-MM-DD');
    }
  }
{% endhighlight %}

Again, just watered down pseudo-code, but you get the point. Now imagine the logic being much more complicated and used in multiple places, and you'll see
why trying to get this called and translated correctly within the *I18n* component will start to get very difficult. I ended up having to fall back to the underlying
JavaScript-only implementation of *i18next*.

{% highlight javascript %}
  import i18n from './MyI18nConfig';
  ...
  formattedDateTime(date, today) {
    if (date.isSame(today)) {
      return i18n.t('date.today');
    } else {
      date.format('YYY-MM-DD');
    }
  }
{% endhighlight %}

This is pretty much all that needs to be done, since the `<I18n />` component basically calls this exact function and configuration "under the covers". Due to the asynchornous
nature of loading the translation strings though (at least in my case since I'm using an XHR plugin to fetch the JSON files), if the `i18n.t('date.today')` statement was executed
before the translations loaded, the string would be interpolated by React as "date.today" and be stuck that way, even after the translations loaded.

After doing a little digging, I turned to [Higher-Order Components](https://reactjs.org/docs/higher-order-components.html) to solve my problem. From the link,

<blockquote>
A higher-order component (HOC) is a function that takes a component and returns a new component
</blockquote>

That is essentially what the `<I18n />` component was doing as well, except that component was taking its [children](https://reactjs.org/docs/react-api.html#reactchildren) (already conveniently wrapped as a function) and passing the translation function into it once the
translations had loaded. This works for most cases until you either want to share logic that provides translated strings, or the translations are nested in such a way that it would be too much of a pain or too messy to pass the
`t()` function through a series of other functions once it becomes available.

Luckily the underlying *i18next* package offers a [callback](https://www.i18next.com/api.html#onloaded) when the translations are loaded. That way we can wrap any any component that uses the `i18n.t()` function without the
`<I18n />` component and hide it until the translations are loaded, thus mimicking the `<I18n />` component while
giving a more generic and flexible use-case.

{% highlight javascript %}
import React from 'react';
import i18n from '../../I18n';

type I18nComponentStateType = {
  i18nInitialized: boolean // flag triggered when translations loaded
};

export default function I18nComponent(
  WrappedComponent: React.Element<*>
): React.ComponentType<*> {

  // eslint-disable-next-line react/display-name
  return class extends React.Component {
    state: I18nComponentStateType;

    constructor(props: Object) {
      super(props);

      // setting initial state
      this.state = {
        i18nInitialized: false
      };

      i18n.on('loaded', () => {
        // update state after translations load, triggering a re-render
        this.setState({ i18nInitialized: true });
      });
    }

    render(): React.Element<*> {
      const {
        i18nInitialized
      } = this.state;

      // hide the wrapped component until translations loaded
      return i18nInitialized
        ? <WrappedComponent />
        : null;
    }
  };
}
{% endhighlight %}

Now when the component is exported, just wrap it in this HOC function and the wrapped component will re-render
when the translations are loaded!

{% highlight javascript %}
import I18nComponent from '../I18nComponent';
...
class MyComponent extends React.Component {
...
}
...
export default I18nComponent(MyComponent);
{% endhighlight %}