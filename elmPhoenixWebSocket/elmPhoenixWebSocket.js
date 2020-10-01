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

// The Phoenix Socket class imported with `import {Socket} from "phoenix"`
// This is passed in as a parameter to the `init` function
var phoenixSocket

// The Phoenix JS socket instantiated with `new phoenixSocket`
var socket

// The current channel
var channel

// A map of channels with each topic as a unique key
var channels = {}

// The Phoenix Presence class imported with `import {Presence} from "phoenix"`
// This is passed in as a parameter to the `init` function
var phoenixPresence

// The Presence data
var presence = {}

// The Elm ports object
var elmPorts

// The endpoint url.
var url = "/socket"

// A flag to determine whether to keep trying to reconnect.
// If a user has been denied due to bad creds then we shouldn't
// keep trying to reconnect automatically.
var allowReconnect = false


let ElmPhoenixWebSocket = {

    /*     init/2

            Parameters:
                ports <object> - The Elm ports object. // Elm.AppName.ports

    */
    init(ports, socket, presence) {
        elmPorts = ports
        elmPorts.sendMessage.subscribe( params => this[params.event](params.payload))

        phoenixSocket = socket
        phoenixPresence = presence
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
        allowReconnect = false

        socket = new phoenixSocket(url, this.optionsToParams(data))
        socket.onError( resp => self.sendToSocket("Error", resp))
        socket.onMessage( resp => self.sendToSocket("Message", resp))
        socket.onOpen( function(resp) {
                allowReconnect = true
                self.sendToSocket("Opened", resp)
            }
        )
        socket.onClose( function(resp) {
            if(allowReconnect) {

                // The socket has closed unexpectedly after having been open,
                // so we assume the closure was due to a drop in the network.
                self.sendToSocket("Error", {reason: "Unreachable"})
            } else {

                // The socket closes, and allowReconnect is still equal to false, so we assume
                // the socket has denied the connection for some reason.
                //
                // Therefore, reset the reconnectTimer so that we don't keep
                // trying to connect with the same bad creds.
                socket.reconnectTimer.reset()

                // One known case exists that isn't covered here. If the application
                // is down, but the network up, then we end up here, sending back "Denied".
                // This is wrong, but, maybe not too much of an issue with a Phoenix OTP
                // backend. Maybe look to Ajax as a final fallback check.

                self.sendToSocket("Error", {reason: "Denied"})
            }
                self.sendToSocket("Closed", resp)
            }
        )


        socket.connect()

        return socket
    },


    /* connectionState/0

        Retrieve the current connection state and send it back to Elm as a String.

    */
    connectionState() { Port.sendToSocket("ConnectionState", socket.connectionState()) },


    /* disconnect/0

        Disconnect from the socket.

    */
    disconnect() { socket.disconnect() },


    /* endpoint/0

        Retrieve the current endpoint and send it back to Elm as a String.

    */
    endPointURL() { Port.sendToSocket("EndPointURL", socket.endPointURL()) },


    /* makeRef/0

        Retrieve the next message ref, accounting for overflows, and send it back to Elm as a String.

    */
    makeRef() { Port.sendToSocket("MakeRef", socket.makeRef()) },


    /* protocol/0

        Retrieve the current protocol and send it back to Elm as a String.

    */
    protocol() { Port.sendToSocket("Protocol", socket.protocol()) },


    /* isConnected/0

        Retrieve whether the socket is currently connected and send it back to Elm as a Bool.

    */
    isConnected() { Port.sendToSocket("IsConnected", socket.isConnected()) },


    /* log/1

        Logs the message. Override this.logger for specialized logging. noops by default.

            Parameters:
                params <object>
                    kind <string>
                    msg <string>
                    data <object>
    */
    log(params) {
        if( socket.hasLogger && socket.hasLogger() ) {
            socket.log(params.kind, params.msg, params.data)
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
        if( socket.hasLogger ) {
            Port.sendToSocket("HasLogger", socket.hasLogger())
        } else {
            // The function does not exist so send back null to signify we could not test for a logger.
            Port.sendToSocket("HasLogger", null)
        }
    },


    /* optionsToParams/1

            Private function intended to extract only options with a value set in Elm. It also creates
            the `reconnectAfterMs` and `rejoinAfterMs` functions when required.

                Parameter:
                    params_ <object>
                        params <maybe object> Any data to be sent to the socket when connecting, such as authentication params.
                        options <maybe object> Any options to set on the socket when connecting.
    */
    optionsToParams(params_) {
        if(params_) {
            var options = params_.options
            var params = {params: params_.params || params_}

            for( var prop in options ) {
                switch(prop) {
                    case "reconnectAfterMs":

                        // Check to see if a backoff function is required for the socket.
                        if(options.reconnectSteppedBackoff && options.reconnectMaxBackOff) {

                            // Create the backoff function the socket uses when trying to reconnect.
                            params.reconnectAfterMs = function(tries) { return options.reconnectSteppedBackoff[ tries - 1] || options.reconnectMaxBackOff }
                        } else {
                            if(options.reconnectAfterMs) {

                                // No backoff function is required so just use the Int supplied.
                                params.reconnectAfterMs = options.reconnectAfterMs
                            }
                        }
                        break

                    case "rejoinAfterMs":

                        // Check to see if a backoff function is required for the channels.
                        if(options.rejoinSteppedBackoff && options.rejoinMaxBackOff) {

                            // Create the backoff function the channels use when trying to rejoin.
                            params.rejoinAfterMs = function(tries) { return options.rejoinSteppedBackoff[ tries - 1] || options.rejoinMaxBackOff }
                        } else {
                            if(options.rejoinAfterMs) {

                                // No backoff function is required so just use the Int supplied.
                                params.rejoinAfterMs = options.rejoinAfterMs
                            }
                        }
                        break

                    default:

                        // If an option has a value add it to the params object.
                        //
                        // Null values could be comming in from Elm, and we don't want
                        // to override a default by mistake. So we only add properties
                        // that have values other than null.
                        if(options[prop]) {
                            params[prop] = options[prop]
                        }
                }
            }

            return params
        }
    },

    /* Channel */

    /* join/2

            Join a channel.

            Parameters:
                params <object>
                    topic <string> - The topic of the channel.
                    events <list string> - The events expected to come from the channel.
                    msg <object> - Any data to be sent to the channel, such as authentication params.

                socket <object> - The Phx Socket.

    */
    join(params) {
        let self = this

        channel = socket.channel(params.topic, params.payload)
        channel.onClose( () => self.sendToChannel(params.topic, "Closed", {}))
        channel.onError( (error) => self.sendToChannel(params.topic, "Error", {msg: error}))

        channel.on("presence_diff", diff => self.onDiff(params.topic, diff))
        channel.on("presence_state", state => self.onState(params.topic, state))

        let join = {}

        // Join the channel, with or without a custom timeout.
        if(params.timeout) {
            join = channel.join(params.timeout)
        } else {
            join = channel.join()
        }

        join
            .receive("ok", (payload) => self.joinOk(channel, params.topic, payload))
            .receive("error", (payload) => self.sendToChannel(params.topic, "JoinError", payload))
            .receive("timeout", () => self.sendToChannel(params.topic, "JoinTimeout", {payload: params.payload}))

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

        this.sendToChannel(topic, "JoinOk", payload)
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
        self = this

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
            .receive("ok", (payload) => self.sendToChannel(params.topic, "PushOk", {event: params.event, payload: payload}))
            .receive("error", (payload) => self.sendToChannel(params.topic, "PushError", {event: params.event, payload: payload}))
            .receive("timeout", () => self.sendToChannel(params.topic, "PushTimeout", {event: params.event, payload: params.payload}))
    },

    /* on/1

            Subscribe to a channel event.

            Parameters:
                params <object>
                    topic <maybe string> - The topic of the channel to subscribe to.
                    event <string> - The event to subscribe to.
    */
    on(params) {
        self = this
        this.find(params.topic)
            .on(params.event, payload => self.sendToChannel(params.topic, "Message", {event: params.event, payload: payload}))
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
        this.sendToChannel(topic, "LeaveOk", {})

        delete this.find(topic)
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


    /* Presence */


    /*     onDiff/2

            Called when a user presence joins or leaves.

            Parameters:
                topic <string> - The channel topic.
                diff <object> - The diff received from Phoenix Presence.

    */
    onDiff(topic, diff) {
        let self = this

        presence = phoenixPresence.syncDiff(
            presence,
            diff,
            (id, current, newPres) => self.sendToPresence(topic, "Join", (this.packageForElm(id, newPres))),
            (id, current, leftPres) => self.sendToPresence(topic, "Leave", (this.packageForElm(id, leftPres)))
        )

        this.sendToPresence(topic, "Diff", {leaves: this.toList(diff.leaves), joins: this.toList(diff.joins)})
        this.sendToPresence(topic, "State",{list: phoenixPresence.list(presence, (id, metas) => (this.packageForElm(id, metas)))})
    },


    /*     onState/2

            Called when a user presence joins or leaves.

            Parameters:
                topic <string> - The channel topic.
                state <object> - The state received from Phoenix Presence.

    */
    onState(topic, state) {
        let self = this

        presence = phoenixPresence.syncState(
            presence,
            state,
            (id, current, newPres) => self.sendToPresence(topic, "Join", (this.packageForElm(id, newPres))),
            (id, current, leftPres) => self.sendToPresence(topic, "Leave", (this.packageForElm(id, leftPres)))
        )

        this.sendToPresence(topic, "State",{list: phoenixPresence.list(presence, (id, metas) => (this.packageForElm(id, metas)))})
    },


    /* toList/1

            List the presences in a consistent form that is easier to handle in Elm.

            Parameters:
                presences_ <object> - The raw presence data received from the server. // {"id1": metas, "id2": metas, ... }

            Returns:
                [{id: "id1", metas: metas}, {id: "id2", metas: metas}, ... ]
    */
    toList(presences_) {
        let list = []

        for(var id in presences_) {
            list.push(this.packageForElm(id, presences_[id]))
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


    /* Ports */

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
        elmPorts.socketReceiver.send(
            {event: event,
             payload: payload
            }
        )
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
        elmPorts.channelReceiver.send(
            {topic: topic,
             event: event,
             payload: payload
            }
        )
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
        if(elmPorts.presenceReceiver) {
            elmPorts.presenceReceiver.send(
                {topic: topic,
                 event: event,
                 payload: payload
                }
            )
        } else {
            console.warn("No presenceReceiver port found.")
        }
    }

}

export default ElmPhoenixWebSocket



