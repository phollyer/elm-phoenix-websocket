# JS for Elm-Phoenix-WebSocket package

Add `elmPhoenixWebSocket.js` to `assets/js/` in your Phoenix App.

The following example is for an Elm SPA.

`app.js`
```
import { Socket } from "phoenix";

import { Elm } from "../elm/src/Main.elm";

import ElmPhoenixWebSocket from "./elmPhoenixWebSocket";

var flags = { your: "flags" };

var app = Elm.Main.init({flags: flags});

if(app) {
    ElmPhoenixWebSocket.init(app.ports, Socket);
} else {
  console.error('Elm Program could not be instantiated.');
}
```

In order to use Phoenix Presence you can simply change the following
lines as below.

Change:

```
import { Socket } from "phoenix";
```

To

```
import { Socket, Presence } from "phoenix";
```

And Change

```
ElmPhoenixWebSocket.init(app.ports, Socket);
```

To

```
ElmPhoenixWebSocket.init(app.ports, Socket, Presence);
```



