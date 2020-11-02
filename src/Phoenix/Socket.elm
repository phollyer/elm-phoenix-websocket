module Phoenix.Socket exposing
    ( ConnectOption(..), Params, PortOut, connect
    , disconnect
    , ClosedInfo, Topic, Event, Payload, ChannelMessage, PresenceMessage, HeartbeatMessage, AllInfo, Info(..), InternalError(..), Msg(..), PortIn, subscriptions
    , connectionState, endPointURL, info, isConnected, makeRef, protocol
    , allMessagesOn, allMessagesOff
    , channelMessagesOn, channelMessagesOff
    , presenceMessagesOn, presenceMessagesOff
    , heartbeatMessagesOn, heartbeatMessagesOff
    , log, startLogging, stopLogging
    )

{-| This module can be used to talk directly to PhoenixJS without needing to
add anything to your Model. You can send and receive messages to and from the
JS Socket from anywhere in your Elm program. That is all it does and all it is
intended to do.

If you want more functionality, the top level [Phoenix](Phoenix#) module
takes care of a lot of the low level stuff such as automatically connecting to
the Socket.


# Connecting

@docs ConnectOption, Params, PortOut, connect


# Disconnecting

@docs disconnect


# Receiving Messages

@docs ClosedInfo, Topic, Event, Payload, ChannelMessage, PresenceMessage, HeartbeatMessage, AllInfo, Info, InternalError, Msg, PortIn, subscriptions


# Socket Information

Request information about the Socket.

@docs connectionState, endPointURL, info, isConnected, makeRef, protocol


# Message Control

These functions enable control over what messages the PhoenixJS `onMessage`
handler forwards on to Elm.

@docs allMessagesOn, allMessagesOff

@docs channelMessagesOn, channelMessagesOff

@docs presenceMessagesOn, presenceMessagesOff

@docs heartbeatMessagesOn, heartbeatMessagesOff


# Logging

Here you can log data to the console, and activate and deactive the socket's
logger, but be warned, **there is no safeguard when you compile** such as you
get when you use `Debug.log`. Be sure to deactive the logging before you deploy
to production.

However, the ability to easily toggle logging on and off leads to a possible
use case where, in a deployed production environment, an admin is able to see
all the logging, while regular users do not.

@docs log, startLogging, stopLogging

-}

import Json.Decode as JD
import Json.Decode.Extra exposing (andMap)
import Json.Encode as JE exposing (Value)
import Json.Encode.Extra exposing (maybe)


{-| The options that can be set on the Socket when instantiating a
`new Socket(url, options)` on the JS side.

See <https://hexdocs.pm/phoenix/js/#Socket> for more info on the options and
the effect they have.

However, there are two potential instances where we have to work around the
inability to send functions through `ports`. This is if you wish to employ a
backoff strategy that increases the time interval between repeated attempts to
reconnect or rejoin.

To do this on the JS side, you would provide a function that returns an `Int`.
But because we can't send functions through ports, the way to create these
functions is to also use the `...SteppedBackoff` counterparts:

    [ ReconnectAfterMillis 1000
    , ReconnectSteppedBackoff [ 10, 20, 50, 100, 500 ]
    , RejoinAfterMillis 10000
    , RejoinSteppedBackoff [ 1000, 2000, 5000 ]
    ]

On the JS side, the above options result in:

    { reconnectAfterMs: function(tries){ return [10, 20, 50, 100, 500][tries - 1] || 1000 },
      rejoinAfterMs: function(tries){ return [1000, 2000, 5000][tries - 1] || 10000 }
    }

For a consistent time interval simply ignore the `...SteppedBackoff` options:

    [ ReconnectAfterMillis 1000
    , RejoinAfterMillis 10000
    ]

-}
type ConnectOption
    = BinaryType String
    | HeartbeatIntervalMillis Int
    | Logger Bool
    | LongpollerTimeout Int
    | ReconnectAfterMillis Int
    | ReconnectSteppedBackoff (List Int)
    | RejoinAfterMillis Int
    | RejoinSteppedBackoff (List Int)
    | Timeout Int
    | Transport String
    | Vsn String


{-| A type alias repesenting the params to be sent when connecting, such as
authentication params like username and password.
-}
type alias Params =
    Value


{-| A type alias representing the `port` function required to send messages out
to the accompanying JS.

You will find this `port` function in the
[Port](https://github.com/phollyer/elm-phoenix-webSocket/tree/master/ports)
module.

-}
type alias PortOut msg =
    { msg : String
    , payload : Value
    }
    -> Cmd msg


{-| Connect to the Socket, providing any required
[ConnectOption](#ConnectOption)s and `Params` as well as the `port` function
to use.

    import Json.Encode as JE
    import Phoenix.Socket as Socket
    import Ports.Phoenix as Port

    -- A simple connection

    Socket.connect [] Nothing Port.phoenixSend

    -- A connection with options and auth params

    options =
        [ Socket.HeartbeatIntervalMillis 500
        , Socket.Timeout 10000
        ]

    params =
        JE.object
            [ ("username", JE.string "Joe Bloggs")
            , ("password", JE.string "password")
            ]

    Socket.connect options (Just params) Port.phoenixSend

-}
connect : List ConnectOption -> Maybe Params -> PortOut msg -> Cmd msg
connect options maybeParams portOut =
    portOut
        { msg = "connect"
        , payload =
            encodeConnectOptionsAndParams options maybeParams
        }


encodeConnectOptionsAndParams : List ConnectOption -> Maybe Value -> Value
encodeConnectOptionsAndParams options maybeParams =
    JE.object
        [ ( "options"
          , JE.object <|
                List.map encodeConnectOption options
          )
        , ( "params", Maybe.withDefault JE.null maybeParams )
        ]


encodeConnectOption : ConnectOption -> ( String, Value )
encodeConnectOption option =
    case option of
        BinaryType binaryType ->
            ( "binaryType", JE.string binaryType )

        HeartbeatIntervalMillis interval ->
            ( "heartbeatIntervalMs", JE.int interval )

        Logger use ->
            ( "logger", JE.bool use )

        LongpollerTimeout timeout ->
            ( "longpollerTimeout", JE.int timeout )

        ReconnectAfterMillis millis ->
            ( "reconnectAfterMs", JE.int millis )

        ReconnectSteppedBackoff list ->
            ( "reconnectSteppedBackoff", JE.list JE.int list )

        RejoinAfterMillis millis ->
            ( "rejoinAfterMs", JE.int millis )

        RejoinSteppedBackoff list ->
            ( "rejoinSteppedBackoff", JE.list JE.int list )

        Timeout millis ->
            ( "timeout", JE.int millis )

        Transport transport ->
            ( "transport", JE.string transport )

        Vsn vsn ->
            ( "vsn", JE.string vsn )


{-| Disconnect the Socket, maybe providing a status
[code](https://developer.mozilla.org/en-US/docs/Web/API/CloseEvent#Status_codes)
for the closure.
-}
disconnect : Maybe Int -> PortOut msg -> Cmd msg
disconnect code portOut =
    portOut
        { msg = "disconnect"
        , payload =
            JE.object
                [ ( "code", maybe JE.int code ) ]
        }



-- Receiving


{-| A type alias representing the information received when the Socket closes.
-}
type alias ClosedInfo =
    { reason : Maybe String
    , code : Int
    , wasClean : Bool
    , type_ : String
    , isTrusted : Bool
    }


{-| A type alias representing the Channel topic id. For example
`"topic:subTopic"`.
-}
type alias Topic =
    String


{-| A type alias representing an event received from a Channel.
-}
type alias Event =
    String


{-| A type alias representing data that is received from a Channel.
-}
type alias Payload =
    Value


{-| A type alias representing a raw Channel message received by the Socket.
-}
type alias ChannelMessage =
    { topic : Topic
    , event : Event
    , payload : Payload
    , joinRef : Maybe String
    , ref : Maybe String
    }


{-| A type alias representing a raw Presence message received by the Socket.
-}
type alias PresenceMessage =
    { topic : Topic
    , event : Event
    , payload : Payload
    }


{-| A type alias representing a raw Heartbeat received by the Socket.
-}
type alias HeartbeatMessage =
    { topic : Topic
    , event : Event
    , payload : Payload
    , ref : String
    }


{-| A type alias representing all of the info available about the Socket.
-}
type alias AllInfo =
    { connectionState : String
    , endPointURL : String
    , isConnected : Bool
    , makeRef : String
    , protocol : String
    }


{-| Information received about the Socket.
-}
type Info
    = All AllInfo
    | ConnectionState String
    | EndPointURL String
    | IsConnected Bool
    | MakeRef String
    | Protocol String


{-| An `InternalError` should never happen, but if it does, it is because the
JS is out of sync with this package.

If you ever receive this message, please
[raise an issue](https://github.com/phollyer/elm-phoenix-websocket/issues).

-}
type InternalError
    = DecoderError String
    | InvalidMessage String


{-| All of the messages you can receive from the Socket.
-}
type Msg
    = Opened
    | Closed ClosedInfo
    | Error String
    | Channel ChannelMessage
    | Presence PresenceMessage
    | Heartbeat HeartbeatMessage
    | Info Info
    | InternalError InternalError


{-| A type alias representing the `port` function required to receive
a [Msg](#Msg) from the Socket.

You will find this `port` function in the
[Port](https://github.com/phollyer/elm-phoenix-webSocket/tree/master/ports)
module.

-}
type alias PortIn msg =
    ({ msg : String
     , payload : Value
     }
     -> msg
    )
    -> Sub msg


{-| Subscribe to receive incoming Socket messages.

    import Phoenix.Socket as Socket
    import Ports.Phoenix as Port

    type Msg
      = SocketMsg Socket.Msg
      | ...


    subscriptions : Model -> Sub Msg
    subscriptions _ =
        Socket.subscriptions
            SocketMsg
            Port.socketReceiver

-}
subscriptions : (Msg -> msg) -> PortIn msg -> Sub msg
subscriptions msg portIn =
    portIn (handleMessage msg)


handleMessage : (Msg -> msg) -> { msg : String, payload : Value } -> msg
handleMessage toMsg { msg, payload } =
    case msg of
        "Opened" ->
            toMsg Opened

        "Error" ->
            decodeError toMsg payload

        "Closed" ->
            decodeClosed toMsg payload

        "Channel" ->
            decodeMessage toMsg Channel channelDecoder payload

        "Presence" ->
            decodeMessage toMsg Presence presenceDecoder payload

        "Heartbeat" ->
            decodeMessage toMsg Heartbeat heartbeatDecoder payload

        "ConnectionState" ->
            decodeInfo toMsg ConnectionState JD.string payload

        "EndPointURL" ->
            decodeInfo toMsg EndPointURL JD.string payload

        "Info" ->
            decodeInfo toMsg All infoDecoder payload

        "IsConnected" ->
            decodeInfo toMsg IsConnected JD.bool payload

        "MakeRef" ->
            decodeInfo toMsg MakeRef JD.string payload

        "Protocol" ->
            decodeInfo toMsg Protocol JD.string payload

        _ ->
            toMsg (InternalError (InvalidMessage msg))



{- Socket Information -}


{-| -}
connectionState : PortOut msg -> Cmd msg
connectionState portOut =
    portOut (package "connectionState")


{-| -}
endPointURL : PortOut msg -> Cmd msg
endPointURL portOut =
    portOut (package "endPointURL")


{-| -}
info : PortOut msg -> Cmd msg
info portOut =
    portOut (package "info")


{-| -}
isConnected : PortOut msg -> Cmd msg
isConnected portOut =
    portOut (package "isConnected")


{-| -}
makeRef : PortOut msg -> Cmd msg
makeRef portOut =
    portOut (package "makeRef")


{-| -}
protocol : PortOut msg -> Cmd msg
protocol portOut =
    portOut (package "protocol")


package : String -> { msg : String, payload : Value }
package msg =
    { msg = msg
    , payload = JE.null
    }



{- Message Control -}


{-| -}
allMessagesOn : PortOut msg -> Cmd msg
allMessagesOn portOut =
    portOut (package "allMessagesOn")


{-| -}
allMessagesOff : PortOut msg -> Cmd msg
allMessagesOff portOut =
    portOut (package "allMessagesOff")


{-| -}
channelMessagesOn : PortOut msg -> Cmd msg
channelMessagesOn portOut =
    portOut (package "channelMessagesOn")


{-| -}
channelMessagesOff : PortOut msg -> Cmd msg
channelMessagesOff portOut =
    portOut (package "channelMessagesOff")


{-| -}
presenceMessagesOn : PortOut msg -> Cmd msg
presenceMessagesOn portOut =
    portOut (package "presenceMessagesOn")


{-| -}
presenceMessagesOff : PortOut msg -> Cmd msg
presenceMessagesOff portOut =
    portOut (package "presenceMessagesOff")


{-| -}
heartbeatMessagesOn : PortOut msg -> Cmd msg
heartbeatMessagesOn portOut =
    portOut (package "heartbeatMessagesOn")


{-| -}
heartbeatMessagesOff : PortOut msg -> Cmd msg
heartbeatMessagesOff portOut =
    portOut (package "heartbeatMessagesOff")



{- Logging -}


{-| Log some data to the console.

    import Json.Encode as JE
    import Ports.Phoenix as Port

    log "info" "foo"
        (JE.object
            [ ( "bar", JE.string "foo bar" ) ]
        )
        port.phoenixSend

    -- info: foo {bar: "foo bar"}

In order to receive any output in the console, you first need to activate the
Socket's logger. There are two ways to do this. You can use the
[startLogging](#startLogging) function, or you can pass the `Logger True`
[ConnectOption](#Phoenix.Socket#ConnectOption) to the [connect](#connect)
function.

    import Ports.Phoenix as Port

    connect [ Logger True ] Nothing Port.phoenixSend

-}
log : String -> String -> Value -> PortOut msg -> Cmd msg
log kind msg data portOut =
    portOut
        { msg = "log"
        , payload =
            JE.object
                [ ( "kind", JE.string kind )
                , ( "msg", JE.string msg )
                , ( "data", data )
                ]
        }


{-| Activate the Socket's logger function. This will log all messages that the
Socket sends and receives.
-}
startLogging : PortOut msg -> Cmd msg
startLogging portOut =
    portOut (package "startLogging")


{-| Deactivate the Socket's logger function.
-}
stopLogging : PortOut msg -> Cmd msg
stopLogging portOut =
    portOut (package "stopLogging")



{- Decoders -}


decodeClosed : (Msg -> msg) -> Value -> msg
decodeClosed toMsg payload =
    case JD.decodeValue closedDecoder payload of
        Ok closed ->
            toMsg (Closed closed)

        Result.Err error ->
            toMsg (InternalError (DecoderError (JD.errorToString error)))


closedDecoder : JD.Decoder ClosedInfo
closedDecoder =
    JD.succeed
        ClosedInfo
        |> andMap
            (JD.maybe (JD.field "reason" JD.string)
                |> JD.andThen
                    (\reason ->
                        case reason of
                            Just "" ->
                                JD.succeed Nothing

                            _ ->
                                JD.succeed reason
                    )
            )
        |> andMap (JD.field "code" JD.int)
        |> andMap (JD.field "wasClean" JD.bool)
        |> andMap (JD.field "type" JD.string)
        |> andMap (JD.field "isTrusted" JD.bool)


errorDecoder : JD.Decoder String
errorDecoder =
    JD.succeed
        identity
        |> andMap (JD.field "reason" JD.string)


decodeError : (Msg -> msg) -> Value -> msg
decodeError toMsg payload =
    case JD.decodeValue errorDecoder payload of
        Ok reason ->
            toMsg (Error reason)

        Err error ->
            toMsg (InternalError (DecoderError (JD.errorToString error)))


decodeInfo : (Msg -> msg) -> (a -> Info) -> JD.Decoder a -> Value -> msg
decodeInfo toMsg okMsg decoder payload =
    case JD.decodeValue decoder payload of
        Ok val ->
            toMsg (Info (okMsg val))

        Err error ->
            toMsg (InternalError (DecoderError (JD.errorToString error)))


infoDecoder : JD.Decoder AllInfo
infoDecoder =
    JD.succeed
        AllInfo
        |> andMap (JD.field "connectionState" JD.string)
        |> andMap (JD.field "endPointURL" JD.string)
        |> andMap (JD.field "isConnected" JD.bool)
        |> andMap (JD.field "nextMessageRef" JD.string)
        |> andMap (JD.field "protocol" JD.string)


decodeMessage : (Msg -> msg) -> (a -> Msg) -> JD.Decoder a -> Value -> msg
decodeMessage toMsg okMsg decoder payload =
    case JD.decodeValue decoder payload of
        Ok message ->
            toMsg (okMsg message)

        Result.Err error ->
            toMsg (InternalError (DecoderError (JD.errorToString error)))


channelDecoder : JD.Decoder ChannelMessage
channelDecoder =
    JD.succeed
        ChannelMessage
        |> andMap (JD.field "topic" JD.string)
        |> andMap (JD.field "event" JD.string)
        |> andMap (JD.field "payload" JD.value)
        |> andMap (JD.maybe (JD.field "join_ref" JD.string))
        |> andMap (JD.maybe (JD.field "ref" JD.string))


presenceDecoder : JD.Decoder PresenceMessage
presenceDecoder =
    JD.succeed
        PresenceMessage
        |> andMap (JD.field "topic" JD.string)
        |> andMap (JD.field "event" JD.string)
        |> andMap (JD.field "payload" JD.value)


heartbeatDecoder : JD.Decoder HeartbeatMessage
heartbeatDecoder =
    JD.succeed
        HeartbeatMessage
        |> andMap (JD.field "topic" JD.string)
        |> andMap (JD.field "event" JD.string)
        |> andMap (JD.field "payload" JD.value)
        |> andMap (JD.field "ref" JD.string)
