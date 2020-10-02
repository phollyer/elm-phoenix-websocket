
import {Socket, Presence} from "phoenix"
import { Elm } from "../elm/src/ExampleChatProgram.elm";
import ElmPhoenixWebSocket from "./elmPhoenixWebSocket";

var flags =
  { height: window.innerHeight,
    width: window.innerWidth,
    version: document.querySelector('#body').dataset.version
  };

var elmContainer = document.getElementById('elm-app-container')
var app = Elm.ExampleChatProgram.init({node: elmContainer, flags: flags});

ElmPhoenixWebSocket.init(app.ports, Socket, Presence);

