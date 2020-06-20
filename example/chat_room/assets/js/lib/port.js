////////////////////////////////////////////////////////
//
// port.js
// JavaScript module code for elmPhoenixWebSocket.js,
// webSocket.js, channel.js and presences.js
// Copyright (c) 2019 Paul Hollyer <paul@hollyer.me.uk>
// Some rights reserved.
// Distributed under the MIT License
// See LICENSE
//
////////////////////////////////////////////////////////

var channelReceiver = {}
var socketReceiver = {}
var presenceReceiver = {}

let Port  = {

    /* init/1

            Initialize the channelReceiver object that sends data to be received by Elm.

            Parameters:
                receiver <object> - The Elm ports channelReceiver object.

    */
    init(socketReceiver_, channelReceiver_, presenceReceiver_) {
        socketReceiver = socketReceiver_
        channelReceiver = channelReceiver_
        presenceReceiver = presenceReceiver_
    },

    /* sendToSocket/3

            Send data to Elm.

            As we can't be certain the ports have been set up,
            make checks before trying to send the data, and report
            any errors to the console.

            Paramters:
                event <string> - The message to send through the port.
                payload <json>|<elm comparable> - The data to send.

    */
    sendToSocket(event, payload) {
        if(socketReceiver) {
            if(socketReceiver.send) {
                socketReceiver.send(
                    {event: event,
                     payload: payload
                    }
                )
            } else {
                console.error("Ports socketReceiver object does not have a send function.")
            }
        } else {
            console.error("Ports socketReceiver object not found.")
        }
    },

    /* sendToChannel/3

            Send data to Elm.

            As we can't be certain the ports have been set up,
            make checks before trying to send the data, and report
            any errors to the console.

            Paramters:
                topic <string> - The channel topic.
                event <string> - The message to send through the port.
                payload <json>|<elm comparable> - The data to send.

    */
    sendToChannel(topic, event, payload) {
        if(channelReceiver) {
            if(channelReceiver.send) {
                channelReceiver.send(
                    {topic: topic,
                     event: event,
                     payload: payload
                    }
                )
            } else {
                console.error("Ports channelReceiver object does not have a send function.")
            }
        } else {
            console.error("Ports channelReceiver object not found.")
        }
    },

    /* sendToPresence/3

            Send data to Elm.

            As we can't be certain the ports have been set up,
            make checks before trying to send the data, and report
            any errors to the console.

            Paramters:
                topic <string> - The channel topic.
                event <string> - The message to send through the port.
                payload <json>|<elm comparable> - The data to send.

    */
    sendToPresence(topic, event, payload) {
        if(presenceReceiver) {
            if(presenceReceiver.send) {
                presenceReceiver.send(
                    {topic: topic,
                     event: event,
                     payload: payload
                    }
                )
            } else {
                console.error("Ports presenceReceiver object does not have a send function.")
            }
        } else {
            console.error("Ports presenceReceiver object not found.")
        }
    }
}

export default Port