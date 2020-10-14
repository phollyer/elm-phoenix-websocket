
import {Socket, Presence} from "phoenix"
import { Elm } from "../elm/src/Main.elm";
import ElmPhoenixWebSocket from "./elmPhoenixWebSocket";

var app = Elm.Main.init({});

ElmPhoenixWebSocket.init(app.ports, Socket, Presence);

