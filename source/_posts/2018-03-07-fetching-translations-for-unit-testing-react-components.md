---
layout: post
title: "10 Minutes of Code: Fetching Translations For Unit Testing React Components"
date: 2018-03-07 18:26:07
comments: true
description: "5 Minutes of Code: Fetching Translations For Unit Testing React Components"
keywords: "react,i18n,internationalization,translation,10minsofcode,10minutesofcode"
categories:
- 10-mins-of-code
- React
- i18n
tags:
- 10-mins-of-code
- React
- i18n
---

I am currently implementating [internationalization](https://en.wikipedia.org/wiki/Internationalization_and_localization), often abbreviated as *i18n*, in
a React app I'm working on. I'm using [react-i18next](https://github.com/i18next/react-i18next)
to handle the translations, and I wanted to make sure we had proper test coverage for this new functionality. The way this package works,
which is just a React wrapper around the [i18next](https://www.i18next.com/) package, is by mapping nested keys to their associated values
in a particular list of translations. By some means we detect the user's language (usually from the browser), and fetch the JSON file associated
with those translations and interpolate the values into the key placeholders. For example, for English we fetch the `en.json` file

{% highlight json %}
{
  "foo": {
    "bar": {
      "baz": "Foo Bar Baz"
    }
  }
}
{% endhighlight %}

and use the package-provided `<I18n />` component to translate it. Therefore

{% highlight javascript %}
<I18n>
{
  t => (
    <span>{ t('foo.bar.baz') }</span>
  )
}
</I18n>
{% endhighlight %}

will become simply

{% highlight html %}
<span>Foo Bar Baz</span>
{% endhighlight %}

You need to create a configuration file for initialization of the __i18next__ package, providing various options. Two of these most importantly tell __i18next__
*where* to find the translation files and *how* to fetch them. For the actual application's configuration, I'm fetching the file(s) by way of XHR and a newly
created endpoint. However for unit testing, we want both instant translations and to avoid the overhead of making a network request. The documentation provides
an example of how to create an __i18next__ configuration file specifically for testing, so I used something very similar to that found [here](https://react.i18next.com/misc/testing.html).
For this configuration I tried using the [i18next-sync-fs-backend](https://github.com/sallar/i18next-sync-fs-backend) in order to instantly load the translations
by way of file fetching and reading on the server-side as opposed to an XHR request.

However, this turned out to be quite the headache. It was not translating my strings despite scouring Google, trying to verify the correct file path, etc.
I finally decided to do the importing myself, so using the file system package [fs](https://nodejs.org/api/fs.html), I fetched and parsed the JSON directly in the configuration file.
__i18next__ provides a function to add the resources as an argument rather than fetching them and handling the file parsing itself. By using `addResourceBundle`
to add the JSON resources and `readFileSync` to pull the JSON directly into the config file, I was able to get my translations rendering synchronously and correctly.
My working configuration file looked something like this:

{% highlight javascript %}
import i18n from 'i18next';
import { reactI18nextModule } from 'react-i18next';
import path from 'path';
import fs from 'fs';

i18n
  .use(reactI18nextModule)
  .init({
    initImmediate: false,
    fallbackLng: 'en',
    debug: false,
    saveMissing: true,
    preload: ['en'],

    interpolation: {
      escapeValue: false, // not needed for react!!
    },

    // react i18next special options (optional)
    react: {
      wait: true,
      nsMode: 'fallback', // set it to fallback to let passed namespaces to translated hoc act as fallbacks
    },
  })
  .addResourceBundle(
    'en',
    'my-app',
    JSON.parse(fs.readFileSync(path.join(__dirname, '../src/client/locales/en.json')))
  );


export default i18n;
{% endhighlight %}

Language values are hard-coded in this example, but you can easily provide those as dynamic arguments for other languages. If you're like
me and struggled to get this working, I hope you can find this useful, or at least learned something new. Thanks for reading!
