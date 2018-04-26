---
layout: post
title: "Flow types with React Relay and GraphQL"
date: 2018-04-25 19:38:34
comments: true
description: "Flow types with React Relay and GraphQL"
keywords: "react,relay,graphql,flow"
categories:
- React
tags:
- React
---

We've been doing some pretty cool stuff with JavaScript at my company, and I wanted to write about some of the tools we are using to "up JavaScript's game".
Obviously JS has been exploding with all the new frameworks and packages to improve its versatility, and in terms of web one of the most popular
frameworks is arguably React. While you can find React projects alive and well in many many startups, one thing that I feel doesn't get covered enough
are some of the new data fetching mechanisms that may not be your common server-side API endpoints, and the ability to bring static typing to JavaScript.

Conveniently, this post happens to touch on both of those topics and the solution to those two items we use on our projects. This is by no means meant
to be an exhaustive tutorial or introduction. However, I would strongly encourage you to learn about these topics first by checking out the documentation for
[GraphQL](https://graphql.org/) and [Flow](https://flow.org/). I wanted to briefly touch on how we combine these with React for a more pleasant development
experience.

### Flow

From the docs I linked to above,

<blockquote>
Flow is a static type checker for your JavaScript code. It does a lot of work to make you more productive. Making you code faster, smarter, more confidently, and to a bigger scale.
Flow checks your code for errors through static type annotations. These types allow you to tell Flow how you want your code to work, and Flow will make sure it does work that way.
</blockquote>

In short, Flow allows static typing in JavaScript similar to what you may have seen in Java or Swift. A couple of simple examples where this can really be helpful might include:

* Ensuring functions are not only receiving arguments of the correct type, but also the object or primitive that is returned from the function is also of the correct type
{% highlight javascript %}
// @flow
function square(n: number): number {
  return n * n;
}

square("2"); // Error!
{% endhighlight %}

* Making sure objects have their expected properties, and those properties have the correct types
{% highlight javascript %}
// @flow
type MyObject = {
  foo: number,
  bar: boolean,
  baz: string,
};

var val: MyObject = { /* ... */ };
function method(val: MyObject) { /* ... */ }
class Foo { constructor(val: MyObject) { /* ... */ } }
{% endhighlight %}

Flow can then "compile" the code in your project from the command line and report on any errors of missing or incorrect types.
This is really great for any custom objects or functions you create, but is also useful for *generated* types as well. Keep that
in mind as you continue reading.

### GraphQL

In keeping with our topic introductions, from GraphQL's documentation above:

<blockquote>
GraphQL is a query language for your API, and a server-side runtime for executing queries by using a type system you define for your data. GraphQL isn't tied to any specific database or storage engine and is instead backed by your existing code and data.
</blockquote>

This is still accomplished through a POST request to an endpoint, however the queries to that endpoint can be MUCH more verbose and structured, as well as highly flexible in that you only need to fetch
the data you need at that time, based on the schema definition. Again, I would *strongly* encourage you to read the docs as this definition does not
even begin to scratch the surface, but for the puposes of this article an example might be:

* A query constructed on the client side and sent to the GraphQL specific endpoint
{% highlight javascript %}
query HeroNameAndFriends($episode: Episode) {
  hero(episode: $episode) {
    name
    friends {
      name
    }
  }
}
{% endhighlight %}

* Variables that are passed to the endpoint along with the query
{% highlight json %}
{
  "episode": "JEDI"
}
{% endhighlight %}

* A nicely-structured response matching the query structure that was sent to the server
{% highlight json %}
{
  "data": {
    "hero": {
      "name": "R2-D2",
      "friends": [
        {
          "name": "Luke Skywalker"
        },
        {
          "name": "Han Solo"
        },
        {
          "name": "Leia Organa"
        }
      ]
    }
  }
}
{% endhighlight %}

I know it's a lot to wrap your head around, but the important item that relates to what we are discussing comes in the next paragraph from
the documentation I quoted above.

<blockquote>
A GraphQL service is created by defining types and fields on those types, then providing functions for each field on each type.
</blockquote>

Since Flow is all about defining types, it's no suprise these two topics can easily go hand in hand. Let's take a look at how they
fit into the React ecosystem.

### React and Relay

Looking at the GraphQL query above, the nested nature makes it very similar to the nested and encapsulated functionality of a React component.
Since data flows down through nested components, and a component should only know about the data it needs, a GraphQL query and schema can be
structured in such a way that the nested objects returned in the results can be segregated and sent through the properties of components in
a parent-child relationship. In that way, the data model and view model can more closely mimic one another and inherently become more manageable
as they change and evolve together.

[Relay](https://facebook.github.io/relay/docs/en/introduction-to-relay.html) is a framework that pairs with React and GraphQL to make that possible.
A top level `<QueryRenderer />` component is defined with a GraphQL query, and the subsequent response from the server is asynchronously loaded with
the returned data passed down the property chain of nested components. To get a clear picture of what that high-level component looks like, here's
an example from the docs:

{% highlight javascript %}
import React from 'react';
import { QueryRenderer, graphql } from 'react-relay';

class Example extends React.Component {
  render() {
    return (
      <QueryRenderer
        environment={environment}
        query={graphql`
          query ExampleQuery($pageID: ID!) {
            page(id: $pageID) {
              name
            }
          }
        `}
        variables={{
          pageID: '110798995619330',
        }}
        render={({error, props}) => {
          if (error) {
            return <div>{error.message}</div>;
          } else if (props) {
            return <div>{props.page.name} is great!</div>;
          }
          return <div>Loading</div>;
        }}
      />
    );
  }
}
{% endhighlight %}

### Relay and Fragment Containers

Relay is a pretty cool framework, but I think one of the features that makes it *very* powerful is its ability
to allow React components to define the data they need, even nested components that do not directly own the
`<QueryRenderer />` component definition like we saw above.

What this translates to is a higher-order component provided by Relay called a [Fragment Container](https://facebook.github.io/relay/docs/en/fragment-container.html).
It relies on a named "piece" of a GraphQL query that is defined in a child component, then referenced in the parent GraphQL query.
Relay is smart enough to assemble these query pieces before executing the query, then re-renders each component with *only* the data defined by
the fragment it contains.

Another example from the docs, if there is a top-level `<TodoList />` component:

{% highlight javascript %}
class TodoList extends React.Component {
  render() {
    return (
      <QueryRenderer
        environment={environment}
        query={graphql`
          query TodoListQuery {
            list {
              # Specify any fields required by '<TodoList>' itself.
              title
              # Include a reference to the fragment from the child component.
              todoItems {
                ...TodoItem_item
              }
            }
          }
        `}
        render={({error, props}) => {
          if (error) {
            <div>{error.message}</div>;
          } else if (props) {
            <Text>{props.list.title}</Text>
            {props.list.todoItems.map(item => <TodoItem item={item} />)}
          } else {
            <div>Loading</div>;
          }
        }}
      />
    );
  }
}
{% endhighlight %}

The Fragment Container for the `<TodoItem />` component would look like this:

{% highlight javascript %}
class TodoItem extends React.Component {
  render() {
    const item = this.props.item;
    // ...
  }
}

export default createFragmentContainer(
  TodoItem,
  item: graphql`
    # Fragment name uses underscore to denote property name
    fragment TodoItem_item on Todo {
      # Properties available on the item component property
      text
      isComplete
    }
  `,
);
{% endhighlight %}

In short, even though data is still being passed down through the component chain, each component still defines
*what* data it needs and *how* it is structured.

### Relay and Flow

As mentioned in the Flow section above, Flow is great for validating and verifying both the custom types you create
*and* generated types. If we apply that statement to GraphQL, Relay will be taking those request and returning
actual objects in the shape of those queries and passing them as properties to components.

You can imagine what a pain this would be manually adding these huge type definitions to match query definitions. Thankfully,
the NPM package [relay-compiler](https://facebook.github.io/relay/docs/en/installation-and-setup.html#set-up-relay-compiler)
makes it almost automatic. When a query is updated, a simple command in the terminal can generate or update generated Flow types
for these queries. How cool is that?!

When the command is run the definitions are inserted into a `__generated__` folder nested within the folder that contains the component.
If the `<TodoList />` and `<TodoItem />` components were in the folder `src/components/Todo/` you would find the generated type definitions
within `src/components/Todo/__generated__`. A simple **import** statement will pull the definition in, and the type can be applied to the
component's **props** variable.

{% highlight javascript %}
import type { TodoListQueryType } from './__generated__/TodoListQueryType';

class TodoList extends React.Component {
  constructor(props: TodoListQueryType) {
    ...
  }
}
{% endhighlight %}

*Viola!* One more neat little tidbit, if you are trying to access a nested type within a GraphQL query type, you can use a Flow Utility Type, `$PropertyType`
to assign the nested type to a property.

{% highlight javascript %}
import type { TodoListQueryType } from './__generated__/TodoListQueryType';

class TodoList extends React.Component {
  list: $PropertyType<TodoListQueryType, 'list'>

  constructor(props: TodoListQueryType) {
    list = props.list
    ...
  }
}
{% endhighlight %}

### What a ride!

Time to take a breath if you need it! I know we flew through a lot of information in only a few paragraphs, but I hope the topic sections and documentation links
can help guide you through the lessons in more detail. We are doing a lot of exciting things where I work and I wanted to provide just a taste of some of the fantastic
tools and technologies we're using here. I hope you enjoyed reading this as much as I enjoyed writing it, and happy coding!