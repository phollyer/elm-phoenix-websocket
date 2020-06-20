# Elm 0.19.x package for Phoenix WebSockets

For more information about Phoenix WebSockets see
[Phoenix.Channel](https://hexdocs.pm/phoenix/1.5.3/Phoenix.Channel.html#content)
, [Phoenix.Presence](https://hexdocs.pm/phoenix/1.5.3/Phoenix.Presence.html#content)
and [PhoenixJS](https://hexdocs.pm/phoenix/js).

Multiple channels and Presences are supported from within your Elm program.

In order for your Elm program to talk to
[PhoenixJS](https://hexdocs.pm/phoenix/js), you will need to add a very small
[`port`](https://github.com/phollyer/elm-phoenix-websocket/blob/master/src/Ports/Phoenix.elm)
module to your Elm `src` files, and some
[JavaScript](https://github.com/phollyer/elm-phoenix-websocket/tree/master/elmPhoenixWebSocket)
files to your Phoenix project.

# How To
## Set up JavaScript for Elm and ElmPhoenixWebSocket

You first need to copy the contents of the
[`elmPhoenixWebSocket`](https://github.com/phollyer/elm-phoenix-websocket/tree/master/elmPhoenixWebSocket)
folder into `assets/js`.

Here is an example `app.js` that sets up Elm and ElmPhoenixWebSocket.

*Two assumptions are made here:*

1. *The location of your `Main.elm` file is `assets/elm/src`, change the path
if you need to.*
2. *You are using [`webpack`](https://webpack.js.org/) for asset management,
along with [`elm-webpack-loader`](https://github.com/elm-community/elm-webpack-loader).*

```
import { Elm } from "../elm/src/Main.elm";
import ElmPhoenixWebSocket from "./elmPhoenixWebSocket/elmPhoenixWebSocket";

var elmContainerId = 'elm-app-container';
var elmContainer = document.getElementById(elmContainerId);
var app;

if (elmContainer) {
    app = Elm.Main.init({node: elmContainer, flags: {}});
} else {
    console.error("Could not find Elm container: " + elmContainerId);
}

if(app) {
    ElmPhoenixWebSocket.init(app.ports);
} else {
    console.error('Elm Program could not be instantiated.');
}
```
## Set up JavaScript for just ElmPhoenixWebSocket assuming Elm is already setup

You first need to copy the contents of the
[`elmPhoenixWebSocket`](https://github.com/phollyer/elm-phoenix-websocket/tree/master/elmPhoenixWebSocket)
folder into `assets/js`.

*Assuming you already have Elm setup in your Phoenix project and instantiated
as `app`:*


```
import ElmPhoenixWebSocket from "./elmPhoenixWebSocket/elmPhoenixWebSocket";

ElmPhoenixWebSocket.init(app.ports);
```

# Set up Elm

Add
[`Ports/Phoenix.elm`](https://github.com/phollyer/elm-phoenix-websocket/tree/master/src/Ports)
to your Elm `src` folder, changing the module name to suit if required.

Install the package.

    elm install phollyer/elm-phoenix-websocket

# Example

There is a working example
[here](https://github.com/phollyer/elm-phoenix-websocket/tree/master/example/chat_room)
that you can run locally and also inspect the code.

The file
[example/chat_room/assets/elm/src/ExampleChatProgram.elm](https://github.com/phollyer/elm-phoenix-websocket/tree/master/example/chat_room/assets/elm/src/ExampleChatProgram.elm)
is commented and documented, so as well as browsing through the file, you can
navigate to `example/chat_room/assets/elm` and use
[elm-doc-preview](https://github.com/dmy/elm-doc-preview) to read the docs.