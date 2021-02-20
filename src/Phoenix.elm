module Phoenix exposing
    ( Model
    , PortConfig, init
    , Msg
    , SocketState(..), SocketMessage(..)
    , Topic, Event, Payload, OriginalPayload, PushRef, ChannelResponse(..)
    , Presence, PresenceDiff, PresenceEvent(..)
    , InternalError(..)
    , PhoenixMsg(..), update, updateWith, map, mapMsg
    , RetryStrategy(..), PushConfig, pushConfig, push
    , subscriptions
    , connect
    , addConnectOptions, setConnectOptions
    , setConnectParams
    , disconnect, disconnectAndReset
    , join, joinAll, JoinConfig, joinConfig, setJoinConfig
    , leave, leaveAll, LeaveConfig, setLeaveConfig
    , addEvent, addEvents, dropEvent, dropEvents
    , socketState, socketStateToString, isConnected, connectionState, disconnectReason, endPointURL, protocol
    , queuedChannels, channelQueued, joinedChannels, channelJoined, topicParts
    , allQueuedPushes, queuedPushes, pushQueued, dropQueuedPush
    , pushInFlight, pushWaiting
    , timeoutPushes, pushTimedOut, dropTimeoutPush, pushTimeoutCountdown
    , dropPush
    , presenceState, presenceDiff, presenceJoins, presenceLeaves, lastPresenceJoin, lastPresenceLeave
    , batch, batchWithParams
    , log, startLogging, stopLogging
    )

{-| This module is a wrapper around the [Socket](Phoenix.Socket),
[Channel](Phoenix.Channel) and [Presence](Phoenix.Presence) modules. It handles
all the low level stuff with a simple, but extensive API. It automates a few
processes, and generally simplifies working with Phoenix WebSockets.

Once you have installed the package, and followed the simple setup instructions
[here](https://package.elm-lang.org/packages/phollyer/elm-phoenix-websocket/latest/),
configuring this module is as simple as this:

    import Phoenix
    import Ports.Phoenix as Ports


    -- Add the Phoenix Model to your Model

    type alias Model =
        { phoenix : Phoenix.Model
            ...
        }


    -- Initialize the Phoenix Model

    init : Model
    init =
        { phoenix = Phoenix.init Ports.config
            ...
        }


    -- Add a Phoenix Msg

    type Msg
        = PhoenixMsg Phoenix.Msg
        | ...


    -- Handle Phoenix Msgs

    update : Msg -> Model -> (Model Cmd Msg)
    update msg model =
        case msg of
            PhoenixMsg subMsg ->
                let
                    (phoenix, phoenixCmd, phoenixMsg) =
                        Phoenix.update subMsg model.phoenix
                in
                case phoenixMsg of
                    ...

                _ ->
                    ({ model | phoenix = phoenix }
                    , Cmd.map PhoenixMsg phoenixCmd
                    )

            _ ->
                (model, Cmd.none)


    -- Subscribe to receive Phoenix Msgs

    subscriptions : Model -> Sub Msg
    subscriptions model =
        Sub.map PhoenixMsg <|
            Phoenix.subscriptions model.phoenix


# Model

@docs Model


# Initialising the Model

@docs PortConfig, init


# Update

@docs Msg

@docs SocketState, SocketMessage

@docs Topic, Event, Payload, OriginalPayload, PushRef, ChannelResponse

@docs Presence, PresenceDiff, PresenceEvent

@docs InternalError

@docs PhoenixMsg, update, updateWith, map, mapMsg


# Pushing

When pushing an event to a Channel, opening the Socket, and joining the
Channel is handled automatically. Pushes will be queued until the Channel has
been joined, at which point, any queued pushes will be sent in a batch.

See [Connecting to the Socket](#connecting-to-the-socket) and
[Joining a Channel](#joining-a-channel) for more details on handling connecting
and joining manually.

If the Socket is open and the Channel already joined, the push will be sent
immediately.

@docs RetryStrategy, PushConfig, pushConfig, push


# Subscriptions

@docs subscriptions


# Connecting to the Socket

Connecting to the Socket is automatic on the first [push](#push) to a Channel,
and also when a [join](#join) is attempted. However, if it is necessary to
connect before hand, the [connect](#connect) function is available.

@docs connect


## Setting connect options

@docs addConnectOptions, setConnectOptions


## Sending data when connecting

@docs setConnectParams


# Disconnecting from the Socket

@docs disconnect, disconnectAndReset


# Joining a Channel

Joining a Channel is automatic on the first [push](#push) to the Channel.
However, if it is necessary to join before hand, the [join](#join) function is
available.

@docs join, joinAll, JoinConfig, joinConfig, setJoinConfig


# Leaving a Channel

@docs leave, leaveAll, LeaveConfig, setLeaveConfig


# Incoming Events

Setting up incoming events to receive on a Channel can be done when setting a
[JoinConfig](#JoinConfig), but if it is necessary to switch events on and off
intermittently, then the following functions are available.

@docs addEvent, addEvents, dropEvent, dropEvents


# Helpers


## Socket Information

@docs socketState, socketStateToString, isConnected, connectionState, disconnectReason, endPointURL, protocol


## Channels

@docs queuedChannels, channelQueued, joinedChannels, channelJoined, topicParts


## Pushes

@docs allQueuedPushes, queuedPushes, pushQueued, dropQueuedPush

@docs pushInFlight, pushWaiting

@docs timeoutPushes, pushTimedOut, dropTimeoutPush, pushTimeoutCountdown

@docs dropPush


## Presence Information

@docs presenceState, presenceDiff, presenceJoins, presenceLeaves, lastPresenceJoin, lastPresenceLeave


## Batching

@docs batch, batchWithParams


## Logging

Here you can log data to the console, and activate and deactive the socket's
logger, but be warned, **there is no safeguard when you compile** such as you
get when you use `Debug.log`. Be sure to deactive the logging before you deploy
to production.

However, the ability to easily toggle logging on and off leads to a possible
use case where, in a deployed production environment, an admin is able to see
all the logging, while regular users do not.

@docs log, startLogging, stopLogging

-}

import Dict exposing (Dict)
import Internal.Channel as Channel exposing (Channel)
import Internal.Config exposing (Config)
import Internal.Presence as Presence exposing (Presence)
import Internal.Push as Push exposing (Push)
import Internal.Socket as Socket exposing (Socket)
import Json.Encode as JE exposing (Value)
import Phoenix.Channel
import Phoenix.Presence
import Phoenix.Socket
import Time



{- Model -}


{-| The model that carries the internal state.

This is an opaque type, so use the provided API to interact with it.

-}
type Model
    = Model
        { portConfig : PortConfig
        , socket : Socket SocketState Msg
        , channel : Channel Msg
        , push : Push RetryStrategy Msg
        , presence : Presence.Presence
        }


{-| Initialize the [Model](#Model) by providing the `ports` that enable
communication with JS.

The easiest way to provide the `ports` is to copy
[this file](https://github.com/phollyer/elm-phoenix-websocket/tree/master/ports)
into your `src`, and then use its `config` function as follows:

    import Phoenix
    import Ports.Phoenix as Ports

    init : Model
    init =
        { phoenix = Phoenix.init Ports.config
            ...
        }

-}
init : PortConfig -> Model
init portConfig =
    Model
        { portConfig = portConfig
        , socket =
            Socket.init portConfig.phoenixSend
                (Disconnected (Phoenix.Socket.ClosedInfo Nothing 0 False "" False))
        , channel = Channel.init portConfig.phoenixSend
        , push = Push.init portConfig.phoenixSend
        , presence = Presence.init
        }



{- Types -}


{-| A type alias representing the ports that are needed to communicate with JS.

This is for reference only, you won't need this if you copy
[this file](https://github.com/phollyer/elm-phoenix-websocket/tree/master/ports)
into your `src`.

-}
type alias PortConfig =
    { phoenixSend :
        { msg : String
        , payload : Value
        }
        -> Cmd Msg
    , socketReceiver :
        ({ msg : String
         , payload : Value
         }
         -> Msg
        )
        -> Sub Msg
    , channelReceiver :
        ({ topic : String
         , msg : String
         , payload : Value
         }
         -> Msg
        )
        -> Sub Msg
    , presenceReceiver :
        ({ topic : String
         , msg : String
         , payload : Value
         }
         -> Msg
        )
        -> Sub Msg
    }


{-| The `Msg` type that you pass into the [update](#update) function.

This is an opaque type, for pattern matching see [PhoenixMsg](#PhoenixMsg).

-}
type Msg
    = ReceivedChannelMsg Phoenix.Channel.Msg
    | ReceivedPresenceMsg Phoenix.Presence.Msg
    | ReceivedSocketMsg Phoenix.Socket.Msg
    | TimeoutTick Time.Posix


{-| Pattern match on these in your `update` function.

To handle events that are `push`ed or `broadcast` from an Elixir Channel you
should pattern match on `ChannelEvent`.

-}
type PhoenixMsg
    = NoOp
    | SocketMessage SocketMessage
    | ChannelResponse ChannelResponse
    | ChannelEvent Topic Event Payload
    | PresenceEvent PresenceEvent
    | InternalError InternalError


{-| -}
type SocketMessage
    = StateChange SocketState
    | SocketError String
    | ChannelMessage
        { topic : String
        , event : String
        , payload : Value
        , joinRef : Maybe String
        , ref : Maybe String
        }
    | PresenceMessage
        { topic : String
        , event : String
        , payload : Value
        }
    | Heartbeat
        { topic : String
        , event : String
        , payload : Value
        , ref : String
        }


{-| -}
type SocketState
    = Connecting
    | Connected
    | Disconnecting
    | Disconnected
        { reason : Maybe String
        , code : Int
        , wasClean : Bool
        , type_ : String
        , isTrusted : Bool
        }


{-| -}
type ChannelResponse
    = ChannelError Topic
    | ChannelClosed Topic
    | LeaveOk Topic
    | JoinOk Topic Payload
    | JoinError Topic Payload
    | JoinTimeout Topic OriginalPayload
    | PushOk Topic Event PushRef Payload
    | PushError Topic Event PushRef Payload
    | PushTimeout Topic Event PushRef OriginalPayload


{-| -}
type PresenceEvent
    = Join Topic Presence
    | Leave Topic Presence
    | State Topic (List Presence)
    | Diff Topic PresenceDiff


{-| An `InternalError` should never happen, but if it does, it is because the
JS is out of sync with this package.

If you ever receive this message, please
[raise an issue](https://github.com/phollyer/elm-phoenix-websocket/issues).

-}
type InternalError
    = DecoderError String
    | InvalidMessage String


{-| A type alias representing data that is sent to, or received from, a
Channel.
-}
type alias Payload =
    Value


{-| A type alias representing the Channel topic id, for example
`"topic:subTopic"`.
-}
type alias Topic =
    String


{-| A type alias representing an event that is sent to, or received from, a
Channel.
-}
type alias Event =
    String


{-| A type alias representing the `ref` set on a [push](#PushConfig).
-}
type alias PushRef =
    Maybe String


{-| A type alias representing the original payload that was sent with a
[push](#PushConfig).
-}
type alias OriginalPayload =
    Value


{-| A type alias representing the optional config to use when joining a
Channel.

  - `topic` - The channel topic id, for example: `"topic:subTopic"`.

  - `payload` - Data to be sent to the Channel when joining. If no data is
    required, set this to
    [Json.Encode.null](https://package.elm-lang.org/packages/elm/json/latest/Json-Encode#null).
    Defaults to
    [Json.Encode.null](https://package.elm-lang.org/packages/elm/json/latest/Json-Encode#null).

  - `events` - A list of events to receive from the Channel. Defaults to `[]`.

  - `timeout` - Optional timeout, in ms, before retrying to join if the previous
    attempt failed. Defaults to `Nothing`.

If a `JoinConfig` is not set prior to joining a Channel, the defaults will be used.

-}
type alias JoinConfig =
    { topic : String
    , payload : Value
    , events : List String
    , timeout : Maybe Int
    }


{-| A type alias representing the optional config to use when leaving a
Channel.

  - `topic` - The channel topic id, for example: `"topic:subTopic"`.

  - `timeout` - Optional timeout, in ms, before retrying to leave if the
    previous attempt failed. Defaults to `Nothing`.

If a `LeaveConfig` is not set prior to leaving a Channel, the defaults will be used.

-}
type alias LeaveConfig =
    { topic : Topic
    , timeout : Maybe Int
    }


{-| A type alias representing the config for pushing a message to a Channel.

  - `topic` - The Channel topic to send the push to.

  - `event` - The event to send to the Channel.

  - `payload` - The data to send with the push. If you don't need to send any
    data, set this to
    [Json.Encode.null](https://package.elm-lang.org/packages/elm/json/latest/Json-Encode#null).

  - `timeout` - Optional timeout in milliseconds to set on the push request.

  - `retryStrategy` - The retry strategy to use if the push times out.

  - `ref` - Optional reference that can later be used to identify the push.
    This is useful when using functions that need to find the push in order to
    do their thing, such as [dropPush](#dropPush) or
    [pushTimeoutCountdown](#pushTimeoutCountdown).

-}
type alias PushConfig =
    { topic : String
    , event : String
    , payload : Value
    , timeout : Maybe Int
    , retryStrategy : RetryStrategy
    , ref : Maybe String
    }


{-| The retry strategy to use if a push times out.

  - `Drop` - Drop the push and don't try again. This is the default if no
    strategy is set.

  - `Every second` - The number of seconds to wait between retries.

  - `Backoff [List seconds] (Maybe max)` - A backoff strategy enabling you to increase
    the delay between retries. When the list has been exhausted, `max` will be
    used for each subsequent attempt, if max is `Nothing`, the push will then
    be dropped, which is useful if you want to limit the number of retries.

        Backoff [ 1, 5, 10, 20 ] (Just 30)

-}
type RetryStrategy
    = Drop
    | Every Int
    | Backoff (List Int) (Maybe Int)


{-| A type alias representing a Presence on a Channel.

  - `id` - The `id` used to identify the Presence map in the
    [Presence.track/3](https://hexdocs.pm/phoenix/Phoenix.Presence.html#c:track/3)
    Elixir function. The recommended approach is to use the users' `id`.

  - `metas`- A list of metadata as stored in the
    [Presence.track/3](https://hexdocs.pm/phoenix/Phoenix.Presence.html#c:track/3)
    function.

  - `user` - The user data that is pulled from the DB and stored on the
    Presence in the
    [fetch/2](https://hexdocs.pm/phoenix/Phoenix.Presence.html#c:fetch/2)
    Elixir callback function. This is the recommended approach for storing user
    data on the Presence. If
    [fetch/2](https://hexdocs.pm/phoenix/Phoenix.Presence.html#c:fetch/2) is
    not being used then `user` will be equal to
    [Json.Encode.null](https://package.elm-lang.org/packages/elm/json/latest/Json-Encode#null).

  - `presence` - The whole Presence map. This provides a way to access any
    additional data that is stored on the Presence.

```
-- MyAppWeb.MyChannel.ex

def handle_info(:after_join, socket) do
  {:ok, _} = Presence.track(socket, socket.assigns.user_id, %{
    online_at: System.os_time(:millisecond)
  })

  push(socket, "presence_state", Presence.list(socket))

  {:noreply, socket}
end

-- MyAppWeb.Presence.ex

defmodule MyAppWeb.Presence do
  use Phoenix.Presence,
    otp_app: :my_app,
    pubsub_server: MyApp.PubSub

  def fetch(_topic, presences) do
    query =
      from u in User,
      where: u.id in ^Map.keys(presences),
      select: {u.id, u}

    users = query |> Repo.all() |> Enum.into(%{})

    for {key, %{metas: metas}} <- presences, into: %{} do
      {key, %{metas: metas, user: users[key]}}
    end
  end
end
```

-}
type alias Presence =
    { id : String
    , metas : List Value
    , user : Value
    , presence : Value
    }


{-| -}
type alias PresenceDiff =
    { joins : List Presence
    , leaves : List Presence
    }



{- Actions -}


{-| Connect to the Socket.
-}
connect : Model -> ( Model, Cmd Msg )
connect (Model ({ socket } as model)) =
    case Socket.currentState model.socket of
        Disconnected _ ->
            ( updateSocketState Connecting (Model { model | socket = Socket.setReconnect False socket })
            , Socket.connect model.socket
            )

        Disconnecting ->
            -- A request has come in to connect while disconnecting
            -- so set a flag that tells us to connect again when the
            -- closed event is received.
            ( Model { model | socket = Socket.setReconnect True socket }
            , Cmd.none
            )

        _ ->
            -- Ignore the connect request because we are either connected
            -- or connecting already
            ( Model model
            , Cmd.none
            )


{-| Disconnect the Socket, maybe providing a status
[code](https://developer.mozilla.org/en-US/docs/Web/API/CloseEvent#Status_codes)
for the closure.

[ConnectOptions](Socket#ConnectOptions) and configs etc will remain to make it
simpler to connect again. If you want to reset everything use the
[disconnectAndReset](#disconnectAndReset) function instead.

-}
disconnect : Maybe Int -> Model -> ( Model, Cmd Msg )
disconnect code (Model ({ socket } as model)) =
    case Socket.currentState model.socket of
        Disconnected _ ->
            ( Model model, Cmd.none )

        Disconnecting ->
            ( Model model, Cmd.none )

        _ ->
            ( updateSocketState Disconnecting (Model model)
            , Socket.disconnect code socket
            )


{-| Disconnect the Socket, maybe providing a status
[code](https://developer.mozilla.org/en-US/docs/Web/API/CloseEvent#Status_codes)
for the closure.

This will reset all of the internal model, so information relating to
[ConnectOptions](Socket#ConnectOptions) and configs etc will also be reset.

The only information that will remain is the [PortConfig](#PortConfig).

-}
disconnectAndReset : Maybe Int -> Model -> ( Model, Cmd Msg )
disconnectAndReset code (Model model) =
    case Socket.currentState model.socket of
        Disconnected _ ->
            ( init model.portConfig, Cmd.none )

        Disconnecting ->
            ( init model.portConfig, Cmd.none )

        _ ->
            ( init model.portConfig
            , Socket.disconnect code model.socket
            )


{-| Join a Channel referenced by the [Topic](#Topic).

Connecting to the Socket is automatic if it has not already been done.

If the Socket is not open, the `join` will be queued, and the Socket will try
to connect. Once the Socket is open, any queued `join`s will be attempted.

If the Socket is already open, the `join` will be attempted immediately.

-}
join : Topic -> Model -> ( Model, Cmd Msg )
join topic (Model ({ channel } as model)) =
    if Channel.isJoined topic channel then
        ( Model model, Cmd.none )

    else
        case Socket.currentState model.socket of
            Connected ->
                let
                    ( channel_, channelCmd ) =
                        Channel.join topic channel
                in
                ( Model { model | channel = channel_ }, channelCmd )

            Connecting ->
                ( queueJoin topic (Model model), Cmd.none )

            Disconnecting ->
                ( queueJoin topic (Model model), Cmd.none )

            Disconnected _ ->
                queueJoin topic (Model model)
                    |> connect


{-| Join a `List` of Channels.

The [join](#join)s will be batched together, the order in which the requests
will reach their respective Channels at the `Elixir` end is undetermined.

-}
joinAll : List Topic -> Model -> ( Model, Cmd Msg )
joinAll topics (Model model) =
    batchWithParams [ ( join, topics ) ] (Model model)


{-| Leave a Channel referenced by the [Topic](#Topic).
-}
leave : Topic -> Model -> ( Model, Cmd Msg )
leave topic (Model model) =
    case Socket.currentState model.socket of
        Connected ->
            let
                ( channel, channelCmd ) =
                    Channel.leave topic model.channel
            in
            ( Model { model | channel = channel }, channelCmd )

        _ ->
            ( Model { model | channel = Channel.queueLeave topic model.channel }, Cmd.none )


{-| Leave all joined Channels.
-}
leaveAll : Model -> ( Model, Cmd Msg )
leaveAll (Model model) =
    batchWithParams [ ( leave, Channel.allJoined model.channel ) ] (Model model)


{-| Push a message to a Channel.

    import Json.Encode as JE
    import Phoenix exposing (pushConfig)

    Phoenix.push
        { pushConfig
        | topic = "topic:subTopic"
        , event = "event1"
        , payload =
            JE.object
                [("foo", JE.string "bar")]
        }
        model.phoenix

-}
push : PushConfig -> Model -> ( Model, Cmd Msg )
push ({ topic } as config) (Model ({ channel } as model)) =
    let
        ( push_, ref ) =
            Push.preFlight config model.push
    in
    if Channel.isJoined topic channel then
        let
            ( p, cmd ) =
                Push.send ref push_
        in
        ( Model { model | push = p }, cmd )

    else if Channel.joinIsQueued topic channel then
        ( Model { model | push = push_ }, Cmd.none )

    else
        join topic <|
            Model
                { model
                    | push = push_
                    , channel = Channel.queueJoin topic channel
                }


{-| Add the [Event](#Event) you want to receive from the Channel identified by
[Topic](#Topic).
-}
addEvent : Topic -> Event -> Model -> Cmd Msg
addEvent topic event (Model { portConfig }) =
    Phoenix.Channel.on
        { topic = topic
        , event = event
        }
        portConfig.phoenixSend


{-| Add the [Event](#Event)s you want to receive from the Channel identified by
[Topic](#Topic).
-}
addEvents : Topic -> List Event -> Model -> Cmd Msg
addEvents topic events (Model { portConfig }) =
    Phoenix.Channel.allOn
        { topic = topic
        , events = events
        }
        portConfig.phoenixSend


{-| Remove an [Event](#Event) you no longer want to receive from the Channel
identified by [Topic](#Topic).
-}
dropEvent : Topic -> Event -> Model -> Cmd Msg
dropEvent topic event (Model { portConfig }) =
    Phoenix.Channel.off
        { topic = topic
        , event = event
        }
        portConfig.phoenixSend


{-| Remove [Event](#Event)s you no longer want to receive from the Channel
identified by [Topic](#Topic).
-}
dropEvents : Topic -> List Event -> Model -> Cmd Msg
dropEvents topic events (Model { portConfig }) =
    Phoenix.Channel.allOff
        { topic = topic
        , events = events
        }
        portConfig.phoenixSend



{- Subscriptions -}


{-| Receive `Msg`s from the Socket, Channels and Phoenix Presence.

    import Phoenix

    type alias Model =
        { phoenix : Phoenix.Model
            ...
        }

    type Msg
        = PhoenixMsg Phoenix.Msg
        | ...

    subscriptions : Model -> Sub Msg
    subscriptions model =
        Sub.map PhoenixMsg <|
            Phoenix.subscriptions model.phoenix

-}
subscriptions : Model -> Sub Msg
subscriptions (Model model) =
    Sub.batch
        [ Phoenix.Channel.subscriptions
            ReceivedChannelMsg
            model.portConfig.channelReceiver
        , Phoenix.Socket.subscriptions
            ReceivedSocketMsg
            model.portConfig.socketReceiver
        , Phoenix.Presence.subscriptions
            ReceivedPresenceMsg
            model.portConfig.presenceReceiver
        , if Push.timeoutsExist model.push then
            Time.every 1000 TimeoutTick

          else
            Sub.none
        ]



{- Update -}


{-|

    import Phoenix

    type alias Model =
        { phoenix : Phoenix.Model
            ...
        }

    type Msg
        = PhoenixMsg Phoenix.Msg
        | ...

    update : Msg -> Model -> (Model, Cmd Msg)
    update msg model =
        case msg of
            PhoenixMsg subMsg ->
                let
                    (phoenix, phoenixCmd, phoenixMsg) =
                        Phoenix.update subMsg model.phoenix
                in
                case phoenixMsg of
                    ...

                _ ->
                    ( { model | phoenix = phoenix }
                    , Cmd.map PhoenixMsg phoenixCmd
                    )

            _ ->
                (model, Cmd.none)

-}
update : Msg -> Model -> ( Model, Cmd Msg, PhoenixMsg )
update msg (Model model) =
    case msg of
        TimeoutTick _ ->
            let
                ( toSend, toKeep ) =
                    Push.timeoutTick model.push
                        |> Push.partitionTimeouts isTimeToRetryPush
                        |> Tuple.mapFirst Push.resetTimeoutTick
                        |> Tuple.mapFirst (Push.map currentBackoffComplete)
                        |> Tuple.mapSecond (Push.filter retryStrategiesToKeep)

                ( push_, pushCmd ) =
                    Push.sendAll toSend model.push
            in
            ( Model { model | push = Push.setTimeouts toKeep push_ }
            , pushCmd
            , NoOp
            )

        ReceivedSocketMsg subMsg ->
            case subMsg of
                Phoenix.Socket.Opened ->
                    Model { model | socket = Socket.setReconnect False model.socket }
                        |> updateDisconnectReason Nothing
                        |> updateSocketState Connected
                        |> batchWithParams
                            [ ( join, queuedChannels (Model model) )
                            , ( leave, Channel.allQueuedLeaves model.channel )
                            ]
                        |> toPhoenixMsg (SocketMessage (StateChange Connected))

                Phoenix.Socket.Closed closedInfo ->
                    if Socket.reconnect model.socket then
                        connect (Model model)
                            |> toPhoenixMsg (SocketMessage (StateChange (Disconnected closedInfo)))

                    else if Socket.currentState model.socket == Disconnecting then
                        ( init model.portConfig
                            |> setConnectOptions (Socket.options model.socket)
                            |> setConnectParams (Socket.params model.socket)
                            |> setJoinConfigs (Channel.joinConfigs model.channel)
                            |> setLeaveConfigs (Channel.leaveConfigs model.channel)
                        , Cmd.none
                        , SocketMessage (StateChange (Disconnected closedInfo))
                        )

                    else
                        Model model
                            |> updateDisconnectReason closedInfo.reason
                            |> updateSocketState (Disconnected closedInfo)
                            |> batchWithParams
                                [ ( join, queuedChannels (Model model) ) ]
                            |> toPhoenixMsg (SocketMessage (StateChange (Disconnected closedInfo)))

                Phoenix.Socket.Connecting ->
                    ( updateSocketState Connecting (Model model)
                    , Cmd.none
                    , SocketMessage (StateChange Connecting)
                    )

                Phoenix.Socket.Disconnecting ->
                    ( updateSocketState Disconnecting (Model model)
                    , Cmd.none
                    , SocketMessage (StateChange Disconnecting)
                    )

                Phoenix.Socket.Channel message ->
                    ( Model model
                    , Cmd.none
                    , SocketMessage (ChannelMessage message)
                    )

                Phoenix.Socket.Presence message ->
                    ( Model model
                    , Cmd.none
                    , SocketMessage (PresenceMessage message)
                    )

                Phoenix.Socket.Heartbeat message ->
                    ( Model model
                    , Cmd.none
                    , SocketMessage (Heartbeat message)
                    )

                Phoenix.Socket.Info socketInfo ->
                    case socketInfo of
                        Phoenix.Socket.All info ->
                            ( Model { model | socket = Socket.setInfo info model.socket }, Cmd.none, NoOp )

                        _ ->
                            ( Model model, Cmd.none, NoOp )

                Phoenix.Socket.Error reason ->
                    ( Model model, Cmd.none, SocketMessage (SocketError reason) )

                Phoenix.Socket.InternalError errorType ->
                    case errorType of
                        Phoenix.Socket.DecoderError error ->
                            ( Model model
                            , Cmd.none
                            , InternalError (DecoderError ("Socket : " ++ error))
                            )

                        Phoenix.Socket.InvalidMessage error ->
                            ( Model model
                            , Cmd.none
                            , InternalError (InvalidMessage ("Socket : " ++ error))
                            )

        ReceivedChannelMsg channelMsg ->
            case channelMsg of
                Phoenix.Channel.Closed topic ->
                    ( Model model, Cmd.none, ChannelResponse (ChannelClosed topic) )

                Phoenix.Channel.Error topic ->
                    ( Model model, Cmd.none, ChannelResponse (ChannelError topic) )

                Phoenix.Channel.JoinError topic payload ->
                    ( Model model, Cmd.none, ChannelResponse (JoinError topic payload) )

                Phoenix.Channel.JoinOk topic payload ->
                    let
                        ( push_, pushCmd ) =
                            Push.sendByTopic topic model.push
                    in
                    ( Model
                        { model
                            | channel = Channel.addJoin topic model.channel
                            , push = push_
                        }
                    , pushCmd
                    , ChannelResponse (JoinOk topic payload)
                    )

                Phoenix.Channel.JoinTimeout topic payload ->
                    ( Model model, Cmd.none, ChannelResponse (JoinTimeout topic payload) )

                Phoenix.Channel.LeaveOk topic ->
                    ( Model
                        { model
                            | channel =
                                Channel.dropLeave topic model.channel
                                    |> Channel.dropJoin topic
                        }
                    , Cmd.none
                    , ChannelResponse (LeaveOk topic)
                    )

                Phoenix.Channel.Message topic event payload ->
                    ( Model model, Cmd.none, ChannelEvent topic event payload )

                Phoenix.Channel.PushError topic event payload ref ->
                    ( Model { model | push = Push.dropSentByRef ref model.push }
                    , Cmd.none
                    , ChannelResponse (PushError topic event (Just ref) payload)
                    )

                Phoenix.Channel.PushOk topic event payload ref ->
                    ( Model { model | push = Push.dropSentByRef ref model.push }
                    , Cmd.none
                    , ChannelResponse (PushOk topic event (Just ref) payload)
                    )

                Phoenix.Channel.PushTimeout topic event payload ref ->
                    ( case Push.maybeRetryStrategy ref model.push of
                        Just Drop ->
                            Model { model | push = Push.dropSentByRef ref model.push }

                        Just _ ->
                            Model { model | push = Push.timedOut ref model.push }

                        Nothing ->
                            Model { model | push = Push.dropSentByRef ref model.push }
                    , Cmd.none
                    , ChannelResponse (PushTimeout topic event (Just ref) payload)
                    )

                Phoenix.Channel.InternalError errorType ->
                    case errorType of
                        Phoenix.Channel.DecoderError error ->
                            ( Model model
                            , Cmd.none
                            , InternalError (DecoderError ("Channel : " ++ error))
                            )

                        Phoenix.Channel.InvalidMessage topic error _ ->
                            ( Model model
                            , Cmd.none
                            , InternalError (InvalidMessage ("Channel : " ++ topic ++ " : " ++ error))
                            )

        ReceivedPresenceMsg presenceMsg ->
            case presenceMsg of
                Phoenix.Presence.Diff topic diff ->
                    ( Model { model | presence = Presence.addDiff topic diff model.presence }
                    , Cmd.none
                    , PresenceEvent (Diff topic diff)
                    )

                Phoenix.Presence.Join topic presence ->
                    ( Model { model | presence = Presence.addJoin topic presence model.presence }
                    , Cmd.none
                    , PresenceEvent (Join topic presence)
                    )

                Phoenix.Presence.Leave topic presence ->
                    ( Model { model | presence = Presence.addLeave topic presence model.presence }
                    , Cmd.none
                    , PresenceEvent (Leave topic presence)
                    )

                Phoenix.Presence.State topic state ->
                    ( Model { model | presence = Presence.setState topic state model.presence }
                    , Cmd.none
                    , PresenceEvent (State topic state)
                    )

                Phoenix.Presence.InternalError errorType ->
                    case errorType of
                        Phoenix.Presence.DecoderError error ->
                            ( Model model
                            , Cmd.none
                            , InternalError (DecoderError ("Presence : " ++ error))
                            )

                        Phoenix.Presence.InvalidMessage topic error ->
                            ( Model model
                            , Cmd.none
                            , InternalError (InvalidMessage ("Presence : " ++ topic ++ " : " ++ error))
                            )



{- Predicates -}


{-| Whether the Socket is connected or not.
-}
isConnected : Model -> Bool
isConnected (Model { socket }) =
    Socket.isConnected socket


{-| Determine if a Channel is in the queue to join.
-}
channelQueued : Topic -> Model -> Bool
channelQueued topic (Model { channel }) =
    Channel.joinIsQueued topic channel


{-| Determine if a Channel has joined successfully.
-}
channelJoined : Topic -> Model -> Bool
channelJoined topic (Model { channel }) =
    Channel.isJoined topic channel


{-| Determine if a Push has timed out and will be tried again in accordance
with it's [RetryStrategy](#RetryStrategy).

    pushTimedOut
        (\push -> push.ref == "custom ref")
        model.phoenix

-}
pushTimedOut : (PushConfig -> Bool) -> Model -> Bool
pushTimedOut compareFunc (Model model) =
    Push.hasTimedOut compareFunc model.push


{-| Determine if a Push is in the queue to be sent when its' Channel joins.

    pushQueued
        (\push -> push.ref == "custom ref")
        model.phoenix

-}
pushQueued : (PushConfig -> Bool) -> Model -> Bool
pushQueued compareFunc (Model model) =
    Push.isQueued compareFunc model.push


{-| Determine if a Push has been sent and is on it's way to the Elixir Channel.

    pushInFlight
        (\push -> push.event == "custom_event")
        model.phoenix

-}
pushInFlight : (PushConfig -> Bool) -> Model -> Bool
pushInFlight compareFunc (Model model) =
    Push.inFlight compareFunc model.push


{-| Determine if a Push is waiting to be received by its' Channel.

This means the [push](#push) could be in any off the following states:

  - in a queue waiting for its' Channel to be joined before being sent

  - in flight and on its way to the Channel

  - timed out and waiting to be tried again according to its'
    [RetryStrategy](#RetryStrategy)

This is useful if you just need to determine if a [push](#push) is being
actioned. Maybe you need to disable/hide a button until the
[PushOk](#ChannelResponse) message has been received?

    pushWaiting
        (\push -> push.event == "custom_event")
        model.phoenix

-}
pushWaiting : (PushConfig -> Bool) -> Model -> Bool
pushWaiting compareFunc model =
    pushQueued compareFunc model
        || pushInFlight compareFunc model
        || pushTimedOut compareFunc model


isTimeToRetryPush : String -> { a | retryStrategy : RetryStrategy, timeoutTick : Int } -> Bool
isTimeToRetryPush _ config =
    case config.retryStrategy of
        Every secs ->
            config.timeoutTick == secs

        Backoff (head :: _) _ ->
            config.timeoutTick == head

        Backoff [] (Just max) ->
            config.timeoutTick == max

        Backoff [] Nothing ->
            False

        Drop ->
            False


retryStrategiesToKeep : { a | retryStrategy : RetryStrategy } -> Bool
retryStrategiesToKeep { retryStrategy } =
    retryStrategy /= Drop && retryStrategy /= Backoff [] Nothing



{- Queries -}


{-| The current [state](#SocketState) of the Socket.
-}
socketState : Model -> SocketState
socketState (Model model) =
    Socket.currentState model.socket


{-| The current [state](#SocketState) of the Socket as a String.
-}
socketStateToString : Model -> String
socketStateToString (Model model) =
    case Socket.currentState model.socket of
        Connected ->
            "Connected"

        Connecting ->
            "Connecting"

        Disconnecting ->
            "Disconnecting"

        Disconnected _ ->
            "Disconnected"


{-| The current connection state of the Socket as a String.
-}
connectionState : Model -> String
connectionState (Model { socket }) =
    Socket.connectionState socket


{-| The reason the Socket disconnected.
-}
disconnectReason : Model -> Maybe String
disconnectReason (Model { socket }) =
    Socket.disconnectReason socket


{-| The endpoint URL for the Socket.
-}
endPointURL : Model -> String
endPointURL (Model { socket }) =
    Socket.endPointURL socket


{-| The protocol being used by the Socket.
-}
protocol : Model -> String
protocol (Model { socket }) =
    Socket.protocol socket


{-| Channels that are queued waiting to join.
-}
queuedChannels : Model -> List String
queuedChannels (Model { channel }) =
    Channel.allQueuedJoins channel


{-| Channels that have joined successfully.
-}
joinedChannels : Model -> List String
joinedChannels (Model { channel }) =
    Channel.allJoined channel


{-| Split a topic into it's component parts.
-}
topicParts : Topic -> List String
topicParts topic =
    String.split ":" topic


{-| Pushes that are queued and waiting for their Channel to join before being
sent.
-}
allQueuedPushes : Model -> Dict Topic (List PushConfig)
allQueuedPushes (Model model) =
    Push.allQueued model.push


{-| Retrieve a list of pushes, by [Topic](#Topic), that are queued and waiting
for their Channel to join before being sent.
-}
queuedPushes : Topic -> Model -> List PushConfig
queuedPushes topic (Model model) =
    Push.queued topic model.push


{-| Pushes that have timed out and are waiting to be sent again in accordance
with their [RetryStrategy](#RetryStrategy).

Pushes with a [RetryStrategy](#RetryStrategy) of `Drop`, won't make it here.

-}
timeoutPushes : Model -> Dict String (List PushConfig)
timeoutPushes (Model model) =
    Push.allTimeouts model.push


{-| Maybe get the number of seconds until a push is retried.

This is useful if you want to show a countdown timer to your users.

-}
pushTimeoutCountdown : (PushConfig -> Bool) -> Model -> Maybe Int
pushTimeoutCountdown compareFunc (Model model) =
    Push.timeoutCountdown compareFunc countdown model.push


countdown : { a | retryStrategy : RetryStrategy, timeoutTick : Int } -> Maybe Int
countdown config =
    case config.retryStrategy of
        Drop ->
            Nothing

        Every seconds ->
            Just (seconds - config.timeoutTick)

        Backoff (seconds :: _) _ ->
            Just (seconds - config.timeoutTick)

        Backoff [] (Just max) ->
            Just (max - config.timeoutTick)

        Backoff [] Nothing ->
            Nothing


{-| A list of Presences on the Channel referenced by [Topic](#Topic).
-}
presenceState : Topic -> Model -> List Presence
presenceState topic (Model model) =
    Presence.state topic model.presence


{-| A list of Presence diffs on the Channel referenced by [Topic](#Topic).
-}
presenceDiff : Topic -> Model -> List PresenceDiff
presenceDiff topic (Model model) =
    Presence.diff topic model.presence


{-| A list of Presences that have joined the Channel referenced by
[Topic](#Topic).
-}
presenceJoins : Topic -> Model -> List Presence
presenceJoins topic (Model model) =
    Presence.joins topic model.presence


{-| A list of Presences that have left the Channel referenced by
[Topic](#Topic).
-}
presenceLeaves : Topic -> Model -> List Presence
presenceLeaves topic (Model model) =
    Presence.leaves topic model.presence


{-| Maybe the last Presence to join the Channel referenced by [Topic](#Topic).
-}
lastPresenceJoin : Topic -> Model -> Maybe Presence
lastPresenceJoin topic (Model model) =
    Presence.lastJoin topic model.presence


{-| Maybe the last Presence to leave the Channel referenced by [Topic](#Topic).
-}
lastPresenceLeave : Topic -> Model -> Maybe Presence
lastPresenceLeave topic (Model model) =
    Presence.lastLeave topic model.presence



{- Setters -}


{-| Add some [ConnectOption](Phoenix.Socket#ConnectOption)s to set on the
Socket when it is created.

**Note:** This will overwrite any like for like
[ConnectOption](Phoenix.Socket.ConnectOption)s that have already been set.

    import Phoenix
    import Phoenix.Socket exposing (ConnectOption(..))
    import Ports.Phoenix as Ports

    type alias Model =
        { phoenix : Phoenix.Model
            ...
        }

    init : Model
    init =
        { phoenix =
            Phoenix.init Ports.config
                |> Phoenix.addConnectOptions
                    [ Timeout 7000
                    , HeartbeatIntervalMillis 2000
                    ]
                |> Phoenix.addConnectOptions
                    [ Timeout 5000 ]
            ...
        }

    -- List ConnectOption == [ Timeout 5000, HeartbeatIntervalMillis 2000 ]

-}
addConnectOptions : List Phoenix.Socket.ConnectOption -> Model -> Model
addConnectOptions options (Model ({ socket } as model)) =
    Model { model | socket = Socket.addOptions options socket }


{-| Provide the [ConnectOption](Phoenix.Socket#ConnectOption)s to set on the
Socket when it is created.

**Note:** This will replace _all_ previously set
[ConnectOption](Phoenix.Socket.ConnectOption)s.

    import Phoenix
    import Phoenix.Socket exposing (ConnectOption(..))
    import Ports.Phoenix as Ports

    type alias Model =
        { phoenix : Phoenix.Model
            ...
        }

    init : Model
    init =
        { phoenix =
            Phoenix.init Ports.config
                |> Phoenix.addConnectOptions
                    [ HeartbeatIntervalMillis 2000 ]
                |> Phoenix.setConnectOptions
                    [ Timeout 7000 ]
                |> Phoenix.setConnectOptions
                    [ Timeout 5000 ]
            ...
        }

    -- List ConnectOption == [ Timeout 5000 ]

-}
setConnectOptions : List Phoenix.Socket.ConnectOption -> Model -> Model
setConnectOptions options (Model ({ socket } as model)) =
    Model { model | socket = Socket.setOptions options socket }


{-| Provide some params to send to the `connect` function at the Elixir end.

    import Json.Encode as JE
    import Phoenix

    type alias Model =
        { phoenix : Phoenix.Model
            ...
        }

    init : Model
    init =
        { phoenix =
            Phoenix.init Ports.config
                |> Phoenix.setConnectParams
                    ( JE.object
                        [ ("username", JE.string "username")
                        , ("password", JE.string "password")
                        ]
                    )
            ...
        }

-}
setConnectParams : Value -> Model -> Model
setConnectParams params (Model ({ socket } as model)) =
    Model { model | socket = Socket.setParams (Just params) socket }


{-| Set a [JoinConfig](#JoinConfig) to be used when joining a Channel.

    import Phoenix exposing (joinConfig)
    import Ports.Phoenix as Port

    type alias Model =
        { phoenix : Phoenix.Model
            ...
        }

    init : Model
    init =
        { phoenix =
            Phoenix.init Port.config
                |> Phoenix.setJoinConfig
                    { joinConfig
                    | topic = "topic:subTopic"
                    , events = [ "event1", "event2" ]
                    }
            ...
        }

-}
setJoinConfig : JoinConfig -> Model -> Model
setJoinConfig config (Model ({ channel } as model)) =
    Model { model | channel = Channel.setJoinConfig config channel }


setJoinConfigs : Config Topic JoinConfig -> Model -> Model
setJoinConfigs configs (Model ({ channel } as model)) =
    Model { model | channel = Channel.setJoinConfigs configs channel }


{-| Set a [LeaveConfig](#LeaveConfig) to be used when leaving a Channel.

    import Phoenix
    import Ports.Phoenix as Port

    type alias Model =
        { phoenix : Phoenix.Model
            ...
        }

    init : Model
    init =
        { phoenix =
            Phoenix.init Port.config
                |> Phoenix.setLeaveConfig
                    { topic = "topic:subTopic"
                    , timeout = Just 5000
                    }
            ...
        }

-}
setLeaveConfig : LeaveConfig -> Model -> Model
setLeaveConfig config (Model ({ channel } as model)) =
    Model { model | channel = Channel.setLeaveConfig config channel }


setLeaveConfigs : Config Topic LeaveConfig -> Model -> Model
setLeaveConfigs configs (Model ({ channel } as model)) =
    Model { model | channel = Channel.setLeaveConfigs configs channel }


queueJoin : Topic -> Model -> Model
queueJoin topic (Model model) =
    Model { model | channel = Channel.queueJoin topic model.channel }


updateSocketState : SocketState -> Model -> Model
updateSocketState state (Model model) =
    Model { model | socket = Socket.setState state model.socket }


updateDisconnectReason : Maybe String -> Model -> Model
updateDisconnectReason maybeReason (Model model) =
    Model { model | socket = Socket.setDisconnectReason maybeReason model.socket }



{- Delete -}


{-| Cancel a [Push](#Push).

This will cancel pushes that are queued to be sent when their Channel joins. It
will also prevent pushes that timeout from being re-tried.

-}
dropPush : (PushConfig -> Bool) -> Model -> Model
dropPush compare (Model model) =
    Model { model | push = Push.drop compare model.push }


{-| Cancel a queued [Push](#Push) that is waiting for its' Channel to
[join](#join).

    dropQueuedPush
        (\push -> push.topic == "topic:subTopic")
        model.phoenix

-}
dropQueuedPush : (PushConfig -> Bool) -> Model -> Model
dropQueuedPush compareFunc (Model model) =
    Model { model | push = Push.dropQueued compareFunc model.push }


{-| Cancel a timed out [Push](#Push).

    dropTimeoutPush
        (\push -> push.topic == "topic:subTopic")
        model.phoenix

This will only work after a `push` has timed out and before it is re-tried.

-}
dropTimeoutPush : (PushConfig -> Bool) -> Model -> Model
dropTimeoutPush compareFunc (Model model) =
    Model { model | push = Push.dropTimeout compareFunc model.push }



{- Transform -}


{-| Helper function to use with [update](#update) in order to:

  - update the `phoenix` field on the `Model`
  - map the `Cmd Phoenix.Msg` generated by `Phoenix.update` to a `Cmd Msg`.

```
import Phoenix

type alias Model =
    { phoenix : Phoenix.Model
        ...
    }

type Msg
    = PhoenixMsg Phoenix.Msg
    | ...

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
    case msg of
        PhoenixMsg subMsg ->
            let
                (newModel, cmd, phoenixMsg) =
                  Phoenix.update subMsg model.phoenix
                        |> Phoenix.updateWith PhoenixMsg model
            in
            case phoenixMsg of
                ...

            _ ->
                (newModel, cmd)

        _ ->
            (model, Cmd.none)
```

**Note:** To use this function, `Phoenix.Model` needs to be stored on field `phoenix` on
the `Model`.

-}
updateWith :
    (Msg -> msg)
    -> { model | phoenix : Model }
    -> ( Model, Cmd Msg, PhoenixMsg )
    -> ( { model | phoenix : Model }, Cmd msg, PhoenixMsg )
updateWith toMsg model ( phoenix, phoenixCmd, phoenixMsg ) =
    ( { model | phoenix = phoenix }
    , Cmd.map toMsg phoenixCmd
    , phoenixMsg
    )


toPhoenixMsg : PhoenixMsg -> ( Model, Cmd Msg ) -> ( Model, Cmd Msg, PhoenixMsg )
toPhoenixMsg phoenixMsg ( model, cmd ) =
    ( model, cmd, phoenixMsg )


currentBackoffComplete : { a | retryStrategy : RetryStrategy } -> { a | retryStrategy : RetryStrategy }
currentBackoffComplete config =
    case config.retryStrategy of
        Backoff list max ->
            { config | retryStrategy = Backoff (List.drop 1 list) max }

        _ ->
            config


{-| Map the Phoenix [Model](#Model) and `Cmd` [Msg](#Msg) that is generated by
the [update](#update) function onto your `model` and `msg`.

    import Phoenix

    type alias Model =
        { websocket : Phoenix.Model
            ...
        }

    type Msg
        = PhoenixMsg Phoenix.Msg
        | ...


    update : Msg -> Model -> (Model, Cmd Msg)
    update msg model =
        case msg of
            PhoenixMsg subMsg ->
                let
                    (newModel, cmd, phoenixMsg) =
                        Phoenix.update subMsg model.websocket
                            |> Phoenix.map (\p m -> { m | websocket = p }) model PhoenixMsg
                in
                ...

-}
map : (Model -> model -> model) -> model -> (Msg -> msg) -> ( Model, Cmd Msg, PhoenixMsg ) -> ( model, Cmd msg, PhoenixMsg )
map toModel model toMsg ( phoenix, msg, phoenixMsg ) =
    ( toModel phoenix model, Cmd.map toMsg msg, phoenixMsg )


{-| Map your `msg` onto the Phoenix `Cmd` [Msg](#Msg) that is generated by the
`update` function. This is useful if you want to work with the Phoenix
[Model](#Model) some more before updating your own `Model`.

    import Phoenix

    type alias Model =
        { websocket : Phoenix.Model
            ...
        }

    type Msg
        = PhoenixMsg Phoenix.Msg
        | ...


    update : Msg -> Model -> (Model, Cmd Msg)
    update msg model =
        case msg of
            PhoenixMsg subMsg ->
                let
                    (phoenix, cmd, phoenixMsg) =
                        Phoenix.update subMsg model.websocket
                            |> Phoenix.mapMsg PhoenixMsg
                in
                ...

-}
mapMsg : (Msg -> msg) -> ( Model, Cmd Msg, PhoenixMsg ) -> ( Model, Cmd msg, PhoenixMsg )
mapMsg toMsg ( model, msg, phoenixMsg ) =
    ( model, Cmd.map toMsg msg, phoenixMsg )



{- Batching -}


{-| Batch a list of functions together.

    import Phoenix exposing (pushConfig)

    Phoenix.batch
        [ Phoenix.join "topic:subTopic3"
        , Phoenix.leave "topic:subTopic2"
        , Phoenix.push
            { pushConfig
            | topic = "topic:subTopic1"
            , event = "hello"
            }
        ]
        model.phoenix

-}
batch : List (Model -> ( Model, Cmd Msg )) -> Model -> ( Model, Cmd Msg )
batch functions model =
    List.foldl batchCmds ( model, Cmd.none ) functions


batchCmds : (Model -> ( Model, Cmd Msg )) -> ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
batchCmds func ( model, cmd ) =
    Tuple.mapSecond
        (\cmd_ -> Cmd.batch [ cmd, cmd_ ])
        (func model)


{-| Batch a list of parameters onto their functions.

    import Phoenix

    Phoenix.batchWithParams
        [ (Phoenix.join, [ "topic:subTopic1", "topic:subTopic2" ])
        , (Phoenix.leave, [ "topic:subTopic3", "topic:subTopic4" ])
        , (Phoenix.push, [ pushConfig1, pushConfig2, pushConfig3 ])
        ]
        model.phoenix

-}
batchWithParams : List ( a -> Model -> ( Model, Cmd Msg ), List a ) -> Model -> ( Model, Cmd Msg )
batchWithParams list model =
    batch
        (List.map (\( func, params ) -> List.map func params) list
            |> List.concat
        )
        model



{- Logging -}


{-| Log some data to the console.

    import Json.Encode as JE

    log "info" "foo"
        (JE.object
            [ ( "bar", JE.string "foo bar" ) ]
        )
        model.phoenix

    -- info: foo {bar: "foo bar"}

In order to receive any output in the console, you first need to activate the
socket's logger. There are two ways to do this. You can use the
[startLogging](#startLogging) function, or you can set the `Logger True`
[ConnectOption](#Phoenix.Socket#ConnectOption).

    import Phoenix
    import Phoenix.Socket exposing (ConnectOption(..))
    import Ports.Phoenix as Ports

    init : Model
    init =
        { phoenix =
            Phoenix.init Ports.config
                |> Phoenix.setConnectOptions
                    [ Logger True ]
        ...
        }

-}
log : String -> String -> Value -> Model -> Cmd Msg
log kind msg data (Model model) =
    Phoenix.Socket.log kind msg data model.portConfig.phoenixSend


{-| Activate the socket's logger function. This will log all messages that the
socket sends and receives.
-}
startLogging : Model -> Cmd Msg
startLogging (Model model) =
    Phoenix.Socket.startLogging model.portConfig.phoenixSend


{-| Deactivate the socket's logger function.
-}
stopLogging : Model -> Cmd Msg
stopLogging (Model model) =
    Phoenix.Socket.stopLogging model.portConfig.phoenixSend



{- Helpers -}


{-| A helper function for creating a [JoinConfig](#JoinConfig).

    import Phoenix exposing (joinConfig)

    { joinConfig
    | topic = "topic:subTopic"
    , events = [ "event1", "event2" ]
    }

-}
joinConfig : JoinConfig
joinConfig =
    { topic = ""
    , payload = JE.null
    , events = []
    , timeout = Nothing
    }


{-| A helper function for creating a [PushConfig](#PushConfig).

    import Phoenix exposing (pushConfig)

    { pushConfig
    | topic = "topic:subTopic"
    , event = "hello"
    }

-}
pushConfig : PushConfig
pushConfig =
    { topic = ""
    , event = ""
    , payload = JE.null
    , timeout = Nothing
    , retryStrategy = Drop
    , ref = Nothing
    }
