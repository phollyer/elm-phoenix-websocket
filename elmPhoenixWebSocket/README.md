# Accompanying JS

You need to add all these files to `assets/js/` and import
`elmPhoenixWebSocket` into `app.js` or wherever you are instantiating your Elm
program.

Probably the easiest way to get these files is to clone this repo and copy them
into your Phoenix project.

Assuming you are instantiating your Elm program something like this:

```
app = Elm.Main.init({node: "elm-container", flags: {}})
```

Then you can wire up this JS as follows:

```
import ElmPhoenixWebSocket from "./elmPhoenixWebSocket"  // Change the path accordingly

ElmPhoenixWebSocket.init(app)
```