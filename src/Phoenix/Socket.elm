module Phoenix.Socket exposing
    ( ConnectOption(..), Params, PortOut, connect
    , disconnect
    , Msg(..), ClosedInfo, MessageConfig, AllInfo, Info(..), PortIn, subscriptions
    , connectionState, endPointURL, hasLogger, info, isConnected, makeRef, protocol
    , log, startLogging, stopLogging
    )

{-| Use this module to work directly with the socket.

After connecting to the socket, you can then join one or more
[channel](Phoenix.Channel)s and start sending and receiving messages to and from your
channel(s).


# Connecting

@docs ConnectOption, Params, PortOut, connect


# Disconnecting

@docs disconnect


# Receiving Messages

@docs Msg, ClosedInfo, MessageConfig, AllInfo, Info, PortIn, subscriptions


# Socket Information

@docs connectionState, endPointURL, hasLogger, info, isConnected, makeRef, protocol


# Logging

Here you can log data to the console, and activate and deactive the socket's
logger.

But be warned **there is no safeguard during compilation** such as you get when
you use `Debug.log`. Be sure to deactive the logging before you deploy to
production.

However, the ability to easily toggle logging on and off leads to a possible
use case where, in a deployed production environment, an admin is able to see
all the logging, while regular users do not.

@docs log, startLogging, stopLogging

-}

import Json.Decode as JD
import Json.Decode.Extra exposing (andMap)
import Json.Encode as JE exposing (Value)
import Json.Encode.Extra exposing (maybe)


{-| The options that can be set on the socket when instantiating a
`new Socket(url, options)` on the JS side.

See <https://hexdocs.pm/phoenix/js/#socket> for more info on the options and
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


{-| A type alias representing the `port` function required to communicate with
the accompanying JS.

You will find this `port` function in the
[Port](https://github.com/phollyer/elm-phoenix-websocket/tree/master/src/Ports)
module.

-}
type alias PortOut msg =
    { msg : String
    , payload : Value
    }
    -> Cmd msg


{-| Connect to the socket, providing any required
[ConnectOption](#ConnectOption)s and `Params` as well as the `port` function
to use.

    import Json.Encode as JE
    import Port
    import Socket

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
    let
        payload =
            encodeConnectOptionsAndParams options maybeParams
    in
    portOut { msg = "connect", payload = payload }


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


{-| Disconnect the socket.

The JS API provides for a callback function and additional params to be passed
in to the `disconnect` function. In the context of using Elm, this doesn't make
sense as there is nothing to callback to, and so this isn't supported.

If you need to callback to some other JS you have, you will need to edit the
accompanying JS file accordingly.

-}
disconnect : PortOut msg -> Cmd msg
disconnect portOut =
    portOut <|
        package "disconnect"



-- Receiving


{-| All of the messages you can receive from the socket.

The data each [Msg](#Msg) carries should be self explanatory,
except for maybe:

  - `HasLoggerReply` - not all versions of
    [PhoenixJS](https://hexdocs.pm/phoenix/js) have the `hasLogger` function.
    Therefore, a value of `Nothing` means the function does not exist and therefore
    could not be called, while a `Just` will carry the result of calling
    `hasLogger` on the socket.

  - `InvalidMsg` means that a message has been received from the accompanying JS
    that cannot be handled. This should not happen, if it does, please raise an
    [issue](https://github.com/phollyer/elm-phoenix-websocket/issues).

The `Error` in a `Result` is a `Json.Decode.Error`. These should not occur, but
will if the data received from the accompanying JS is of the wrong type, so I
decided to leave the `Error` to be handled by the user of the package, rather
than gloss over it with some kind of default.

-}
type Msg
    = Opened
    | Closed (Result JD.Error ClosedInfo)
    | Error (Result JD.Error String)
    | Message (Result JD.Error MessageConfig)
    | Info Info
    | InvalidMsg String


{-| -}
type Info
    = All (Result JD.Error AllInfo)
    | ConnectionState (Result JD.Error String)
    | EndPointURL (Result JD.Error String)
    | HasLogger (Result JD.Error (Maybe Bool))
    | IsConnected (Result JD.Error Bool)
    | MakeRef (Result JD.Error String)
    | Protocol (Result JD.Error String)


{-| A type alias representing the information received when the socket closes.
-}
type alias ClosedInfo =
    { reason : String
    , code : Int
    , wasClean : Bool
    }


{-| A type alias representing the raw message received by the socket. This
arrives as a [Msg](#Msg) `Message`.

You will need to decode `payload` yourself, as only you will know the structure
of this `Value`. It will be whatever data has been sent back from Phoenix
corresponding to `msg` so you will need to check this in order to select the
correct decoder if you are sending different structures for different `msg`s.

If you are using multiple channels, you will also need to check the `topic` to
identify the channel that sent the `msg`.

**NB** You won't need this if you choose to handle messages over
[Channel](Phoenix.Channel#Msg)s.

-}
type alias MessageConfig =
    { joinRef : Maybe String
    , ref : Maybe String
    , topic : String
    , event : String
    , payload : Value
    }


{-| All of the info available about the socket. This arrive as a
[Msg](#Msg) `InfoReply` and is the result of sending an `Info`
[InfoRequest](#InfoRequest).
-}
type alias AllInfo =
    { connectionState : String
    , endPointURL : String
    , hasLogger : Maybe Bool
    , isConnected : Bool
    , makeRef : String
    , protocol : String
    }


{-| A type alias representing the `port` function required to receive
the [Msg](#Msg) from the socket.

You will find this `port` function in the
[Port](https://github.com/phollyer/elm-phoenix-websocket/tree/master/src/Ports)
module.

-}
type alias PortIn msg =
    ({ msg : String
     , payload : JE.Value
     }
     -> msg
    )
    -> Sub msg


{-| Subscribe to receive incoming socket msgs.

    import Port
    import Socket

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
    portIn <|
        handleIn msg


handleIn : (Msg -> msg) -> { msg : String, payload : JE.Value } -> msg
handleIn toMsg { msg, payload } =
    case msg of
        "Opened" ->
            toMsg Opened

        "Closed" ->
            toMsg <|
                Closed
                    (JD.decodeValue closedDecoder payload)

        "Error" ->
            toMsg <|
                Error
                    (JD.decodeValue errorDecoder payload)

        "Message" ->
            toMsg <|
                Message
                    (JD.decodeValue messageDecoder payload)

        "ConnectionState" ->
            toMsg <|
                Info <|
                    ConnectionState
                        (JD.decodeValue JD.string payload)

        "EndPointURL" ->
            toMsg <|
                Info <|
                    EndPointURL
                        (JD.decodeValue JD.string payload)

        "HasLogger" ->
            toMsg <|
                Info <|
                    HasLogger
                        (JD.decodeValue (JD.maybe JD.bool) payload)

        "Info" ->
            toMsg <|
                Info <|
                    All
                        (JD.decodeValue infoDecoder payload)

        "IsConnected" ->
            toMsg <|
                Info <|
                    IsConnected
                        (JD.decodeValue JD.bool payload)

        "MakeRef" ->
            toMsg <|
                Info <|
                    MakeRef
                        (JD.decodeValue JD.string payload)

        "Protocol" ->
            toMsg <|
                Info <|
                    Protocol
                        (JD.decodeValue JD.string payload)

        _ ->
            toMsg (InvalidMsg msg)



-- Decoders


closedDecoder : JD.Decoder ClosedInfo
closedDecoder =
    JD.succeed
        ClosedInfo
        |> andMap (JD.field "reason" JD.string)
        |> andMap (JD.field "code" JD.int)
        |> andMap (JD.field "wasClean" JD.bool)


errorDecoder : JD.Decoder String
errorDecoder =
    JD.oneOf
        [ JD.field "reason" JD.string
        , JD.field "error" JD.string
        , JD.string
        ]


infoDecoder : JD.Decoder AllInfo
infoDecoder =
    JD.succeed
        AllInfo
        |> andMap (JD.field "connectionState" JD.string)
        |> andMap (JD.field "endPointURL" JD.string)
        |> andMap (JD.field "hasLogger" (JD.maybe JD.bool))
        |> andMap (JD.field "isConnected" JD.bool)
        |> andMap (JD.field "nextMessageRef" JD.string)
        |> andMap (JD.field "protocol" JD.string)


messageDecoder : JD.Decoder MessageConfig
messageDecoder =
    JD.succeed
        MessageConfig
        |> andMap (JD.maybe (JD.field "join_ref" JD.string))
        |> andMap (JD.maybe (JD.field "ref" JD.string))
        |> andMap (JD.field "topic" JD.string)
        |> andMap (JD.field "event" JD.string)
        |> andMap (JD.field "payload" JD.value)



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
hasLogger : PortOut msg -> Cmd msg
hasLogger portOut =
    portOut (package "hasLogger")


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


package : String -> { msg : String, payload : JE.Value }
package msg =
    { msg = msg
    , payload = JE.null
    }



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
socket's logger. There are two ways to do this. You can use the
[startLogging](#startLogging) function, or you can pass the `Logger True`
[ConnectOption](#Phoenix.Socket#ConnectOption) to the [connect](#connect)
function.

    import Ports.Phoenix as Port

    connect [ Logger True ] Nothing Port.phoenixSend

-}
log : String -> String -> Value -> PortOut msg -> Cmd msg
log kind msg data portOut =
    portOut <|
        { msg = "log"
        , payload =
            JE.object
                [ ( "kind", JE.string kind )
                , ( "msg", JE.string msg )
                , ( "data", data )
                ]
        }


{-| Activate the socket's logger function. This will log all messages that the
socket sends and receives.
-}
startLogging : PortOut msg -> Cmd msg
startLogging portOut =
    portOut (package "startLogging")


{-| Deactivate the socket's logger function.
-}
stopLogging : PortOut msg -> Cmd msg
stopLogging portOut =
    portOut (package "stopLogging")
