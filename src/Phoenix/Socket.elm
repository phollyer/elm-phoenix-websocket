module Phoenix.Socket exposing
    ( ConnectOption(..), Params, PortOut, connect
    , disconnect
    , MsgOut(..), send
    , subscriptions, EventIn(..), MessageConfig
    , PortIn, PackageIn
    )

{-| Use this module to work directly with the socket.

After connecting to the socket, you can then [join a channel](Channel) and
start sending and receiving messages from your channels.


# Connecting

@docs ConnectOption, Params, PortOut, connect


# Disconnecting

@docs disconnect


# Sending Messages

@docs MsgOut, send


# Receiving Messages

@docs subscriptions, EventIn, MessageConfig

@docs PortIn, PackageIn

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

On the JS side, this results in:

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
    | LongpollerTimeout Int
    | ReconnectAfterMillis Int
    | ReconnectSteppedBackoff (List Int)
    | RejoinAfterMillis Int
    | RejoinSteppedBackoff (List Int)
    | Timeout Int
    | Transport String


{-| A type alias repesenting the params to be sent when connecting, usually
authentication params such as username and password.
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
    { event : String
    , payload : Value
    }
    -> Cmd msg


{-| Connect to the socket, providing any required
[ConnectOption](#ConnectOption)s and `Params` as well as the `port` function
to use.

    import Json.Encode as JE
    import Port

    -- A simple connection

    connect [] Nothing Port.phoenixSend

    -- A connection with options and auth params

    options =
        [ HeartbeatIntervalMillis 500
        , Timeout 10000
        ]

    params =
        JE.object
            [ ("username", JE.string "Joe Bloggs")
            , ("password", JE.string "password")
            ]

    connect options (Just params) Port.phoenixSend

-}
connect : List ConnectOption -> Maybe Params -> PortOut msg -> Cmd msg
connect options maybeParams portOut =
    let
        payload =
            encodeConnectOptionsAndParams options maybeParams
    in
    portOut <|
        package "connect" (Just payload)


{-| Disconnect the socket.

The JS API provides for a callback function and additional params to be passed
in to the `disconnect` function. In the context of using Elm, this doesn't make
sense as there is nothing to callback to, and so this isn't supported.

If you need to callback to some other JS you have, you will need to adjust the
accompanying JS file accordingly.

-}
disconnect : PortOut msg -> Cmd msg
disconnect portOut =
    portOut <|
        package "disconnect" Nothing


{-| All of the messages you can send to the socket.

These messages correspond to the instance members of the socket as described
[here](https://hexdocs.pm/phoenix/js/index.html#socket), with the exception of
`Info`.

Sending the `Info` message will request all of the following in a single
request and their results will come back in a single response.

  - `ConnectionState`
  - `EndPointURL`
  - `HasLogger`
  - `IsConnected`
  - `MakeRef`
  - `Protocol`

Currently, the following JS instance members are not supported:

  - `off(refs, null-null)`
  - `channel(topic, chanParams)`
  - `push(data)`

-}
type MsgOut
    = ConnectionState
    | EndPointURL
    | HasLogger
    | Info
    | IsConnected
    | MakeRef
    | Protocol
    | Log { kind : String, msg : String, data : JD.Value }


{-| Send a [MsgOut](#MsgOut) to the socket.

    import Port

    send Info Port.phoenixSend

-}
send : MsgOut -> PortOut msg -> Cmd msg
send msgOut portOut =
    case msgOut of
        ConnectionState ->
            portOut <|
                package "connectionState" Nothing

        Info ->
            portOut <|
                package "info" Nothing

        IsConnected ->
            portOut <|
                package "isConnected" Nothing

        EndPointURL ->
            portOut <|
                package "endPointURL" Nothing

        HasLogger ->
            portOut <|
                package "hasLogger" Nothing

        MakeRef ->
            portOut <|
                package "makeRef" Nothing

        Protocol ->
            portOut <|
                package "protocol" Nothing

        Log { kind, msg, data } ->
            let
                payload =
                    JE.object
                        [ ( "kind", JE.string kind )
                        , ( "msg", JE.string msg )
                        , ( "data", data )
                        ]
            in
            portOut <|
                package "log" (Just payload)


package : String -> Maybe JE.Value -> { event : String, payload : JE.Value }
package event maybePayload =
    case maybePayload of
        Just payload ->
            { event = event
            , payload = payload
            }

        Nothing ->
            { event = event
            , payload = JE.null
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



-- Receiving


{-| A type alias representing the data received from the socket. You will not
use this directly.
-}
type alias PackageIn =
    { event : String
    , payload : JE.Value
    }


{-| A type alias representing the `port` function required to receive
the [EventIn](#EventIn) from the socket.

You could write this yourself, if you do, it needs to be named
`socketReceiver`, although you may find it simpler to just add
[this port module](https://github.com/phollyer/elm-phoenix-websocket/blob/master/src/Ports/Phoenix.elm)
to your `src` - it includes all the necessary `port` functions.

-}
type alias PortIn msg =
    (PackageIn -> msg) -> Sub msg


{-| Subscribe to receive incoming socket events.

    import Ports.Phoenix as Phx
    import Socket

    type Msg
      = SocketMsg Socket.EventIn
      | ...


    subscriptions : Model -> Sub Msg
    subscriptions _ =
        Phx.socketReceiver
          |> Socket.subscriptions
            SocketMsg

-}
subscriptions : (EventIn -> msg) -> PortIn msg -> Sub msg
subscriptions msg portIn =
    portIn <|
        handleIn msg


handleIn : (EventIn -> msg) -> PackageIn -> msg
handleIn toMsg { event, payload } =
    case event of
        "Opened" ->
            toMsg Opened

        "Closed" ->
            toMsg Closed

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
                ConnectionStateReply
                    (JD.decodeValue JD.string payload)

        "EndPointURL" ->
            toMsg <|
                EndPointURLReply
                    (JD.decodeValue JD.string payload)

        "HasLogger" ->
            toMsg <|
                HasLoggerReply
                    (JD.decodeValue (JD.maybe JD.bool) payload)

        "Info" ->
            toMsg <|
                InfoReply
                    (JD.decodeValue infoDecoder payload)

        "IsConnected" ->
            toMsg <|
                IsConnectedReply
                    (JD.decodeValue JD.bool payload)

        "MakeRef" ->
            toMsg <|
                MakeRefReply
                    (JD.decodeValue JD.string payload)

        "Protocol" ->
            toMsg <|
                ProtocolReply
                    (JD.decodeValue JD.string payload)

        _ ->
            toMsg (InvalidEvent event)


{-| All of the events you can receive from the socket.

You will probably be most interested in `Opened`,
`Closed` and `Error`.

The data each [EventIn](#EventIn) carries should be self explanatory,
except for maybe:

`HasLoggerReply` - not all versions of
[PhoenixJS](https://hexdocs.pm/phoenix/js) have the `hasLogger` function.
Therefore, a value of `Nothing` means the function does not exist, while a
`Just` will carry the result of calling `hasLogger` on the socket.

`InvalidEvent` means that an event has been received from the accompanying JS
that cannot be handled. This should not happen, if it does, please raise an
[issue](https://github.com/phollyer/elm-phoenix-websocket/issues).

-}
type EventIn
    = Opened
    | Closed
    | Error (Result JD.Error String)
    | Message (Result JD.Error MessageConfig)
    | ConnectionStateReply (Result JD.Error String)
    | EndPointURLReply (Result JD.Error String)
    | HasLoggerReply (Result JD.Error (Maybe Bool))
    | InfoReply (Result JD.Error InfoData)
    | IsConnectedReply (Result JD.Error Bool)
    | MakeRefReply (Result JD.Error String)
    | ProtocolReply (Result JD.Error String)
    | InvalidEvent String


type alias InfoData =
    { connectionState : String
    , endpointURL : String
    , hasLogger : Maybe Bool
    , isConnected : Bool
    , nextMessageRef : String
    , protocol : String
    }


{-| A type alias representing the raw message received by the socket. This
arrives as an [EventIn](#EventIn) `Message`.

You will need to decode `payload` yourself, as only you will know the structure
of this `Value`. It will be whatever data has been sent back from Phoenix
corresponding to `event` so you will need to check this in order to select the
correct decoder if you are sending different structures for different `event`s.

If you are using multiple channels, you will also need to check the `topic` to
identify the channel that sent the `event`.

You won't need this if you choose to handle messages over
[Channel](Channel#MsgIn)s.

-}
type alias MessageConfig =
    { joinRef : Maybe String
    , ref : Maybe String
    , topic : String
    , event : String
    , payload : Value
    }



-- Decoders


errorDecoder : JD.Decoder String
errorDecoder =
    JD.oneOf
        [ JD.field "reason" JD.string
        , JD.field "error" JD.string
        , JD.string
        ]


infoDecoder : JD.Decoder InfoData
infoDecoder =
    JD.succeed
        InfoData
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
