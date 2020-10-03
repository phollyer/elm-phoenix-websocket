module Phoenix.Channel exposing
    ( JoinConfig, PortOut, join
    , LeaveConfig, leave
    , PushConfig, push
    , PortIn, Topic, OriginalPushMsg, NewPushMsg, Msg(..), subscriptions
    , on, off
    )

{-| Use this module to work directly with channels.

Before you can start sending and receiving messages to and from your channels,
you first need to connect to a [socket](Phoenix.Socket), and join the channels.


# Joining

@docs JoinConfig, PortOut, join


# Leaving

@docs LeaveConfig, leave


# Pushing

@docs PushConfig, push


# Receiving

@docs PortIn, Topic, OriginalPushMsg, NewPushMsg, Msg, subscriptions


# Custom Messages

@docs on, off

-}

import Json.Decode as JD
import Json.Encode as JE exposing (Value)


{-| A type alias representing the config for joining a channel.

  - `topic` - the channel topic id, for example: `"topic:subtopic"`.

  - `payload` - optional data to be sent to the channel when joining.

  - `timeout` - optional timeout, in ms, before retrying to join if the previous
    attempt failed.

-}
type alias JoinConfig =
    { topic : String
    , payload : Maybe Value
    , timeout : Maybe Int
    }


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


{-| Join a channel.

    import Phoenix.Channel as Channel
    import Port

    Channel.join
        { topic = "topic:subtopic"
        , payload = Nothing
        , timeout = Nothing
        }
        Port.pheonixSend

-}
join : JoinConfig -> PortOut msg -> Cmd msg
join { topic, payload, timeout } portOut =
    let
        payload_ =
            JE.object
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
    in
    portOut
        { msg = "join"
        , payload = payload_
        }


{-| A type alias representing the config for leaving a channel.

  - `topic` - channel topic id, for example: `"topic:subtopic"`.
  - `timeout` - optional timeout, in ms, before retrying to leave if the previous
    attempt failed.

-}
type alias LeaveConfig =
    { topic : String
    , timeout : Maybe Int
    }


{-| Leave a channel.

    import Phoenix.Channel as Channel
    import Port

    Channel.leave
        { topic = "topic:subtopic"
        , timeout = Nothing
        }
        Port.pheonixSend

-}
leave : LeaveConfig -> PortOut msg -> Cmd msg
leave { topic, timeout } portOut =
    let
        payload_ =
            JE.object
                [ ( "topic", JE.string topic )
                , ( "timeout"
                  , case timeout of
                        Just t ->
                            JE.int t

                        Nothing ->
                            JE.null
                  )
                ]
    in
    portOut
        { msg = "leave"
        , payload = payload_
        }


{-| A type alias representing the config for pushing messages to a channel.

  - `topic` - the channel topic id, for example: `"topic:subtopic"`.

  - `msg` - the msg to send to the channel.

  - `payload` - the data to be sent.

  - `timeout` - optional timeout, in ms, before retrying to push if the previous
    attempt failed.

-}
type alias PushConfig =
    { topic : String
    , msg : String
    , payload : Value
    , timeout : Maybe Int
    }


{-| Push a message to a channel.

    import Json.Encode as JE
    import Phoenix.Channel as Channel
    import Port

    Channel.push
        { topic = "topic:subtopic"
        , msg = "new_msg"
        , payload = JE.object [("msg", JE.string "Hello World")]
        , timeout = Nothing
        }
        Port.pheonixSend

-}
push : PushConfig -> PortOut msg -> Cmd msg
push { topic, msg, payload, timeout } portOut =
    let
        payload_ =
            JE.object
                [ ( "topic", JE.string topic )
                , ( "msg", JE.string msg )
                , ( "payload", payload )
                , ( "timeout"
                  , case timeout of
                        Just t ->
                            JE.int t

                        Nothing ->
                            JE.null
                  )
                ]
    in
    portOut
        { msg = "push"
        , payload = payload_
        }


{-| A type alias representing the `port` function required to receive
a [Msg](#Msg) from a channel.

You will find this `port` function in the
[Port](https://github.com/phollyer/elm-phoenix-websocket/tree/master/src/Ports)
module.

-}
type alias PortIn msg =
    ({ topic : String
     , msg : String
     , payload : JE.Value
     }
     -> msg
    )
    -> Sub msg


{-| A type alias representing the channel topic that a [Msg](#Msg) is received
from.
-}
type alias Topic =
    String


{-| A type alias representing a [push](#push) to a channel. Use this to
identify which [push](#push) a [Msg](#Msg) relates to.

So, if you sent the following [push](#push):

    import Json.Encode as JE
    import Phoenix.Channel as Channel
    import Port

    Channel.push
        { topic = "topic:subtopic"
        , msg = "new_msg"
        , payload = JE.object [("msg", JE.string "Hello World")]
        , timeout = Nothing
        }
        Port.pheonixSend

`OriginalPushMsg` would be equal to `"new_msg"`.

-}
type alias OriginalPushMsg =
    String


{-| A type alias representing a msg `push`ed or `broadcast` from a channel.
-}
type alias NewPushMsg =
    String


{-| All of the msgs you can receive from the channel.

  - `Topic` - is the channel topic that the message came from.
  - `OriginalPushMsg` - is the original `msg` that was [push](#push)ed to the
    channel.
  - `NewPushMsg` - is a `msg` that has been `push`ed or `broadcast` from a
    channel.
  - `Value` - is the payload received from the channel, with the exception of
    `JoinTimout` and `PushTimeout` where it will be the original payload.

`InvalidEvent` means that a msg has been received from the accompanying JS
that cannot be handled. This should not happen, if it does, please raise an
[issue](https://github.com/phollyer/elm-phoenix-websocket/issues).

-}
type Msg
    = JoinOk Topic Value
    | JoinError Topic Value
    | JoinTimeout Topic Value
    | PushOk Topic OriginalPushMsg Value
    | PushError Topic OriginalPushMsg Value
    | PushTimeout Topic OriginalPushMsg Value
    | Message Topic NewPushMsg Value
    | Error Topic Value
    | LeaveOk Topic
    | Closed Topic
    | InvalidEvent Topic String Value


{-| Subscribe to receive incoming channel [Msg](#Msg)s.

    import Phoenix.Channel as Channel
    import Port

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
    portIn <|
        handleIn msg


handleIn : (Msg -> msg) -> { topic : String, msg : String, payload : JE.Value } -> msg
handleIn toMsg { topic, msg, payload } =
    case msg of
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
                msg_ =
                    payload
                        |> JD.decodeValue
                            (JD.field "msg" JD.string)
                        |> Result.toMaybe
                        |> Maybe.withDefault ""

                payload_ =
                    payload
                        |> JD.decodeValue
                            (JD.field "payload" JD.value)
                        |> Result.toMaybe
                        |> Maybe.withDefault JE.null
            in
            toMsg (PushOk topic msg_ payload_)

        "PushError" ->
            let
                msg_ =
                    payload
                        |> JD.decodeValue
                            (JD.field "msg" JD.string)
                        |> Result.toMaybe
                        |> Maybe.withDefault ""

                payload_ =
                    payload
                        |> JD.decodeValue
                            (JD.field "payload" JD.value)
                        |> Result.toMaybe
                        |> Maybe.withDefault JE.null
            in
            toMsg (PushError topic msg_ payload_)

        "PushTimeout" ->
            let
                msg_ =
                    payload
                        |> JD.decodeValue
                            (JD.field "msg" JD.string)
                        |> Result.toMaybe
                        |> Maybe.withDefault ""

                payload_ =
                    payload
                        |> JD.decodeValue
                            (JD.field "payload" JD.value)
                        |> Result.toMaybe
                        |> Maybe.withDefault JE.null
            in
            toMsg (PushTimeout topic msg_ payload_)

        "Message" ->
            let
                msg_ =
                    payload
                        |> JD.decodeValue
                            (JD.field "msg" JD.string)
                        |> Result.toMaybe
                        |> Maybe.withDefault ""

                payload_ =
                    payload
                        |> JD.decodeValue
                            (JD.field "payload" JD.value)
                        |> Result.toMaybe
                        |> Maybe.withDefault JE.null
            in
            toMsg (Message topic msg_ payload_)

        "Error" ->
            let
                msg_ =
                    payload
                        |> JD.decodeValue
                            (JD.field "msg" JD.value)
                        |> Result.toMaybe
                        |> Maybe.withDefault JE.null
            in
            toMsg (Error topic msg_)

        "LeaveOk" ->
            toMsg (LeaveOk topic)

        "Closed" ->
            toMsg (Closed topic)

        _ ->
            toMsg (InvalidEvent topic msg payload)


{-| Switch incoming messages on.

In order to receive messages that are `push`ed or `broadcast` from a channel,
it is necessary to set up the JS to receive them. This function allows you to
do just that.

-}
on : { topic : String, msgs : List String } -> PortOut msg -> Cmd msg
on { topic, msgs } portOut =
    Cmd.batch <|
        List.map
            (\msg ->
                let
                    payload =
                        JE.object
                            [ ( "topic", JE.string topic )
                            , ( "msg", JE.string msg )
                            ]
                in
                portOut
                    { msg = "on"
                    , payload = payload
                    }
            )
            msgs


{-| Switch incoming messages off.
-}
off : { topic : String, msgs : List String } -> PortOut msg -> Cmd msg
off { topic, msgs } portOut =
    Cmd.batch <|
        List.map
            (\msg ->
                let
                    payload =
                        JE.object
                            [ ( "topic", JE.string topic )
                            , ( "msg", JE.string msg )
                            ]
                in
                portOut
                    { msg = "off"
                    , payload = payload
                    }
            )
            msgs
