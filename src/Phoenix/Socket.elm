module Phoenix.Socket exposing
    ( send, EventOut(..)
    , PortOut, PackageOut
    , connectOptions
    , ConnectOptions
    , subscriptions, EventIn(..), MessageConfig
    , PortIn, PackageIn
    )

{-| This module is for working directly with the socket.

Once you have connected to the socket, you will then need to
[join a channel](Channel).


# Sending Messages

@docs send, EventOut

@docs PortOut, PackageOut


# Connecting With Options

This enables finer control over the socket if you want to adjust the default
settings.

@docs connectOptions

_Not all options are available on all versions of_
_[PhoenixJS](https://hexdocs.pm/phoenix/js), so check the docs at <https://hexdocs.pm/phoenix/{vesion}/js>_
_if something isn't working as expected._

And please raise an
[issue](https://github.com/phollyer/elm-phoenix-websocket/issues) if you find
that an option doesn't behave as it should.

@docs ConnectOptions


# Receiving Messages

@docs subscriptions, EventIn, MessageConfig

@docs PortIn, PackageIn

-}

import Json.Decode as JD
import Json.Decode.Extra exposing (andMap)
import Json.Encode as JE exposing (Value)
import Json.Encode.Extra exposing (maybe)



{- Sending And Receiving -}
-- Sending


{-| A type alias representing the data sent out through the `port` to the socket.
You will not use this directly.
-}
type alias PackageOut =
    { event : String
    , payload : JE.Value
    }


{-| A type alias representing the `port` function required to send the
[EventOut](#EventOut) to the socket.

You could write this yourself, if you do, it needs to be named
`sendMessage`, although you may find it simpler to just add
[this port module](https://github.com/phollyer/elm-phoenix-websocket/blob/master/src/Ports/Phoenix.elm)
to your `src` - it includes all the necessary `port` functions.

-}
type alias PortOut msg =
    PackageOut -> Cmd msg


{-| Send an [EventOut](#EventOut) to the socket.

    import Ports.Phoenix as Phx
    import Socket exposing (EventOut(..))

    -- Connect to the Socket

    Phx.sendMessage
      |> Socket.send
        (Connect Nothing)

    -- Disconnect from the Socket

    Phx.sendMessage
      |> Socket.send
        Disconnect

-}
send : EventOut -> PortOut msg -> Cmd msg
send msgOut portOut =
    case msgOut of
        Connect maybeValue ->
            case maybeValue of
                Just value ->
                    value
                        |> package
                            "connect"
                        |> portOut

                Nothing ->
                    JE.null
                        |> package
                            "connect"
                        |> portOut

        ConnectWithOptions options maybeValue ->
            maybeValue
                |> connectWithOptions
                    options
                |> package
                    "connect"
                |> portOut

        Disconnect ->
            JE.null
                |> package
                    "disconnect"
                |> portOut

        ConnectionState ->
            JE.null
                |> package
                    "connectionState"
                |> portOut

        IsConnected ->
            JE.null
                |> package
                    "isConnected"
                |> portOut

        EndPointURL ->
            JE.null
                |> package
                    "endPointURL"
                |> portOut

        HasLogger ->
            JE.null
                |> package
                    "hasLogger"
                |> portOut

        MakeRef ->
            JE.null
                |> package
                    "makeRef"
                |> portOut

        Protocol ->
            JE.null
                |> package
                    "protocol"
                |> portOut

        Log { kind, msg, data } ->
            [ ( "kind", JE.string kind )
            , ( "msg", JE.string msg )
            , ( "data", data )
            ]
                |> JE.object
                |> package
                    "log"
                |> portOut


package : String -> JE.Value -> PackageOut
package event value =
    { event = event
    , payload = value
    }



-- Connect With Options


{-| A helper function to return a [ConnectOptions](#ConnectOptions) record with
`Nothing` set on everything. Use it as a starting point for setting just the
options you want.

    { connectOptions | timeout = Just 10000 }

-}
connectOptions : ConnectOptions
connectOptions =
    { transport = Nothing
    , timeout = Nothing
    , heartbeatIntervalMs = Nothing
    , reconnectAfterMs = Nothing
    , reconnectMaxBackOff = Nothing
    , reconnectSteppedBackoff = Nothing
    , rejoinAfterMs = Nothing
    , rejoinMaxBackOff = Nothing
    , rejoinSteppedBackoff = Nothing
    , longpollerTimeout = Nothing
    , binaryType = Nothing
    }


{-| A type alias representing the options that can be set on the socket when
instantiating a `new Socket(url, options)` on the JS side.

See <https://hexdocs.pm/phoenix/js/#socket> for more info on the options and
the effect they have. All the option types are `Maybe`'s of the equivalent
JS types, with two exceptions:

1.  reconnectAfterMS
2.  rejoinAfterMs

On the JS side, these take an `Int` or a `function` that returns an `Int`. But
because we can't send functions through ports, you can set the `...MaxBackOff`
and `...SteppedBackOff` values as follows:

    { connectOptions
        | reconnectSteppedBackOff = [ 10, 20, 50, 100, 500 ]
        , reconnectMaxBackOff = 1000
    }

    { connectOptions
        | rejoinSteppedBackOff = [ 1000, 2000, 5000 ]
        , rejoinMaxBackOff = 10000
    }

On the JS side, this results in:

    { reconnectAfterMs: function(tries){ return [10, 20, 50, 100, 500][tries - 1] || 1000 }}

    { rejoinAfterMs: function(tries){ return [1000, 2000, 5000][tries - 1] || 10000 }}

-}
type alias ConnectOptions =
    { transport : Maybe String
    , timeout : Maybe Int
    , heartbeatIntervalMs : Maybe Int
    , reconnectAfterMs : Maybe Int
    , reconnectMaxBackOff : Maybe Int
    , reconnectSteppedBackoff : Maybe (List Int)
    , rejoinAfterMs : Maybe Int
    , rejoinMaxBackOff : Maybe Int
    , rejoinSteppedBackoff : Maybe (List Int)
    , longpollerTimeout : Maybe Int
    , binaryType : Maybe String
    }


connectWithOptions : ConnectOptions -> Maybe Value -> Value
connectWithOptions options maybeParams =
    let
        opts =
            List.filter
                (\( _, value ) -> value /= JE.null)
                [ ( "transport", maybe JE.string options.transport )
                , ( "timeout", maybe JE.int options.timeout )
                , ( "binaryType", maybe JE.string options.binaryType )
                , ( "heartbeatIntervalMs", maybe JE.int options.heartbeatIntervalMs )
                , ( "reconnectAfterMs", maybe JE.int options.reconnectAfterMs )
                , ( "reconnectMaxBackOff", maybe JE.int options.reconnectMaxBackOff )
                , ( "reconnectSteppedBackoff", maybe (JE.list JE.int) options.reconnectSteppedBackoff )
                , ( "rejoinAfterMs", maybe JE.int options.rejoinAfterMs )
                , ( "rejoinMaxBackOff", maybe JE.int options.rejoinMaxBackOff )
                , ( "rejoinSteppedBackoff", maybe (JE.list JE.int) options.rejoinSteppedBackoff )
                , ( "longpollerTimeout", maybe JE.int options.rejoinMaxBackOff )
                ]
    in
    JE.object
        [ ( "options", JE.object opts )
        , ( "params", Maybe.withDefault JE.null maybeParams )
        ]



-- Events


{-| All of the events you can send to the socket.

You will probably be most interested in `Connect`,
`ConnectWithOptions` and `Disconnect`.

Each of these [EventOut](#EventOut) messages corresponds to the equivalent function
in the [PhoenixJS API](https://hexdocs.pm/phoenix/js/index.html#socket). For
more info on these please read the API
[docs](https://hexdocs.pm/phoenix/js/index.html#socket).

-}
type EventOut
    = Connect (Maybe JE.Value)
    | ConnectWithOptions ConnectOptions (Maybe JE.Value)
    | Disconnect
    | ConnectionState
    | EndPointURL
    | HasLogger
    | IsConnected
    | MakeRef
    | Protocol
    | Log { kind : String, msg : String, data : JD.Value }



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
    portIn (handleIn msg)


handleIn : (EventIn -> msg) -> PackageIn -> msg
handleIn toMsg { event, payload } =
    case event of
        "Opened" ->
            toMsg Opened

        "Closed" ->
            toMsg Closed

        "Error" ->
            toMsg (Error (payload |> decodeError))

        "Message" ->
            toMsg (Message (payload |> decodeMessage))

        "ConnectionState" ->
            toMsg (ConnectionStateReply (payload |> decodeString))

        "EndPointURL" ->
            toMsg (EndPointURLReply (payload |> decodeString))

        "HasLogger" ->
            toMsg (HasLoggerReply (payload |> decodeMaybeBool))

        "IsConnected" ->
            toMsg (IsConnectedReply (payload |> decodeBool))

        "MakeRef" ->
            toMsg (MakeRefReply (payload |> decodeString))

        "Protocol" ->
            toMsg (ProtocolReply (payload |> decodeString))

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
    | Error String
    | Message MessageConfig
    | ConnectionStateReply String
    | EndPointURLReply String
    | HasLoggerReply (Maybe Bool)
    | IsConnectedReply Bool
    | MakeRefReply String
    | ProtocolReply String
    | InvalidEvent String


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


decodeString : Value -> String
decodeString value =
    value
        |> JD.decodeValue
            JD.string
        |> Result.toMaybe
        |> Maybe.withDefault ""


decodeBool : Value -> Bool
decodeBool value =
    value
        |> JD.decodeValue
            JD.bool
        |> Result.toMaybe
        |> Maybe.withDefault False


decodeMaybeBool : Value -> Maybe Bool
decodeMaybeBool value =
    value
        |> JD.decodeValue
            (JD.maybe
                JD.bool
            )
        |> Result.toMaybe
        |> Maybe.withDefault
            Nothing


decodeError : Value -> String
decodeError value =
    let
        defaults =
            [ JD.field "reason" JD.string
            , JD.field "error" JD.string
            , JD.string
            ]
    in
    case JD.decodeValue (JD.oneOf defaults) value of
        Ok v ->
            v

        Err e ->
            JD.errorToString e


decodeMessage : Value -> MessageConfig
decodeMessage value =
    let
        messageDecoder =
            JD.succeed
                MessageConfig
                |> andMap (JD.maybe (JD.field "join_ref" JD.string))
                |> andMap (JD.maybe (JD.field "ref" JD.string))
                |> andMap (JD.field "topic" JD.string)
                |> andMap (JD.field "event" JD.string)
                |> andMap (JD.field "payload" JD.value)
    in
    value
        |> JD.decodeValue
            messageDecoder
        |> Result.toMaybe
        |> Maybe.withDefault
            { joinRef = Nothing
            , ref = Nothing
            , topic = ""
            , event = ""
            , payload = JE.null
            }
