module Phoenix.Channel exposing
    ( send, EventOut(..), JoinConfig, PushConfig, EventConfig, LeaveConfig
    , PortOut, PackageOut
    , subscriptions, EventIn(..), Topic, PushEvent
    , PortIn, PackageIn
    , eventsOn, eventsOff
    )

{-| This module is for working directly with channels.

Before you can join a channel and start sending and receiving, you first need
to [connect to a socket](Socket).


# Sending Messages

@docs send, EventOut, JoinConfig, PushConfig, EventConfig, LeaveConfig

@docs PortOut, PackageOut


# Receiving Messages

@docs subscriptions, EventIn, Topic, PushEvent

@docs PortIn, PackageIn


# Helpers

@docs eventsOn, eventsOff

-}

import Json.Decode as JD
import Json.Encode as JE exposing (Value)



{- Sending And Receiving -}
-- Sending


{-| Send an [EventOut](#EventOut) to the channel.

    import Channel exposing (EventOut(..))
    import Ports.Phoenix as Phx

    -- Join a Channel

    Phx.sendMessage
      |> Channel.send
        (Join
          { topic = "topic:subtopic"
          , timeout = Nothing
          , payload = Nothing
          }
        )

    -- Push some data to a Channel

    import Json.Encode as JE

    Phx.sendMessage
      |> Channel.send
        (Push
          { topic = Just "topic:subtopic"
          , event = "send_msg"
          , timeout = Nothing
          , data =
              JE.object
                [ ("msg", "Hello to everyone!" |> JE.string) ]
          }

-}
send : EventOut -> PortOut msg -> Cmd msg
send msgOut portOut =
    case msgOut of
        Join { topic, timeout, payload } ->
            [ ( "topic", JE.string topic )
            , ( "timeout"
              , case timeout of
                    Just t ->
                        JE.int t

                    Nothing ->
                        JE.null
              )
            , ( "payload"
              , case payload of
                    Just data ->
                        data

                    Nothing ->
                        JE.null
              )
            ]
                |> JE.object
                |> package
                    "join"
                |> portOut

        Push { topic, event, timeout, payload } ->
            [ ( "topic"
              , case topic of
                    Just t ->
                        JE.string t

                    Nothing ->
                        JE.null
              )
            , ( "event", JE.string event )
            , ( "timeout"
              , case timeout of
                    Just t ->
                        JE.int t

                    Nothing ->
                        JE.null
              )
            , ( "payload", payload )
            ]
                |> JE.object
                |> package
                    "push"
                |> portOut

        On { topic, event } ->
            [ ( "topic"
              , case topic of
                    Just t ->
                        JE.string t

                    Nothing ->
                        JE.null
              )
            , ( "event", JE.string event )
            ]
                |> JE.object
                |> package
                    "on"
                |> portOut

        Off { topic, event } ->
            [ ( "topic"
              , case topic of
                    Just t ->
                        JE.string t

                    Nothing ->
                        JE.null
              )
            , ( "event", JE.string event )
            ]
                |> JE.object
                |> package
                    "off"
                |> portOut

        Leave { topic, timeout } ->
            [ ( "topic"
              , case topic of
                    Just t ->
                        JE.string t

                    Nothing ->
                        JE.null
              )
            , ( "timeout"
              , case timeout of
                    Just t ->
                        JE.int t

                    Nothing ->
                        JE.null
              )
            ]
                |> JE.object
                |> package
                    "leave"
                |> portOut


package : String -> JE.Value -> PackageOut
package event value =
    { event = event
    , payload = value
    }


{-| A type alias representing the data sent out through a `port` to a channel.
You will not use this directly.
-}
type alias PackageOut =
    { event : String
    , payload : JE.Value
    }


{-| A type alias representing the `port` function required to send the
[EventOut](#EventOut) to the channel.

You could write this yourself, if you do, it needs to be named
`sendMessage`, although you may find it simpler to just add
[this port module](https://github.com/phollyer/elm-phoenix-websocket/blob/master/src/Ports/Phoenix.elm)
to your `src` - it includes all the necessary `port` functions.

-}
type alias PortOut msg =
    PackageOut -> Cmd msg


{-| All of the events you can send to the channel.

Each of these [EventOut](#EventOut) messages corresponds to the equivalent function
in the [PhoenixJS API](https://hexdocs.pm/phoenix/js/index.html#channel). For
more info on these please read the API
[docs](https://hexdocs.pm/phoenix/js/index.html#channel).

-}
type EventOut
    = Join JoinConfig
    | Push PushConfig
    | On EventConfig
    | Off EventConfig
    | Leave LeaveConfig


{-| A type alias representing the settings for joining a channel.

`topic` - the channel topic id, for example: `"topic:subtopic"`.

`timeout` - optional timeout, in ms, before retrying to join if the previous
attempt failed.

`payload` - optional data to be sent to the channel when joining.

-}
type alias JoinConfig =
    { topic : String
    , timeout : Maybe Int
    , payload : Maybe Value
    }


{-| A type alias representing the settings for pushing messages over a channel.

`topic` - the channel topic id, for example: `Just "topic:subtopic"`.

The `topic` is used to track the channels on the JS side. This allows for
utilising multiple channels. Setting `topic = Nothing` will send the push over
the last used channel, or the only channel you're using if using only one
channel.

`event` - the event to send to the channel.

`timeout` - optional timeout, in ms, before retrying to push if the previous
attempt failed.

`payload` - the data to be sent.

-}
type alias PushConfig =
    { topic : Maybe String
    , event : String
    , timeout : Maybe Int
    , payload : Value
    }


{-| A type alias representing channel events that can be turned [On](#EventOut)
or [Off](#EventOut).

`topic` - optional channel topic id, for example: `Just "topic:subtopic"`.

The `topic` is used to track the channels on the JS side. This allows for
utilising multiple channels. Setting `topic = Nothing` will set the event on
the last used channel, or the only channel you're using if using only one
channel.

`event` - the event that you want to be turned [On](#EventOut) or
[Off](#EventOut).

In order to receive event [Message](#EventIn)s, they need to be registered with
an [On](#EventOut) event sent to the channel. So if your Phoenix Channel is
going to `push` or `broadcast` a `new_msg` event, it needs to be registered as
follows:

    import Channel
    import Ports.Phoenix as Phx

    Phx.sendMessage
        |> Channel.send
            (On
                { topic = Just "topic:subtopic"
                , event = "new_msg"
                }
            )

Now you will be able to receive `new_msg`s as follows:

    import Channel exposing (EventIn(..))
    import Ports.Phoenix as Phx

    type Msg
        = ChannelMsg Channel.EventIn

    update : Msg -> Model -> (Model, Cmd Msg)
    update msg model =
        case msg of
            ChannelMsg (Message "topic:subtopic" "new_msg" payload) ->
                ...

    subscriptions : Model -> Sub Msg
    subscriptions _ =
        Phx.channelReceiver
            |> Channel.subscriptions
                ChannelMsg

**NB** you must set your [On](#EventOut) events after you have joined the
relevant channel.

-}
type alias EventConfig =
    { topic : Maybe String
    , event : String
    }


{-| A type alias representing the settings for leaving a channel.

`topic` - optional channel topic id, for example: `Just "topic:subtopic"`.

The `topic` is used to track the channels on the JS side. This allows for
utilising multiple channels. Setting `topic = Nothing` will leave the last used
channel, or the only channel you're using if using only one channel.

`timeout` - optional timeout, in ms, before retrying to leave if the previous
attempt failed.

-}
type alias LeaveConfig =
    { topic : Maybe String
    , timeout : Maybe Int
    }



-- Receiving


{-| Subscribe to receive incoming channel events.

    import Channel
    import Ports.Phoenix as Phx

    type Msg
      = ChannelMsg Channel.EventIn
      | ...


    subscriptions : Model -> Sub Msg
    subscriptions _ =
        Phx.channelReceiver
          |> Channel.subscriptions
            ChannelMsg

-}
subscriptions : (EventIn -> msg) -> PortIn msg -> Sub msg
subscriptions msg portIn =
    portIn (handleIn msg)


handleIn : (EventIn -> msg) -> PackageIn -> msg
handleIn toMsg { topic, event, payload } =
    case event of
        "JoinOk" ->
            toMsg (JoinOk topic payload)

        "JoinError" ->
            toMsg (JoinError topic payload)

        "JoinTimeout" ->
            let
                payload_ =
                    payload
                        |> JD.decodeValue
                            (JD.field "payload" JD.value)
                        |> Result.toMaybe
                        |> Maybe.withDefault JE.null
            in
            toMsg (JoinTimeout topic payload_)

        "PushOk" ->
            let
                event_ =
                    payload
                        |> JD.decodeValue
                            (JD.field "event" JD.string)
                        |> Result.toMaybe
                        |> Maybe.withDefault ""

                payload_ =
                    payload
                        |> JD.decodeValue
                            (JD.field "payload" JD.value)
                        |> Result.toMaybe
                        |> Maybe.withDefault JE.null
            in
            toMsg (PushOk topic event_ payload_)

        "PushError" ->
            let
                event_ =
                    payload
                        |> JD.decodeValue
                            (JD.field "event" JD.string)
                        |> Result.toMaybe
                        |> Maybe.withDefault ""

                payload_ =
                    payload
                        |> JD.decodeValue
                            (JD.field "payload" JD.value)
                        |> Result.toMaybe
                        |> Maybe.withDefault JE.null
            in
            toMsg (PushError topic event_ payload_)

        "PushTimeout" ->
            let
                event_ =
                    payload
                        |> JD.decodeValue
                            (JD.field "event" JD.string)
                        |> Result.toMaybe
                        |> Maybe.withDefault ""

                payload_ =
                    payload
                        |> JD.decodeValue
                            (JD.field "payload" JD.value)
                        |> Result.toMaybe
                        |> Maybe.withDefault JE.null
            in
            toMsg (PushTimeout topic event_ payload_)

        "Message" ->
            let
                event_ =
                    payload
                        |> JD.decodeValue
                            (JD.field "event" JD.string)
                        |> Result.toMaybe
                        |> Maybe.withDefault ""

                msg =
                    payload
                        |> JD.decodeValue
                            (JD.field "payload" JD.value)
                        |> Result.toMaybe
                        |> Maybe.withDefault JE.null
            in
            toMsg (Message topic event_ msg)

        "Error" ->
            let
                msg =
                    payload
                        |> JD.decodeValue
                            (JD.field "msg" JD.value)
                        |> Result.toMaybe
                        |> Maybe.withDefault JE.null
            in
            toMsg (Error topic msg)

        "LeaveOk" ->
            toMsg (LeaveOk topic)

        "Closed" ->
            toMsg (Closed topic)

        _ ->
            toMsg (InvalidEvent topic event payload)


{-| A type alias representing the data received from a channel. You will not
use this directly.
-}
type alias PackageIn =
    { topic : String
    , event : String
    , payload : JE.Value
    }


{-| A type alias representing the `port` function required to receive
the [EventIn](#EventIn) from the channel.

You could write this yourself, if you do, it needs to be named
`channelReceiver`, although you may find it simpler to just add
[this port module](https://github.com/phollyer/elm-phoenix-websocket/blob/master/src/Ports/Phoenix.elm)
to your `src` - it includes all the necessary `port` functions.

-}
type alias PortIn msg =
    (PackageIn -> msg) -> Sub msg


{-| All of the events you can receive from the channel.

If you are using more than one channel, then you can check `Topic` to determine
which channel the [EventIn](#EventIn) relates to. If you are only using a single
channel, you can ignore `Topic`.

`InvalidEvent` means that an event has been received from the accompanying JS
that cannot be handled. This should not happen, if it does, please raise an
[issue](https://github.com/phollyer/elm-phoenix-websocket/issues).

-}
type EventIn
    = JoinOk Topic Value
    | JoinError Topic Value
    | JoinTimeout Topic Value
    | PushOk Topic PushEvent Value
    | PushError Topic PushEvent Value
    | PushTimeout Topic PushEvent Value
    | Message Topic PushEvent Value
    | Error Topic Value
    | LeaveOk Topic
    | Closed Topic
    | InvalidEvent Topic String Value


{-| A type alias representing the channel topic. Use this to identify the
channel an [EventIn](#EventIn) relates to.

If you are only using one channel, you can ignore this.

-}
type alias Topic =
    String


{-| A type alias representing a [Push](#EventOut) to a channel. Use this to
identify which [Push](#EventOut) an [EventIn](#EventIn) relates to.
-}
type alias PushEvent =
    String



-- Helpers


{-| Set up all the incoming events from the channel.

This needs to used after joining the channel.

    import Channel
    import Ports.Phoenix as Phx

    Phx.sendMessage
        |> Channel.eventsOn
            (Just "topic:subtopic")
            [ "msg1"
            , "msg2"
            , "msg3"
            ]


    Phx.sendMessage
        |> Channel.eventsOn
            Nothing  -- Will use the last used channel, or the only channel if only using one
            [ "msg1"
            , "msg2"
            , "msg3"
            ]

-}
eventsOn : Maybe Topic -> List String -> PortOut msg -> Cmd msg
eventsOn maybeTopic events portOut =
    events
        |> List.map
            (batchEvent
                On
                portOut
                maybeTopic
            )
        |> Cmd.batch


{-| Stop receiving specifc incoming events from the channel.

    import Channel
    import Ports.Phoenix as Phx

    Phx.sendMessage
        |> Channel.eventsOn
            (Just "topic:subtopic")
            [ "msg1"
            , "msg2"
            , "msg3"
            ]

    Phx.sendMessage
        |> Channel.eventsOff
            (Just "topic:subtopic")
            [ "msg1"
            , "msg2"
            ]

    -- "msg3" will still be received.

-}
eventsOff : Maybe Topic -> List String -> PortOut msg -> Cmd msg
eventsOff maybeTopic events portOut =
    events
        |> List.map
            (batchEvent
                Off
                portOut
                maybeTopic
            )
        |> Cmd.batch


batchEvent : (EventConfig -> EventOut) -> PortOut msg -> Maybe Topic -> String -> Cmd msg
batchEvent eventFun portOut maybeTopic event =
    portOut
        |> send
            (eventFun
                { topic = maybeTopic
                , event = event
                }
            )
