# JS for Elm-Phoenix-WebSocket package

Add `elmPhoenixWebSocket.js` to `assets/js/` in your Phoenix App.


## A simple Elm Program

`assets/js/app.js`
```
import { Socket, Presence } from "phoenix";

import { Elm } from "../elm/src/Main.elm";

import ElmPhoenixWebSocket from "./elmPhoenixWebSocket";

var elmContainer = document.getElementById('your-elm-app-container-id');

var app = Elm.Main.init({node: elmContainer, flags: { your: "flags" }});

ElmPhoenixWebSocket.init(app.ports, Socket, Presence);
```

## An Elm SPA

`assets/js/app.js`
```
import { Socket, Presence } from "phoenix";

import { Elm } from "../elm/src/Main.elm";

import ElmPhoenixWebSocket from "./elmPhoenixWebSocket";

var app = Elm.Main.init({flags: { your: "flags" }});

ElmPhoenixWebSocket.init(app.ports, Socket, Presence);
```

**Note:**

This is Version 3

For Version 2, go to:

https://github.com/phollyer/elm-phoenix-websocket/tree/2.0.0

For Version 1.1.0

https://github.com/phollyer/elm-phoenix-websocket/tree/1.1.0