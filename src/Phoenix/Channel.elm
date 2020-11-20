module Phoenix.Channel exposing
    ( Topic, Event, Payload, JoinConfig, PortOut, join
    , LeaveConfig, leave
    , push
    , PortIn, InternalError(..), Msg(..), subscriptions
    , on, allOn, off, allOff
    )

{-| This module can be used to talk directly to PhoenixJS without needing to
add anything to your Model. You can send and receive messages to and from your
Channels from anywhere in your Elm program. That is all it does and all it is
intended to do.

If you want more functionality, the top level [Phoenix](Phoenix#) module
takes care of a lot of the low level stuff such as automatically joining to
your Channels.


# Joining

@docs Topic, Event, Payload, JoinConfig, PortOut, join


# Leaving

@docs LeaveConfig, leave


# Pushing

@docs push


# Receiving

@docs PortIn, InternalError, Msg, subscriptions


# Incoming Events

These are events that are `push`ed or `broadcast` from your Elixir Channels. It
is necessary to set up the JS event listeners so that the events can be
captured and sent on to Elm. These functions turn those event listeners on and
off.

@docs on, allOn, off, allOff

-}

import Json.Decode as JD
import Json.Decode.Extra exposing (andMap)
import Json.Encode as JE exposing (Value)
import Json.Encode.Extra exposing (maybe)


{-| A type alias representing the Channel topic id. For example
`"topic:subTopic"`.
-}
type alias Topic =
    String


{-| A type alias representing an event sent to, or received from a Channel.
-}
type alias Event =
    String


{-| A type alias representing data that is sent to, or received from, a Channel.
-}
type alias Payload =
    Value


{-| A type alias representing the config for joining a Channel.

  - `topic` - The Channel topic id, for example: `"topic:subtopic"`.

  - `events` - A list of events to receive on the Channel.

  - `payload` - Data to be sent to the Channel when joining. If no data is
    required, set this to
    [Json.Encode.null](https://package.elm-lang.org/packages/elm/json/latest/Json-Encode#null).

  - `timeout` - Optional timeout, in ms, before retrying to join if the previous
    attempt failed.

-}
type alias JoinConfig =
    { topic : Topic
    , events : List Event
    , payload : Payload
    , timeout : Maybe Int
    }


{-| A type alias representing the `port` function required to send messages out
to the accompanying JS.

You will find this `port` function in the
[Port](https://github.com/phollyer/elm-phoenix-websocket/tree/master/ports)
module.

-}
type alias PortOut msg =
    { msg : String
    , payload : Value
    }
    -> Cmd msg


{-| Join a Channel.

    import Json.Encode as JE
    import Phoenix.Channel as Channel
    import Ports.Phoenix as Port

    Channel.join
        { topic = "topic:subtopic"
        , payload = JE.null
        , events = []
        , timeout = Nothing
        }
        Port.pheonixSend

-}
join : JoinConfig -> PortOut msg -> Cmd msg
join { topic, events, payload, timeout } portOut =
    portOut
        { msg = "join"
        , payload =
            JE.object
                [ ( "topic", JE.string topic )
                , ( "events", JE.list JE.string events )
                , ( "payload", payload )
                , ( "timeout", maybe JE.int timeout )
                ]
        }


{-| A type alias representing the config for leaving a Channel.

  - `topic` - The Channel topic id, for example: `"topic:subtopic"`.

  - `timeout` - Optional timeout, in ms, before retrying to leave if the
    previous attempt failed.

-}
type alias LeaveConfig =
    { topic : Topic
    , timeout : Maybe Int
    }


{-| Leave a Channel.

    import Phoenix.Channel as Channel
    import Ports.Phoenix as Port

    Channel.leave
        { topic = "topic:subtopic"
        , timeout = Nothing
        }
        Port.pheonixSend

-}
leave : LeaveConfig -> PortOut msg -> Cmd msg
leave { topic, timeout } portOut =
    portOut
        { msg = "leave"
        , payload =
            JE.object
                [ ( "topic", JE.string topic )
                , ( "timeout", maybe JE.int timeout )
                ]
        }


{-| Push to a Channel.

The optional `ref` is returned with the response to the Push so that you can
use it to identify the push later on if needed.

    import Json.Encode as JE
    import Phoenix.Channel as Channel
    import Ports.Phoenix as Port

    Channel.push
        { topic = "topic:subtopic"
        , event = "new_msg"
        , payload =
            JE.object
                [("msg", JE.string "Hello World")]
        , timeout = Nothing
        , ref = Nothing
        }
        Port.pheonixSend

-}
push : { a | topic : Topic, event : Event, payload : Payload, timeout : Maybe Int, ref : Maybe String } -> PortOut msg -> Cmd msg
push { topic, event, payload, timeout, ref } portOut =
    portOut
        { msg = "push"
        , payload =
            JE.object
                [ ( "topic", JE.string topic )
                , ( "event", JE.string event )
                , ( "payload", payload )
                , ( "timeout", maybe JE.int timeout )
                , ( "ref", maybe JE.string ref )
                ]
        }


{-| A type alias representing the `port` function required to receive
a [Msg](#Msg) from a Channel.

You will find this `port` function in the
[Port](https://github.com/phollyer/elm-phoenix-websocket/tree/master/ports)
module.

-}
type alias PortIn msg =
    ({ topic : Topic
     , msg : String
     , payload : JE.Value
     }
     -> msg
    )
    -> Sub msg


{-| An `InternalError` should never happen, but if it does, it is because the
JS is out of sync with this package.

If you ever receive this message, please
[raise an issue](https://github.com/phollyer/elm-phoenix-websocket/issues).

-}
type InternalError
    = DecoderError String
    | InvalidMessage Topic String Payload


{-| All of the messages you can receive from the Channel.

  - `Topic` - The Channel [Topic](#Topic) that the message came from.

  - `Event` - The original [Event](#Event) that was [push](#push)ed to the
    Channel.

  - `Payload` - The data received from the Channel, with the exception of
    `JoinTimout` and `PushTimeout` where it will be the original payload.

-}
type Msg
    = JoinOk Topic Payload
    | JoinError Topic Payload
    | JoinTimeout Topic Payload
    | PushOk Topic Event Payload String
    | PushError Topic Event Payload String
    | PushTimeout Topic Event Payload String
    | Message Topic Event Payload
    | Error Topic
    | LeaveOk Topic
    | Closed Topic
    | InternalError InternalError


{-| Subscribe to receive incoming Channel [Msg](#Msg)s.

    import Phoenix.Channel as Channel
    import Ports.Phoenix as Port

    type Msg
      = ChannelMsg Channel.Msg
      | ...


    subscriptions : Model -> Sub Msg
    subscriptions _ =
        Channel.subscriptions
            ChannelMsg
            Port.channelReceiver

-}
subscriptions : (Msg -> msg) -> PortIn msg -> Sub msg
subscriptions msg portIn =
    portIn (handleIn msg)


handleIn : (Msg -> msg) -> { topic : String, msg : String, payload : JE.Value } -> msg
handleIn toMsg { topic, msg, payload } =
    case msg of
        "JoinOk" ->
            toMsg (JoinOk topic payload)

        "JoinError" ->
            toMsg (JoinError topic payload)

        "JoinTimeout" ->
            toMsg (JoinTimeout topic payload)

        "PushOk" ->
            decodePushResponse toMsg topic PushOk payload

        "PushError" ->
            decodePushResponse toMsg topic PushError payload

        "PushTimeout" ->
            decodePushResponse toMsg topic PushTimeout payload

        "Message" ->
            decodeEvent toMsg topic Message payload

        "Error" ->
            toMsg (Error topic)

        "LeaveOk" ->
            toMsg (LeaveOk topic)

        "Closed" ->
            toMsg (Closed topic)

        _ ->
            toMsg (InternalError (InvalidMessage topic msg payload))



{- Incoming Events -}


{-| Switch an incoming event on.
-}
on : { topic : Topic, event : Event } -> PortOut msg -> Cmd msg
on { topic, event } portOut =
    portOut
        { msg = "on"
        , payload =
            JE.object
                [ ( "topic", JE.string topic )
                , ( "event", JE.string event )
                ]
        }


{-| Switch a list of incoming events on.
-}
allOn : { topic : Topic, events : List Event } -> PortOut msg -> Cmd msg
allOn { topic, events } portOut =
    portOut
        { msg = "allOn"
        , payload =
            JE.object
                [ ( "topic", JE.string topic )
                , ( "events", JE.list JE.string events )
                ]
        }


{-| Switch an incoming event off.
-}
off : { topic : Topic, event : Event } -> PortOut msg -> Cmd msg
off { topic, event } portOut =
    portOut
        { msg = "off"
        , payload =
            JE.object
                [ ( "topic", JE.string topic )
                , ( "event", JE.string event )
                ]
        }


{-| Switch a list of incoming events off.
-}
allOff : { topic : Topic, events : List Event } -> PortOut msg -> Cmd msg
allOff { topic, events } portOut =
    portOut
        { msg = "allOff"
        , payload =
            JE.object
                [ ( "topic", JE.string topic )
                , ( "events", JE.list JE.string events )
                ]
        }



{- Decoders -}


decodePushResponse : (Msg -> msg) -> Topic -> (Topic -> Event -> Payload -> String -> Msg) -> Value -> msg
decodePushResponse toMsg topic pushMsg payload =
    case JD.decodeValue pushDecoder payload of
        Ok push_ ->
            toMsg (pushMsg topic push_.event push_.payload push_.ref)

        Result.Err error ->
            toMsg (InternalError (DecoderError (JD.errorToString error)))


type alias PushResponse =
    { event : String
    , payload : Value
    , ref : String
    }


pushDecoder : JD.Decoder PushResponse
pushDecoder =
    JD.succeed
        PushResponse
        |> andMap (JD.field "event" JD.string)
        |> andMap (JD.field "payload" JD.value)
        |> andMap (JD.field "ref" JD.string)


decodeEvent : (Msg -> msg) -> Topic -> (Topic -> Event -> Payload -> Msg) -> Value -> msg
decodeEvent toMsg topic eventMsg payload =
    case JD.decodeValue eventDecoder payload of
        Ok event ->
            toMsg (eventMsg topic event.event event.payload)

        Result.Err error ->
            toMsg (InternalError (DecoderError (JD.errorToString error)))


type alias EventIn =
    { event : String
    , payload : Value
    }


eventDecoder : JD.Decoder EventIn
eventDecoder =
    JD.succeed
        EventIn
        |> andMap (JD.field "event" JD.string)
        |> andMap (JD.field "payload" JD.value)
