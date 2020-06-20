////////////////////////////////////////////////////////
//
// elmPhoenixWebSocket.js
// JavaScript runtime code for Elm-Phoenix-WebSocket
// Copyright (c) 2019 Paul Hollyer <paul@hollyer.me.uk>
// Some rights reserved.
// Distributed under the MIT License
// See LICENSE
//
////////////////////////////////////////////////////////

/*
    This module is to be used in conjunction with Socket.elm, Channel.elm,
    Presences.elm and Ports/Phoenix.elm.

    It is intended to simply route messages and events back
    and forth between Elm and the Phoenix JS Websocket client, but in a nice
    Elm friendly way.
*/

import WebSocket from "./lib/webSocket"
import Channel from "./lib/channel"
import Port from "./lib/port"

var socket = {}


let ElmPhoenixWebSocket = {

    /*     init/2

            Parameters:
                ports <object> - The Elm ports object. // Elm.AppName.ports

    */
    init(ports) {
        if(ports) {
            Port.init(
                ports.socketReceiver,
                ports.channelReceiver,
                ports.presenceReceiver
            )

              if(ports.sendMessage) {
                  ports.sendMessage.subscribe( params => this.sendMessage(params))
              }
        } else {
            console.error("No ports object found so no ports set up.")
        }

        return this;
    },

    sendMessage(params) {
        switch (params.target) {
            case "socket":
                this.socketMessage(params.event, params.payload)
                break;
            case "channel":
                this.channelMessage(params.event, params.payload)
                break;
            default:
                console.error("Invalid target: " + params.target)
        }
    },
    socketMessage(msg, payload) {
        switch (msg) {
            case "connect":
                socket = WebSocket.connect(payload)
                break;

            default:
                WebSocket[msg](payload)
        }
    },
    channelMessage(msg, payload) {
        switch(msg) {
            case "join":
                Channel.join(payload, socket)
                break;
            default:
                Channel[msg](payload)
        }
    }
}

export default ElmPhoenixWebSocket



