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


let ElmPhoenixWebSocket = {

    // The Phoenix Socket class imported with `import {Socket} from "phoenix"`
    // This is passed in as a parameter to the `init` function
    phoenixSocket: {},

    // The Phoenix JS socket instantiated with `new phoenixSocket`
    socket: {},

    // A map of channels with each topic as a unique key
    channels: {},

    // A map of lists of incoming channel messages with the topic as the key.
    // This is used to store the messages so that they can be sent over from
    // Elm prior to the relevant channel being created.
    incoming: {},

    // The Phoenix Presence class imported with `import {Presence} from "phoenix"`
    // This is passed in as a parameter to the `init` function
    phoenixPresence: {},

    // The Presence data
    presences: {},

    // The Elm ports object
    elmPorts: {},

    // The endpoint url.
    url: "/socket",

    // A flag to determine whether to keep trying to reconnect.
    // If a user has been denied due to bad creds then we shouldn't
    // keep trying to reconnect automatically.
    allowReconnect: false,

    /*     init/2

            Parameters:
                ports <object> - The Elm ports object. // Elm.AppName.ports

    */
    init(ports, socket, presence) {
        this.elmPorts = ports
        this.elmPorts.phoenixSend.subscribe( params => this[params.msg](params.payload))

        this.phoenixSocket = socket
        this.phoenixPresence = presence

        this.socket = new this.phoenixSocket(this.url, {})
        this.info()
    },

    /* Socket */

    /* connect/1

            Connect to a socket.

            Parameters:
                data <maybe object>
                    params <maybe object> - Any data to be sent to the socket when attempting to connect, such as authentication params.
                    options <maybe object> - Any options to set on the socket when creating it.


    */
    connect(data) {
        let self = this

        // Expect to be denied by a failed auth.
        this.allowReconnect = false

        this.socket = new this.phoenixSocket(this.url, this.optionsToParams(data))
        this.socket.onMessage( resp => self.socketSend("Message", resp))
        this.socket.onError( resp => self.socketSend("Error", {reason: "Unknown"}))
        this.socket.onOpen( resp => {
            self.allowReconnect = true
            self.socketSend("Opened", resp)
            self.info()
        })
        this.socket.onClose( resp => {
            if(self.allowReconnect) {

                // The socket has closed unexpectedly after having been open,
                // so we assume the closure was due to a drop in the network.
                self.socketSend("Closed", {code: resp.code, wasClean: resp.wasClean, reason: "Unreachable"})
            } else {

                // The socket closes, and allowReconnect is still equal to false, so we assume
                // the socket has denied the connection for some reason.
                //
                // Therefore, reset the reconnectTimer so that we don't keep
                // trying to connect with the same bad creds.
                self.socket.reconnectTimer.reset()

                // One known case exists that isn't covered here. If the application
                // is down, but the network up, then we end up here, sending back "Denied".
                // This is wrong, but, maybe not too much of an issue with a Phoenix OTP
                // backend. Maybe look to Ajax as a final fallback check.

                self.socketSend("Closed", {code: resp.code, wasClean: resp.wasClean, reason: "Denied"})
            }
            self.info()
        })

        this.socket.connect()
    },


    /* connectionState/0

        Retrieve the current connection state and send it back to Elm as a String.

    */
    connectionState() { this.socketSend("ConnectionState", this.socket.connectionState()) },


    /* disconnect/0

        Disconnect from the socket.

    */
    disconnect() { this.socket.disconnect() },


    /* endpoint/0

        Retrieve the current endpoint and send it back to Elm as a String.

    */
    endPointURL() { this.socketSend("EndPointURL", this.socket.endPointURL()) },


    /* makeRef/0

        Retrieve the next message ref, accounting for overflows, and send it back to Elm as a String.

    */
    makeRef() { this.socketSend("MakeRef", this.socket.makeRef()) },


    /* protocol/0

        Retrieve the current protocol and send it back to Elm as a String.

    */
    protocol() { this.socketSend("Protocol", this.socket.protocol()) },


    /* info/0

        Retrieve the socket info and send it back to Elm as a String.

    */
    info() {
        var hasLogger

        // In Phoenix v1.3.2 the hasLogger function does not exist,
        // so check it exists before calling it.
        if( this.socket.hasLogger ) {
            hasLogger = this.socket.hasLogger()
        } else {
            // The function does not exist so send back null to signify we could not test for a logger.
            hasLogger = null
        }

        var info =
            { connectionState: this.socket.connectionState(),
              endPointURL: this.socket.endPointURL(),
              hasLogger: hasLogger,
              isConnected: this.socket.isConnected(),
              nextMessageRef: this.socket.makeRef(),
              protocol: this.socket.protocol()
            }


        this.socketSend("Info", info )
    },


    /* isConnected/0

        Retrieve whether the socket is currently connected and send it back to Elm as a Bool.

    */
    isConnected() { this.socketSend("IsConnected", this.socket.isConnected()) },


    /* log/1

        Logs the message. Override this.logger for specialized logging. noops by default.

            Parameters:
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


    /* hasLogger/0

        Determine if a logger has been set on the socket and send it back to Elm as a Maybe Bool (true|false|null).

        true|false = Successfully tested and this is the result.
        null = Could not test because the function does not exist on the socket.
    */
    hasLogger() {
        // In Phoenix v1.3.2 the hasLogger function does not exist,
        // so check it exists before calling it.
        if( this.socket.hasLogger ) {
            this.socketSend("HasLogger", this.socket.hasLogger())
        } else {
            // The function does not exist so send back null to signify we could not test for a logger.
            this.socketSend("HasLogger", null)
        }
    },


    /* optionsToParams/1

            Private function intended to extract only options with a value set in Elm. It also creates
            the `reconnectAfterMs` and `rejoinAfterMs` functions when required.

                Parameter:
                    data <object>
                        params <maybe object> Any data to be sent to the socket when connecting, such as authentication params.
                        options <maybe object> Any options to set on the socket when connecting.
    */
    optionsToParams(data) {
        if (data) {
            var params = data.params ? {params: data.params} : {}

            var options = data.options
            for( var prop in options ) {
                switch(prop) {
                    case "reconnectAfterMs":

                        // Check to see if a backoff function is required for the socket.
                        if(options.reconnectSteppedBackoff) {

                            // Create the backoff function the socket uses when trying to reconnect.
                            params.reconnectAfterMs = function(tries) { return options.reconnectSteppedBackoff[ tries - 1] || options.reconnectAfterMs }
                        } else {
                            if(options.reconnectAfterMs) {

                                // No backoff function is required so just use the Int supplied.
                                params.reconnectAfterMs = options.reconnectAfterMs
                            }
                        }
                        break

                    case "rejoinAfterMs":

                        // Check to see if a backoff function is required for the channels.
                        if(options.rejoinSteppedBackoff) {

                            // Create the backoff function the channels use when trying to rejoin.
                            params.rejoinAfterMs = function(tries) { return options.rejoinSteppedBackoff[ tries - 1] || options.rejoinAfterMs }
                        } else {
                            if(options.rejoinAfterMs) {

                                // No backoff function is required so just use the Int supplied.
                                params.rejoinAfterMs = options.rejoinAfterMs
                            }
                        }
                        break

                    default:
                        params[prop] = options[prop]
                }
            }

            return params
        } else {
            return {}
        }
    },


    /* socketSend/3

            Send data to Elm.

            As we can't be certain the ports have been set up,
            make checks before trying to send the data, and report
            any errors to the console.

            Paramters:
                msg <string> - The message to send through the port.
                payload <json>|<elm comparable> - The data to send.

    */
    socketSend(msg, payload) {
        this.elmPorts.socketReceiver.send(
            {msg: msg,
             payload: payload
            }
        )
    },


    /* Channel */

    /* join

            Join a channel.

            Parameters:
                params <object>
                    topic <string> - The topic of the channel.
                    payload <maybe object> - Optional data to be sent to the channel, such as authentication params.
                    msgs <list string> - The msgs expected to come from the channel.
                    timeout <maybe int> - Optional timeout in ms.

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

        this.allOn({topic: params.topic, msgs: this.incoming[params.topic]})

        return channel
    },

    /*    push/1

            Push a msg to the server with data.

            Parameters:
                params <object>
                    msg <string> - The msg to send to the channel.
                    payload <object> - The data to send.
                    topic <maybe string> - The topic of the channel to push to.
                    timeout <maybe int> - The timeout before retrying.

    */
    push(params) {
        self = this

        // Select the channel to push to.
        let channel = this.find(params.topic)

        let push = {}

        // Push the msg and payload to the server, with or without a custom timeout.
        if(params.timeout) {
            push = channel.push(params.msg, params.payload, params.timeout)
        } else {
            push = channel.push(params.msg, params.payload)
        }

        push
            .receive("ok", (payload) => self.channelSend(params.topic, "PushOk", {msg: params.msg, payload: payload, ref: params.ref || 0}))
            .receive("error", (payload) => self.channelSend(params.topic, "PushError", {msg: params.msg, payload: payload, ref: params.ref || 0}))
            .receive("timeout", () => self.channelSend(params.topic, "PushTimeout", {msg: params.msg, payload: params.payload, ref: params.ref || 0}))
    },

    /* on/1

            Subscribe to a channel msg.

            Parameters:
                params <object>
                    topic <maybe string> - The topic of the channel to subscribe to.
                    msg <string> - The msg to subscribe to.
    */
    on(params) {
        self = this
        let channel = this.find(params.topic)

        if (channel) {
            channel.on(params.msg, payload => self.channelSend(params.topic, "Message", {msg: params.msg, payload: payload}))

        }

        this.addIncoming({topic: params.topic, msgs: [params.msg]})
    },

    /* allOn/1

            Subscribe to channel msgs.

            Store them to be re-used if a channel is disconnected by the user,
            so that they don't have to be sent over again from Elm.

            Parameters:
                params <object>
                    topic <maybe string> - The topic of the channel to subscribe to.
                    msgs <list string> - The msgs to subscribe to.
    */
    allOn(params) {
        self = this

        let channel = this.find(params.topic)

        if (channel) {
            for (let i = 0; i < params.msgs.length; i++) {
                channel.on(params.msgs[i], payload => self.channelSend(params.topic, "Message", {msg: params.msgs[i], payload: payload}))
            }
        }

        this.addIncoming(params)
    },

    addIncoming(params) {
        if (this.incoming[params.topic]) {
            this.incoming[params.topic].reduce((allMsgs, msg) => {
                if(!allMsgs.includes(msg)) {
                    allMsgs.push(msg)
                }

                return allMsgs
            }, params.msgs)
        } else {
            this.incoming[params.topic] = params.msgs
        }
    },


    /* off/1

            Turn off a subscribption to a channel msg.

            Parameters:
                params <object>
                    topic <maybe string> - The topic of the channel to unsubscribe to.
                    msg <string> - The msg to unsubscribe to.
    */
    off(params) {
        self = this

        let channel = this.find(params.topic)

        if (channel) {
            channel.off(params.msg)
        }

        this.dropIncoming({topic: params.topic, msgs: [params.msg]})
    },

    /* allOn/1

            Subscribe to channel msgs.

            Parameters:
                params <object>
                    topic <maybe string> - The topic of the channel to subscribe to.
                    msgs <list string> - The msgs to subscribe to.
    */
    allOff(params) {
        self = this

        let channel = this.find(params.topic)

        if (channel) {
            for (let i = 0; i < params.msgs.length; i++) {
                channel.off(params.msgs[i])
            }
        }

        this.dropIncoming(params)
    },

    dropIncoming(params) {
        let incoming = this.incoming[params.topic]

        if (incoming) {
            incoming.filter( msg => !params.msgs.includes(msg))
        }
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
        this.channelSend(topic, "LeaveOk", {})

        delete this.find(topic)
    },

    /* find/1

            Find a channel by topic.

            Parameters:
                topic <string> - The topic of the channel to find.
    */
    find(topic) {
        return this.channels[topic]
    },

    /* channelSend/3

            Send data to Elm.

            As we can't be certain the ports have been set up,
            make checks before trying to send the data, and report
            any errors to the console.

            Paramters:
                topic <string> - The channel topic.
                msg <string> - The message to send through the port.
                payload <json>|<elm comparable> - The data to send.

    */
    channelSend(topic, msg, payload) {
        this.elmPorts.channelReceiver.send(
            {topic: topic,
             msg: msg,
             payload: payload
            }
        )
    },


    /* Presence */


    /*     onDiff/2

            Called when a user presence joins or leaves.

            Parameters:
                topic <string> - The channel topic.
                diff <object> - The diff received from Phoenix Presence.

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


    /*     onState/2

            Called when a user presence joins or leaves.

            Parameters:
                topic <string> - The channel topic.
                state <object> - The state received from Phoenix Presence.

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

        this.presenceSend(topic, "State",{list: this.phoenixPresence.list(newPresence, (id, metas) => (this.packageForElm(id, metas)))})

        this.presences[topic] = newPresence
    },


    /* toList/1

            List the presences in a consistent form that is easier to handle in Elm.

            Parameters:
                presence <object> - The raw presence data received from the server. // {"id1": metas, "id2": metas, ... }

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


    /* packageForElm/2

            Package the presence into a consistent form that is easier to handle in Elm.

            Parameters:
                id <string> - The user id.
                presence <object> - The raw presence data received from the server. // {"id1": metas}

            Returns:
                {id: "id1", metas: metas}
    */
    packageForElm(id, presence) { return {id: id, metas: presence.metas} },


    /* presenceSend/3

            Send data to Elm.

            As we can't be certain the ports have been set up,
            make checks before trying to send the data, and report
            any errors to the console.

            Paramters:
                topic <string> - The channel topic.
                msg <string> - The message to send through the port.
                payload <json>|<elm comparable> - The data to send.

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



