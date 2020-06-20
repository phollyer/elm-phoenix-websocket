////////////////////////////////////////////////////////
//
// webSocket.js
// JavaScript module code for elmPhoenixWebSocket.js
// Copyright (c) 2019 Paul Hollyer <paul@hollyer.me.uk>
// Some rights reserved.
// Distributed under the MIT License
// See LICENSE
//
////////////////////////////////////////////////////////


import Port from "./port"
import {Socket} from "phoenix"

// The Phoenix JS socket.
var socket = {}

// The endpoint url.
var url = "/socket"

// A flag to determine whether to keep trying to reconnect.
// If a user has been denied due to bad creds then we shouldn't
// keep trying to reconnect automatically.
var allowReconnect = false


let WebSocket = {

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

        socket = new Socket(url, this.optionsToParams(data))
        socket.onOpen( resp => self.send("Opened", resp))
        socket.onClose( resp => self.send("Closed", resp))
        socket.onError( resp => self.send("Error", resp))
        socket.onMessage( resp => self.send("Message", resp))
        socket.connect()

        return socket
    },


    /* connectionState/0

        Retrieve the current connection state and send it back to Elm as a String.

    */
    connectionState() { this.send("ConnectionState", socket.connectionState()) },


    /* disconnect/0

        Disconnect from the socket.

    */
    disconnect() {
        socket.disconnect()
    },


    /* endpoint/0

        Retrieve the current endpoint and send it back to Elm as a String.

    */
    endPointURL() { this.send("EndPointURL", socket.endPointURL()) },


    /* makeRef/0

        Retrieve the next message ref, accounting for overflows, and send it back to Elm as a String.

    */
    makeRef() { this.send("MakeRef", socket.makeRef()) },


    /* protocol/0

        Retrieve the current protocol and send it back to Elm as a String.

    */
    protocol() { this.send("Protocol", socket.protocol()) },


    /* isConnected/0

        Retrieve whether the socket is currently connected and send it back to Elm as a Bool.

    */
    isConnected() { this.send("IsConnected", socket.isConnected()) },


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
            this.send("HasLogger", socket.hasLogger())
        } else {
            // The function does not exist so send back null to signify we could not test for a logger.
            this.send("HasLogger", null)
        }
    },


    /* send/2

        Private function intended to determine the basic state of the socket, and send back the appropriate
        response to Elm.

                Parameters:
                    event <string> The event coming from the socket.
                    resp <object> The response received that gets sent to Elm.

    */
    send(event,resp) {
        switch(event) {
            case "Opened":

                // Allow the socket to keep trying to reconnect if it
                // drops out at any time now that the socket has
                // accepted the connection.
                allowReconnect = true

                Port.sendToSocket(event, resp)
                break

            case "Closed":
                if(allowReconnect) {

                    // The socket has closed unexpectedly after having been open,
                    // so we assume the closure was due to a drop in the network.
                    Port.sendToSocket("Error", {reason: "Unreachable"})
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

                    Port.sendToSocket("Error", {reason: "Denied"})
                }
                Port.sendToSocket(event, resp)
                break

            default:
                Port.sendToSocket(event, resp)
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
}

export default WebSocket



