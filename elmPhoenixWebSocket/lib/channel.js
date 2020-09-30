////////////////////////////////////////////////////////
//
// channel.js
// JavaScript module code for elmPhoenixWebSocket.js
// Copyright (c) 2019 Paul Hollyer <paul@hollyer.me.uk>
// Some rights reserved.
// Distributed under the MIT License
// See LICENSE
//
////////////////////////////////////////////////////////


import Port from "./port"
import Presences from "./presences"

// The current channel
var channel = {}

// A map of channels with each topic as a unique key
var channels = {}


let Channel = {

    /* join/2

            Join a channel.

            Parameters:
                params <object>
                    topic <string> - The topic of the channel.
                    events <list string> - The events expected to come from the channel.
                    msg <object> - Any data to be sent to the channel, such as authentication params.

                socket <object> - The Phx Socket.

    */
    join(params, socket) {
        let self = this

        channel = socket.channel(params.topic, params.payload)
        channel.onClose( () => self.send(params.topic, "Closed", {}))
        channel.onError( (error) => self.send(params.topic, "Error", {msg: error}))

        channel.on("presence_diff", diff => Presences.onDiff(params.topic, diff))
        channel.on("presence_state", state => Presences.onState(params.topic, state))

        let join = {}

        // Join the channel, with or without a custom timeout.
        if(params.timeout) {
            join = channel.join(params.timeout)
        } else {
            join = channel.join()
        }

        join
          .receive("ok", (payload) => self.joinOk(channel, params.topic, payload))
          .receive("error", (payload) => self.send(params.topic, "JoinError", payload))
          .receive("timeout", () => self.send(params.topic, "JoinTimeout", {payload: params.payload}))

        return channel
    },

    /* joinOk/3

            Callback function for when a channel is joined.

            Parameters:
                channel <object> - The channel object.
                topic <string> - The channel topic.
                payload <object> - The payload received from the join.
    */
    joinOk(channel, topic, payload) {
        // Add the channel to the list of channels with the
        // topic as the key, so that it can be selected by
        // topic later.
        channels[topic] = channel

        this.send(topic, "JoinOk", payload)
    },

    /*    push/1

            Push a msg to the server with data.

            Parameters:
                params <object>
                    event <string> - The event to send to the channel.
                    payload <object> - The data to send.
                    topic <maybe string> - The topic of the channel to push to.
                    timeout <maybe int> - The timeout before retrying.

    */
    push(params) {
        let self = this

        // Select the channel to push to.
        let channel = this.find(params.topic)

        let push = {}

        // Push the event and payload to the server, with or without a custom timeout.
        if(params.timeout) {
            push = channel.push(params.event, params.payload, params.timeout)
        } else {
            push = channel.push(params.event, params.payload)
        }

        push
            .receive("ok", (payload) => self.send(params.topic, "PushOk", {event: params.event, payload: payload}))
            .receive("error", (payload) => self.send(params.topic, "PushError", {event: params.event, payload: payload}))
            .receive("timeout", () => self.send(params.topic, "PushTimeout", {event: params.event, payload: params.payload}))
    },

    /* on/1

            Subscribe to a channel event.

            Parameters:
                params <object>
                    topic <maybe string> - The topic of the channel to subscribe to.
                    event <string> - The event to subscribe to.
    */
    on(params) {
        let self = this

        this.find(params.topic)
            .on(params.event, payload => self.send(params.topic, "Message", {event: params.event, payload: payload}))
    },


    /* off/1

            Turn off a subscribption to a channel event.

            Parameters:
                params <object>
                    topic <maybe string> - The topic of the channel to unsubscribe to.
                    event <string> - The event to unsubscribe to.
    */
    off(params) {
        this.find(params.topic)
            .off(params.event)
    },


    /*    leave/1

            Leave the channel.

            Parameters:
                params <object>
                    topic <maybe string> - The topic of the channel to leave.
                    timeout <maybe int> - The timeout before retrying.

    */
    leave(params) {

        // Select the channel to leave.
        let channel = this.find(params.topic)

        channel.leave(params.timeout)
            .receive("ok", _ => this.leaveOk(params.topic) )
    },


    /*    leaveOk/2

            Callback after leaving a channel.

            Parameters:
                topic <maybe string> - The topic of the channel to leave.

    */
    leaveOk(topic) {
        this.send(topic, "LeaveOk", {})

        delete this.find(topic)
    },

    /* send/2

            Send the payload back to Channel.elm
    */
    send(topic, event, payload) {
        Port.sendToChannel(topic, event, payload)
    },

    /* find/1

            Find a channel by topic, or return the current channel
            if one cannot be found by topic.

            Parameters:
                topic <maybe string> - The topic of the channel to find.
    */
    find(topic) {
        return channels[topic] || channel
    },
}

export default Channel