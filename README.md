# Elm 0.19.x package for Phoenix WebSockets

A very simple to use Package that provides your Elm program access to the
PhoenixJS API.

In order for your Elm program to talk to PhoenixJS, you will need to add a
JavaScript file to your Phoenix project and a very small Port module to your
Elm `src` files.

## Set up JavaScript

The JS file you need, and set up instructions are
[`here`](https://github.com/phollyer/elm-phoenix-websocket/tree/master/js).

The Port module you need, and set up instructions are
[`here`](https://github.com/phollyer/elm-phoenix-websocket/tree/master/ports).

## Install the package.

    elm install phollyer/elm-phoenix-websocket

## Examples

A Phoenix application that provides an Elm SPA with a dozen examples can be found
[here](https://github.com/phollyer/elm-phoenix-websocket-example).

The relevant Elm files for the examples are
[here](https://github.com/phollyer/elm-phoenix-websocket-example/assets/elm/src/Example).

A live Phoenix application with the Elm SPA can be found
[here](http://www.elm-phoenix-websocket-example.hollyer.me.uk)

## Further Reading

Package [docs](https://package.elm-lang.org/packages/phollyer/elm-phoenix-websocket/latest/Phoenix).

For more information about Phoenix WebSockets see
[Phoenix.Channel](https://hexdocs.pm/phoenix/1.5.3/Phoenix.Channel.html#content)
, [Phoenix.Presence](https://hexdocs.pm/phoenix/1.5.3/Phoenix.Presence.html#content)
and [PhoenixJS](https://hexdocs.pm/phoenix/js).



