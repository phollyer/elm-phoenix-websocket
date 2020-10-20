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

   This is Version 3

   For Version 2, go to:

   https://github.com/phollyer/elm-phoenix-websocket/tree/2.0.0

   For Version 1.1.0

   https://github.com/phollyer/elm-phoenix-websocket/tree/1.1.0

*/


let ElmPhoenixWebSocket = {

    /* The Phoenix Socket class imported with `import {Socket} from "phoenix"`.

       This is passed in as a parameter to the `init` function.
    */
    phoenixSocket: {},

    // The Phoenix JS socket instantiated with `new phoenixSocket(url, params)`.
    socket: {},

    socketMessages: {channel: true, presence: true, heartbeat: true},

    /* A map of channels with each topic as the key.

       This is used to store multiple channels.
    */
    channels: {},

    /* A map of lists of events channel events with the topic as the key.

       This is used to store the events so that they can be sent over from
       Elm prior to the relevant channel being created.
    */
    events: {},

    /* The Phoenix Presence class imported with `import {Presence} from "phoenix"`.

       This is passed in as a parameter to the `init` function.
     */
    phoenixPresence: {},

    /* A map of presence data with the channel topic as the key.

       This is used to store the presence data when multiple channels are used.
    */
    presences: {},

    // The Elm ports object.
    elmPorts: {},

    // The endpoint url.
    url: "/socket",

    /* This is used in the onClose and onOpen callback functions because
       onClose does not provide enough information to determine if the
       user was:

           1. Denied access by the Elixir socket, or
           2. The internet connection dropped out

       We assume the user will be denied, and only set this to true when the
       socket connects successfully. Therefore we currently assume that if
       this value is true when onClose fires, it is because the network has
       dropped out.
    */
    allowReconnect: false,

    /* init

        Set up the ports, socket and presence.

        Send the socket info back to Phoenix.elm
    */
    init(ports, socket, presence) {
        this.elmPorts = ports
        this.elmPorts.phoenixSend.subscribe( params => this[params.msg](params.payload))

        this.phoenixSocket = socket
        this.phoenixPresence = presence

        this.socket = new this.phoenixSocket(this.url, {})
        this.info()
    },

    /********** Socket **********/

    /* connect

        Connect to the socket.

        Set up the callback functions.

        data <maybe object>
            params <maybe object>
                Data to be sent to the socket when attempting to connect, such
                as authentication params.

            options <maybe object>
                Options to set on the socket when creating it.
    */
    connect(data) {
        let self = this

        this.socket = new this.phoenixSocket(this.url, this.setOptionsAndParams(data))
        this.socket.onError( resp => self.socketSend("Error", {reason: "Unknown"}))
        this.socket.onMessage( resp => self.onMessage(resp))

        this.socket.onOpen( resp => {
            self.socketSend("Opened", resp)
            self.info()
            self.allowReconnect = true
        })

        this.socket.onClose( resp => {
            if(self.allowReconnect) {

                /* The socket has closed unexpectedly after having been open,
                   so we assume the closure was due to a drop in the network.
                */
                self.socketSend("Closed", {code: resp.code, wasClean: resp.wasClean, reason: "Unreachable"})
            } else {

                /* The socket closes, and allowReconnect is still equal to
                   false, so we assume the socket has denied the connection for
                   some reason.

                   Therefore, reset the reconnectTimer so that we don't keep
                   trying to connect with the same bad creds.
                 */
                self.socket.reconnectTimer.reset()

                /* One known case exists that isn't covered here.

                   If the application or the server is down, but the network
                   up, then we still end up here, sending back "Denied". This
                   is the wrong response for this scenario.

                   TODO:

                   Send an ajax request to the server to determine if it is the
                   application or the server that is down.

                   If the server is unreachable, send an ajax request to an
                   alternative server. As it is unlikely that both servers will
                   be down at the same time, we can then assume that the user
                   does not have access to the internet.

                   This would require the user to opt in and provide additional
                   config details to be used by the ajax requests.
                 */
                self.socketSend("Closed", {code: resp.code, wasClean: resp.wasClean, reason: "Denied"})
            }
            self.info()
        })

        this.info()

        // Ensure this is set to false before trying to connect.
        this.allowReconnect = false

        this.socket.connect()
    },

    /* setOptionsAndParams

        data <object>
            params <maybe object>
                Any data to be sent to the socket when connecting, such as
                authentication params.

            options <maybe object>
                Any options to set on the socket when connecting.
    */
    setOptionsAndParams(data) {
        if (data) {

            let options = data.options

            if (options) {
                if (options.reconnectSteppedBackoff && options.reconnectAfterMs) {
                    options.reconnectAfterMs = function(tries) { return options.reconnectSteppedBackoff[ tries - 1] || options.reconnectAfterMs }
                    delete options.reconnectSteppedBackoff
                }

                if (options.rejoinSteppedBackoff && options.rejoinAfterMs) {
                    options.rejoinAfterMs = function(tries) { return options.rejoinSteppedBackoff[ tries - 1] || options.rejoinAfterMs }
                    delete options.rejoinSteppedBackoff
                }

                if (options.logger) {
                    options.logger = this.logger
                }
            }

            if (data.params && options) {
                options.params = data.params
            } else if (data.params) {
                options = data
            }

            return options
        }

        return null
    },


    /* disconnect

        Disconnect from the socket.
    */
    disconnect( params ) {
        this.socket.disconnect( () => {}, params.code)
    },


    /* onMessage */

    onMessage( resp ) {
        if (resp.topic == "phoenix" && this.socketMessages.heartbeat) {
            this.socketSend("Heartbeat", resp)

        } else if (resp.event.indexOf("presence") == 0 && this.socketMessages.presence) {
            this.socketSend("Presence", resp)

        } else if (this.socketMessages.channel ){
            this.socketSend("Channel", resp)
        }
    },

    /***** Message Control *****/

    allMessagesOn() {
        this.socketMessages =
            { channel: true,
              presence: true,
              heartbeat: true
            }
    },

    allMessagesOff() {
        this.socketMessages =
            { channel: false,
              presence: false,
              heartbeat: false
            }
    },

    channelMessagesOn() { this.socketMessages.channel = true },

    channelMessagesOff() { this.socketMessages.channel = false },

    presenceMessagesOn() { this.socketMessages.presence = true },

    presenceMessagesOff() { this.socketMessages.presence = false },

    heartbeatMessagesOn() { this.socketMessages.heartbeat = true },

    heartbeatMessagesOff() { this.socketMessages.heartbeat = false },

    /***** Socket Information *****/


    /* connectionState

        Retrieve the current connection state and send it back to Elm as a String.
    */
    connectionState() { this.socketSend("ConnectionState", this.socket.connectionState()) },


    /* endpoint

        Retrieve the current endpoint and send it back to Elm as a String.
    */
    endPointURL() { this.socketSend("EndPointURL", this.socket.endPointURL()) },

    /* hasLogger

        Determine if a logger has been set on the socket and send it back to
        Elm as a Maybe Bool.

        The hasLogger function does not exist on all versions of PhoenixJS so
        we check it exists before calling it.

        If it does exist, we call the function and send back the result.

        If it does not exist, we simply send back `null` to signify that the
        function is not available.
    */
    hasLogger() { this.socketSend("HasLogger", this.getHasLogger()) },

    getHasLogger() {
        if( this.socket.hasLogger ) {
            return this.socket.hasLogger()
        } else {
            return null
        }
    },

    /* isConnected

        Retrieve whether the socket is currently connected and send it back to
        Elm as a Bool.
    */
    isConnected() { this.socketSend("IsConnected", this.socket.isConnected()) },


    /* makeRef

        Retrieve the next message ref, accounting for overflows, and send it
        back to Elm as a String.
    */
    makeRef() { this.socketSend("MakeRef", this.socket.makeRef()) },


    /* protocol

        Retrieve the current protocol and send it back to Elm as a String.
    */
    protocol() { this.socketSend("Protocol", this.socket.protocol()) },


    /* info

        Retrieve all the socket info and send it back to Elm.
    */
    info() {
        let info =
            { connectionState: this.socket.connectionState(),
              endPointURL: this.socket.endPointURL(),
              hasLogger: this.getHasLogger(),
              isConnected: this.socket.isConnected(),
              nextMessageRef: this.socket.makeRef(),
              protocol: this.socket.protocol()
            }

        this.socketSend("Info", info )
    },

    /* socketSend

        Send data to Elm.

        msg <string>
            The message to send through the port.

        payload <json>|<elm comparable>
            The data to send.
    */
    socketSend(msg, payload) {
        this.elmPorts.socketReceiver.send(
            {msg: msg,
             payload: payload
            }
        )
    },


    /* log

        Logs the message.

        params <object>
            kind <string>
            msg <string>
            data <object>
    */
    log(params) {
        if( this.socket.hasLogger && this.socket.hasLogger() ) {
            this.socket.log(params.kind, params.msg, params.data)
        }
    },

    startLogging() {
        this.socket.logger = this.logger
    },

    stopLogging() {
        this.socket.logger = null
    },

    logger(kind, msg, data) { console.log(`${kind}: ${msg}`, data) },





    /********** Channel **********/

    /* join

        Join a channel.

        params <object>
            topic <string>
                The topic of the channel.

            payload <maybe object>
                Optional data to be sent to the channel, such as
                authentication params.

            events <list string>
                The events expected to come from the channel.

            timeout <maybe int>
                Optional timeout in ms.
    */
    join(params) {
        let self = this

        let channel = this.createChannel(params)

        let join = {}

        // Join the channel, with or without a custom timeout.
        if(params.timeout) {
            join = channel.join(params.timeout)
        } else {
            join = channel.join()
        }

        join
            .receive("ok", (payload) => this.channelSend(params.topic, "JoinOk", payload))
            .receive("error", (payload) => self.channelSend(params.topic, "JoinError", payload))
            .receive("timeout", () => self.channelSend(params.topic, "JoinTimeout", params.payload))
    },

    createChannel(params) {
        let channel = this.socket.channel(params.topic, params.payload)

        channel.onClose( () => self.channelSend(params.topic, "Closed", {}))
        channel.onError( () => self.channelSend(params.topic, "Error", {}))

        channel.on("presence_diff", diff => self.onDiff(params.topic, diff))
        channel.on("presence_state", state => self.onState(params.topic, state))

        // Add the channel to the map of channels with the
        // topic as the key, so that it can be selected by
        // topic later.
        this.channels[params.topic] = channel

        this.allOn(params)

        this.allOn({topic: params.topic, events: this.events[params.topic]})

        return channel
    },

    /* push

        Push an event to the server with data.

        params <object>
            topic <string>
                The topic of the channel to push to.

            event <string>
                The event to send to the channel.

            payload <object>
                The data to send.

            timeout <maybe int>
                The timeout before retrying.
    */
    push(params) {
        self = this

        // Select the channel to push to.
        let channel = this.find(params.topic)

        let push = {}

        /* Push the event and payload to the server, with or without a custom
           timeout.
        */
        if(params.timeout) {
            push = channel.push(params.event, params.payload, params.timeout)
        } else {
            push = channel.push(params.event, params.payload)
        }

        push
            .receive("ok", (payload) => self.channelSend(params.topic, "PushOk", {event: params.event, payload: payload, ref: params.ref || 0}))
            .receive("error", (payload) => self.channelSend(params.topic, "PushError", {event: params.event, payload: payload, ref: params.ref || 0}))
            .receive("timeout", () => self.channelSend(params.topic, "PushTimeout", {event: params.event, payload: params.payload, ref: params.ref || 0}))
    },

    /* on

        Subscribe to a channel event.

        Store them it be re-used if a channel is disconnected by the user, so
        that it doesn't have to be sent over again from Elm.

        params <object>
            topic <string>
                The topic of the channel to subscribe to.

            event <string>
                The event to subscribe to.
    */
    on(params) {
        self = this
        let channel = this.find(params.topic)

        if (channel) {
            channel.on(params.event, payload => self.channelSend(params.topic, "Message", {event: params.event, payload: payload}))

        }

        this.addEvents({topic: params.topic, events: [params.event]})
    },

    /* allOn

        Subscribe to channel events.

        Store them to be re-used if a channel is disconnected by the user, so
        that they don't have to be sent over again from Elm.

        params <object>
            topic <string>
                The topic of the channel to subscribe to.

            events <list string>
                The events to subscribe to.
    */
    allOn(params) {
        self = this

        let channel = this.find(params.topic)

        if (channel) {
            for (let i = 0; i < params.events.length; i++) {
                channel.on(params.events[i], payload => self.channelSend(params.topic, "Message", {event: params.events[i], payload: payload}))
            }
        }

        this.addEvents(params)
    },

    addEvents(params) {
        if (this.events[params.topic]) {
            this.events[params.topic].reduce((events, msg) => {
                if(!events.includes(msg)) {
                    events.push(msg)
                }

                return events
            }, params.events)
        } else {
            this.events[params.topic] = params.events
        }
    },


    /* off

        Turn off a subscription to a channel event.

        params <object>
            topic <string>
                The topic of the channel to unsubscribe to.

            event <string>
                The event to unsubscribe to.
    */
    off(params) {
        self = this

        let channel = this.find(params.topic)

        if (channel) {
            channel.off(params.event)
        }

        this.dropEvents({topic: params.topic, events: [params.event]})
    },

    /* allOff

        Turn off subscriptions to channel events.

        params <object>
            topic <string>
                The topic of the channel to subscribe to.

            events <list string>
                The events to subscribe to.
    */
    allOff(params) {
        self = this

        let channel = this.find(params.topic)

        if (channel) {
            for (let i = 0; i < params.events.length; i++) {
                channel.off(params.events[i])
            }
        }

        this.dropEvents(params)
    },

    dropEvents(params) {
        let events = this.events[params.topic]

        if (events) {
            events.filter( event => !params.events.includes(event))
        }
    },


    /* leave

        Leave the channel.

        params <object>
            topic <string>
                The topic of the channel to leave.

            timeout <maybe int>
                The timeout before retrying.
    */
    leave(params) {

        // Select the channel to leave.
        let channel = this.find(params.topic)

        channel.leave(params.timeout)
            .receive("ok", _ => this.leaveOk(params.topic) )
    },


    /* leaveOk

        Callback after leaving a channel.

        topic <string>
            The topic of the channel to leave.
    */
    leaveOk(topic) {
        this.channelSend(topic, "LeaveOk", {})

        delete this.find(topic)
    },

    /* find

        Find a channel by topic.

        topic <string>
            The topic of the channel to find.
    */
    find(topic) {
        return this.channels[topic]
    },

    /* channelSend

        Send data to Elm.

        As we can't be certain the ports have been set up, make checks before
        trying to send the data, and report any errors to the console.


        topic <string>
            The channel topic.

        msg <string>
            The message to send through the port.

        payload <json>|<elm comparable>
            The data to send.
    */
    channelSend(topic, msg, payload) {
        this.elmPorts.channelReceiver.send(
            {topic: topic,
             msg: msg,
             payload: payload
            }
        )
    },


    /********** Presence **********/


    /* onDiff

        Called when a user presence joins or leaves.

        topic <string>
            The channel topic.

        diff <object>
            The diff received from Phoenix Presence.
    */
    onDiff(topic, diff) {
        let self = this

        let currentPresence = this.presences[topic] || {}

        let newPresence = this.phoenixPresence.syncDiff(
            currentPresence,
            diff,
            (id, current, newPres) => self.presenceSend(topic, "Join", (this.packageForElm(id, newPres))),
            (id, current, leftPres) => self.presenceSend(topic, "Leave", (this.packageForElm(id, leftPres)))
        )

        this.presenceSend(topic, "Diff", {leaves: this.toList(diff.leaves), joins: this.toList(diff.joins)})
        this.presenceSend(topic, "State",{list: this.phoenixPresence.list(newPresence, (id, metas) => (this.packageForElm(id, metas)))})

        this.presences[topic] = newPresence
    },


    /* onState

        Called when a user presence joins or leaves.

        topic <string>
            The channel topic.

        state <object>
            The state received from Phoenix Presence.
    */
    onState(topic, state) {
        let self = this

        let currentPresence = this.presences[topic]

        let newPresence = this.phoenixPresence.syncState(
            currentPresence,
            state,
            (id, current, newPres) => self.presenceSend(topic, "Join", (this.packageForElm(id, newPres))),
            (id, current, leftPres) => self.presenceSend(topic, "Leave", (this.packageForElm(id, leftPres)))
        )

        this.presenceSend(topic, "State",{list: this.phoenixPresence.list(newPresence, (id, presence) => (this.packageForElm(id, presence)))})

        this.presences[topic] = newPresence
    },


    /* toList

        List the presences in a consistent form that is easier to handle in
        Elm.

        presence <object>
            The raw presence data received from the server.

                {"id1": metas, "id2": metas, ... }

        Returns:
            [{id: "id1", metas: metas}, {id: "id2", metas: metas}, ... ]
    */
    toList(presence) {
        let list = []

        for(var id in presence) {
            list.push(this.packageForElm(id, presence[id]))
        }

        return list
    },


    /* packageForElm

        Package the presence into a consistent form that is easier to handle in
        Elm.

        id <string>
            The user id.

        presence <object>
            The raw presence data received from the server.

        The metas key will always be present.

        The user key may be present if the fetch/2 callback is being used in
        the Elixir Presence module to fetch user information from the DB.

        The whole presence Object is also provided in order to enable decoding
        of additional data stored on the Presence that can't be foreseen.
    */
    packageForElm(id, presence) {
        return {id: id, metas: presence.metas, user: presence.user || null, presence: presence}
    },


    /* presenceSend

        Send data to Elm.

        As we can't be certain the ports have been set up, make checks before
        trying to send the data, and report any errors to the console.

        topic <string>
            The channel topic.

        msg <string>
            The message to send through the port.

        payload <json>|<elm comparable>
            The data to send.
    */
    presenceSend(topic, msg, payload) {
        if(this.elmPorts.presenceReceiver) {
            this.elmPorts.presenceReceiver.send(
                {topic: topic,
                 msg: msg,
                 payload: payload
                }
            )
        } else {
            console.warn("No presenceReceiver port found.")
        }
    }
}

export default ElmPhoenixWebSocket



