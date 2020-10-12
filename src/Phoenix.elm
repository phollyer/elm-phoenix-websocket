module Phoenix exposing
    ( Model
    , PortConfig, init
    , connect, addConnectOptions, setConnectOptions, Payload, setConnectParams
    , Topic, join, Event, JoinConfig, addJoinConfig
    , LeaveConfig, leave
    , RetryStrategy(..), Push, push, pushAll
    , subscriptions
    , addEvents, dropEvents
    , Msg, update
    , SocketState(..)
    , OriginalPayload, PushRef, ChannelResponse(..)
    , Presence, PresenceDiff, PresenceEvent(..)
    , Error(..)
    , InvalidMsg(..)
    , PhoenixMsg(..), phoenixMsg
    , socketState, isConnected, connectionState, endPointURL, protocol
    , queuedChannels, channelQueued, joinedChannels, channelJoined
    , queuedPushes, pushQueued, dropQueuedPush
    , timeoutPushes, pushTimedOut, dropTimeoutPush, pushTimeoutCountdown
    , dropPush
    , presenceState, presenceDiff, presenceJoins, presenceLeaves, lastPresenceJoin, lastPresenceLeave
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
        { phoenix =
            Phoenix.init
                Ports.config
                []
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
                    (phoenix, phoenixCmd) =
                        Phoenix.update subMsg model.phoenix
                in
                ( { model | phoenix = phoenix}
                , Cmd.map PhoenixMsg phoenixCmd
                )
            ...


    -- Subscribe to receive Phoenix Msgs

    subscriptions : Model -> Sub Msg
    subscriptions model =
        Sub.map PhoenixMsg <|
            Phoenix.subscriptions
                model.phoenix


# Model

@docs Model


# Initialising the Model

@docs PortConfig, init


# Connecting to the Socket

Connecting to the Socket is automatic on the first [push](#push) to a Channel.
However, if you want to connect before hand, you can use the
[connect](#connect) function.

If you want to set any [ConnectOption](Phoenix.Socket#ConnectOption)s on the
socket you can do so when you [init](#init) the [Model](#Model), or use the
[addConnectOptions](#addConnectOptions) or
[setConnectOptions](#setConnectOptions) functions.

If you want to send any params to the Socket when it connects at the Elixir
end, such as authenticating a user for example, then you can use the
[setConnectParams](#setConnectParams) function.

@docs connect, addConnectOptions, setConnectOptions, Payload, setConnectParams


# Joining a Channel

Joining a Channel is automatic on the first [push](#push) to the Channel.
However, if you want to join before hand, you can use the [join](#join)
function.

If you want to send any params to the Channel when you join at the Elixir end
you can use the [addJoinConfig](#addJoinConfig) function.

@docs Topic, join, Event, JoinConfig, addJoinConfig


# Leaving a Channel

@docs LeaveConfig, leave


# Talking to Channels

When pushing an event to a Channel, opening the Socket, and joining the
Channel is handled automatically. Pushes will be queued until the Channel has
been joined, at which point, any queued pushes will be sent in a batch.

See [Connecting to the Socket](#connecting-to-the-socket) and
[Joining a Channel](#joining-a-channel) for more details on handling connecting
and joining manually.

If the Socket is open and the Channel already joined, the push will be sent
immediately.


## Pushing

@docs RetryStrategy, Push, push, pushAll


## Receiving

@docs subscriptions


### Incoming Events

@docs addEvents, dropEvents


# Update

@docs Msg, update


## Pattern Matching


### Socket

@docs SocketState


### Channel

@docs OriginalPayload, PushRef, ChannelResponse

### Phoenix Presence

@docs Presence, PresenceDiff, PresenceEvent


### Errors

@docs Error


### Invalid Messages

@docs InvalidMsg


### PhoenixMsg

@docs PhoenixMsg, phoenixMsg


# Helpers


## Socket

@docs socketState, isConnected, connectionState, endPointURL, protocol


## Channels

@docs queuedChannels, channelQueued, joinedChannels, channelJoined


## Pushes

@docs queuedPushes, pushQueued, dropQueuedPush

@docs timeoutPushes, pushTimedOut, dropTimeoutPush, pushTimeoutCountdown

@docs dropPush


## Presence Information

@docs presenceState, presenceDiff, presenceJoins, presenceLeaves, lastPresenceJoin, lastPresenceLeave


## Debugging and Error Handling


### Logging

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
import Internal.Dict as Dict
import Internal.SocketInfo as SocketInfo
import Json.Encode as JE exposing (Value)
import Phoenix.Channel as Channel
import Phoenix.Presence as Presence
import Phoenix.Socket as Socket
import Set exposing (Set)
import Time


{-| The model that carries the internal state.

This is an opaque type, so use the provided API to interact with it.

-}
type Model
    = Model
        { queuedChannels : Set Topic
        , joinedChannels : Set Topic
        , connectOptions : List Socket.ConnectOption
        , connectParams : Payload
        , joinConfigs : Dict Topic JoinConfig
        , phoenixMsg : PhoenixMsg
        , portConfig : PortConfig
        , presenceDiff : Dict Topic (List PresenceDiff)
        , presenceJoin : Dict Topic (List Presence)
        , presenceLeave : Dict Topic (List Presence)
        , presenceState : Dict Topic (List Presence)
        , pushCount : Int
        , queuedPushes : Dict Int InternalPush
        , socketInfo : SocketInfo.Info
        , socketState : SocketState
        , timeoutPushes : Dict Int InternalPush
        }


{-| A type alias representing the ports that are needed to communicate with JS.
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


{-| Initialize the [Model](#Model) by providing the `ports` that enable
communication with JS and any [ConnectOption](Phoenix.Socket#ConnectOption)s
you want to set on the socket.

The easiest way to provide the `ports` is to copy
[this file](https://github.com/phollyer/elm-phoenix-websocket/tree/master/ports)
into your `src`, and then use its `config` function as follows:

    import Phoenix
    import Phoenix.Socket as Socket
    import Ports.Phoenix as Ports

    init : Model
    init =
        { phoenix =
            Phoenix.init
                Ports.config
                [ Socket.Timeout 10000 ]
        ...
        }

-}
init : PortConfig -> List Socket.ConnectOption -> Model
init portConfig options =
    Model
        { queuedChannels = Set.empty
        , joinedChannels = Set.empty
        , connectOptions = options
        , connectParams = JE.null
        , joinConfigs = Dict.empty
        , phoenixMsg = NoOp
        , portConfig = portConfig
        , presenceDiff = Dict.empty
        , presenceJoin = Dict.empty
        , presenceLeave = Dict.empty
        , presenceState = Dict.empty
        , pushCount = 0
        , queuedPushes = Dict.empty
        , socketInfo = SocketInfo.init
        , socketState = Disconnected (Socket.ClosedInfo "" 0 False)
        , timeoutPushes = Dict.empty
        }



{- Connecting to the Socket -}


{-| Connect to the Socket.
-}
connect : Model -> ( Model, Cmd Msg )
connect (Model model) =
    case model.socketState of
        Disconnected _ ->
            ( Model model
            , Socket.connect
                model.connectOptions
                (Just model.connectParams)
                model.portConfig.phoenixSend
            )

        _ ->
            ( Model model
            , Cmd.none
            )


{-| Add some [ConnectOption](Phoenix.Socket#ConnectOption)s to set on the
Socket when it is created.

    import Phoenix.Socket as Socket

    addConnectOptions
        [ Socket.Timeout 7000
        , Socket.HeartbeatIntervalMillis 2000
        ]
        model.phoenix

**Note:** This will overwrite any
[ConnectOption](Phoenix.Socket.ConnectOption)s that have already been set.

    import Phoenix
    import Phoenix.Socket as Socket
    import Ports.Phoenix as Ports

    init =
        { phoenix =
            Phoenix.init Ports.config
                [ Socket.Timeout 7000
                , Socket.HeartbeatIntervalMillis 2000
                ]
                |> Phoenix.addConnectOptions [ Socket.Timeout 5000 ]
        ...
        }

    -- List ConnectOption == [ Socket.Timeout 5000, Socket.HeartbeatIntervalMillis 2000 ]

-}
addConnectOptions : List Socket.ConnectOption -> Model -> Model
addConnectOptions options (Model model) =
    updateConnectOptions
        (List.append model.connectOptions options)
        (Model model)


{-| Provide the [ConnectOption](Phoenix.Socket#ConnectOption)s to set on the
Socket when it is created.

**Note:** This will replace _all_ current
[ConnectOption](Phoenix.Socket.ConnectOption)s that have already been set.

    import Phoenix
    import Phoenix.Socket as Socket
    import Ports.Phoenix as Ports

    init =
        { phoenix =
            Phoenix.init Ports.config
                [ Socket.Timeout 7000
                , Socket.HeartbeatIntervalMillis 2000
                ]
                |> Phoenix.setConnectOptions [ Socket.Timeout 5000 ]
        ...
        }

    -- List ConnectOption == [ Socket.Timeout 5000 ]

-}
setConnectOptions : List Socket.ConnectOption -> Model -> Model
setConnectOptions options model =
    updateConnectOptions options model


{-| A type alias representing custom data that is sent to the Socket and your
Channels, and received from your Channels.

It is a
[Json.Encode.Value](https://package.elm-lang.org/packages/elm/json/latest/Json-Encode#Value).

-}
type alias Payload =
    Value


{-| Provide some params to send to the Socket when connecting at the Elixir
end.

    import Json.Encode as JE

    setConnectParams
        ( JE.object
            [ ("username", JE.string "username")
            , ("password", JE.string "password")
            ]
        )
        model.phoenix

-}
setConnectParams : Payload -> Model -> Model
setConnectParams params model =
    updateConnectParams params model



{- Joining a Channel -}


{-| A type alias representing the Channel topic id, for example
`"topic:subTopic"`.
-}
type alias Topic =
    String


{-| Join a Channel referenced by the [Topic](#Topic).

Connecting to the Socket is automatic if it has not already been opened.

If the Socket is not open, the `join` will be queued, and the Socket will
connect. Once the Socket is open, any queued `join`s will be attempted.

If the Socket is already open, the `join` will be attempted immediately.

-}
join : Topic -> Model -> ( Model, Cmd Msg )
join topic (Model model) =
    case model.socketState of
        Connected ->
            case Dict.get topic model.joinConfigs of
                Just joinConfig ->
                    ( addChannelBeingJoined topic (Model model)
                    , Channel.join
                        joinConfig
                        model.portConfig.phoenixSend
                    )

                Nothing ->
                    Model model
                        |> addJoinConfig
                            { topic = topic
                            , payload = Nothing
                            , events = []
                            , timeout = Nothing
                            }
                        |> join topic

        Disconnected _ ->
            Model model
                |> addChannelBeingJoined topic
                |> connect


{-| -}
type alias LeaveConfig =
    { topic : Topic
    , timeout : Maybe Int
    }


{-| -}
leave : LeaveConfig -> Model -> Cmd Msg
leave config (Model model) =
    Channel.leave config model.portConfig.phoenixSend


{-| A type alias representing an event that is sent to, or received from, a
Channel.

So if you have this handler in your Elixir Channel:

    def handle_in("new_msg", %{"msg" => msg, "id" => id}, socket) do
      broadcast(socket, "send_msg", %{id: id, text: msg})

      {:reply, :ok, socket}
    end

You would [Push](#Push) the `"new_msg"` `Event` and pattern match on the
`"send_msg"` `Event` when you handle the [ChannelEvent](#PhoenixMsg) in your
`update` function.

-}
type alias Event =
    String


{-| A type alias representing the optional config to use when joining a
Channel.

  - `topic` - The channel topic id, for example: `"topic:subTopic"`.

  - `payload` - Optional data to be sent to the Channel when joining.

  - `events` - A list of events to receive from the Channel.

  - `timeout` - Optional timeout, in ms, before retrying to join if the previous
    attempt failed.

-}
type alias JoinConfig =
    { topic : Topic
    , payload : Maybe Payload
    , events : List Event
    , timeout : Maybe Int
    }


{-| Add a [JoinConfig](#JoinConfig) to be used when joining a Channel
referenced by the [Topic](#Topic).

Multiple Channels are supported, so if you need/want to add multiple configs
all at once, you can pipeline as follows:

    model
        |> addJoinConfig config1
        |> addJoinConfig config2
        |> addJoinConfig config3

**Note 1:** Internally, [JoinConfg](#JoinConfig)s are stored by [Topic](#Topic),
so subsequent additions with the same [Topic](#Topic) will overwrite previous
ones.

**Note 2:** JoinConfigs need to be set prior to the Channel being joined.

-}
addJoinConfig : JoinConfig -> Model -> Model
addJoinConfig config (Model model) =
    updateJoinConfigs
        (Dict.insert config.topic config model.joinConfigs)
        (Model model)


joinChannels : Set Topic -> Model -> ( Model, Cmd Msg )
joinChannels topics model =
    Set.toList topics
        |> List.foldl
            (\topic ( model_, cmd ) ->
                join topic model_
                    |> Tuple.mapSecond
                        (\cmd_ -> Cmd.batch [ cmd_, cmd ])
            )
            ( model, Cmd.none )


addChannelBeingJoined : Topic -> Model -> Model
addChannelBeingJoined topic (Model model) =
    updateChannelsBeingJoined
        (Set.insert topic model.queuedChannels)
        (Model model)


dropChannelBeingJoined : Topic -> Model -> Model
dropChannelBeingJoined topic (Model model) =
    updateChannelsBeingJoined
        (Set.remove topic model.queuedChannels)
        (Model model)


addJoinedChannel : Topic -> Model -> Model
addJoinedChannel topic (Model model) =
    updateChannelsJoined
        (Set.insert topic model.joinedChannels)
        (Model model)


dropJoinedChannel : Topic -> Model -> Model
dropJoinedChannel topic (Model model) =
    updateChannelsJoined
        (Set.remove topic model.joinedChannels)
        (Model model)



{- Talking to Channels -}


{-| The retry strategy to use if a push times out.

  - `Drop` - Drop the push and don't try again.

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


{-| A type alias representing the config for pushing a message to a Channel.

  - `topic` - The Channel topic to send the push to.

  - `event` - The event to send to the Channel.

  - `payload` - The params to send with the push. If you don't need to send
    any params, set this to
    [Json.Encode.null](https://package.elm-lang.org/packages/elm/json/latest/Json-Encode#null).
    I decided not to make this a `Maybe` because it is expected that most of
    the time something will be sent.

  - `timeout` - Optional timeout in milliseconds to set on the push request.

  - `retryStrategy` - The retry strategy to use if the push times out.

  - `ref` - Optional reference you can provide that you can later use to
    identify the push. This is useful when using functions that need to find
    the push in order to do their thing, such as [dropPush](#dropPush) or
    [pushTimeoutCountdown](#pushTimeoutCountdown).

-}
type alias Push =
    { topic : Topic
    , event : Event
    , payload : Payload
    , timeout : Maybe Int
    , retryStrategy : RetryStrategy
    , ref : Maybe String
    }


type alias InternalPush =
    { push : Push
    , ref : Int
    , retryStrategy : RetryStrategy
    , timeoutTick : Int
    }


{-| Push a message to a Channel.

    import Json.Encode as JE
    import Phoenix

    Phoenix.push
        { topic = "post:elm_phoenix_websocket"
        , event = "new_comment"
        , payload =
            JE.object
                [ ("comment", JE.string "Wow, this is great.")
                , ("post_id", JE.int 1)
                ]
        , timeout = Just 5000
        , retryStrategy = Every 5
        , ref = Just "my_ref"
        }
        model.phoenix

-}
push : Push -> Model -> ( Model, Cmd Msg )
push pushConfig (Model model) =
    let
        pushRef =
            model.pushCount + 1

        internalConfig =
            { push = pushConfig
            , ref = pushRef
            , retryStrategy = pushConfig.retryStrategy
            , timeoutTick = 0
            }
    in
    Model model
        |> addPushToQueue internalConfig
        |> updatePushCount pushRef
        |> pushIfJoined internalConfig


addPushToQueue : InternalPush -> Model -> Model
addPushToQueue pushConfig (Model model) =
    updateQueuedPushes
        (Dict.insert pushConfig.ref pushConfig model.queuedPushes)
        (Model model)


dropQueuedInternalPush : Int -> Model -> Model
dropQueuedInternalPush ref (Model model) =
    updateQueuedPushes
        (Dict.remove ref model.queuedPushes)
        (Model model)


{-| Send a list of [Push](#Push)es to their Channels.

The [Push](#Push)es will be batched together and sent as a single `Cmd`. The
order in which they will arrive at the Elixir end is unknown.

As with a single [push](#push), if the Socket is not connected or the relevant
Channels joined, any [push](#push)es that need to be queued, will be, and then
sent when their respective Channels have joined.

-}
pushAll : List Push -> Model -> ( Model, Cmd Msg )
pushAll pushes model =
    sendQueuedPushes <|
        List.foldl
            (\pushConfig (Model model_) ->
                let
                    pushRef =
                        model_.pushCount + 1

                    internalConfig =
                        { push = pushConfig
                        , ref = pushRef
                        , retryStrategy = pushConfig.retryStrategy
                        , timeoutTick = 0
                        }
                in
                Model model_
                    |> addPushToQueue internalConfig
                    |> updatePushCount pushRef
            )
            model
            pushes


pushIfJoined : InternalPush -> Model -> ( Model, Cmd Msg )
pushIfJoined config (Model model) =
    if Set.member config.push.topic model.joinedChannels then
        ( Model model
        , Channel.push
            config.push
            model.portConfig.phoenixSend
        )

    else if Set.member config.push.topic model.queuedChannels then
        ( Model model
        , Cmd.none
        )

    else
        Model model
            |> addChannelBeingJoined config.push.topic
            |> join config.push.topic


pushIfConnected : InternalPush -> Model -> ( Model, Cmd Msg )
pushIfConnected config (Model model) =
    case model.socketState of
        Connected ->
            pushIfJoined
                config
                (Model model)

        Disconnected _ ->
            ( Model model
                |> addChannelBeingJoined config.push.topic
                |> addPushToQueue config
            , Socket.connect
                model.connectOptions
                (Just model.connectParams)
                model.portConfig.phoenixSend
            )


sendQueuedPushes : Model -> ( Model, Cmd Msg )
sendQueuedPushes (Model model) =
    sendAllPushes model.queuedPushes (Model model)


sendQueuedPushesByTopic : Topic -> Model -> ( Model, Cmd Msg )
sendQueuedPushesByTopic topic (Model model) =
    let
        ( toGo, toKeep ) =
            Dict.partition
                (\_ internalConfig -> internalConfig.push.topic == topic)
                model.queuedPushes
    in
    Model model
        |> updateQueuedPushes toKeep
        |> sendAllPushes toGo


sendTimeoutPushes : Model -> ( Model, Cmd Msg )
sendTimeoutPushes (Model model) =
    let
        ( toGo, toKeep ) =
            Dict.partition
                (\_ internalConfig ->
                    case internalConfig.retryStrategy of
                        Every secs ->
                            internalConfig.timeoutTick == secs

                        Backoff (head :: _) _ ->
                            internalConfig.timeoutTick == head

                        Backoff [] (Just max) ->
                            internalConfig.timeoutTick == max

                        Backoff [] Nothing ->
                            False

                        Drop ->
                            -- This branch should never match because
                            -- pushes with a Drop strategy should never
                            -- end up in this list.
                            False
                )
                model.timeoutPushes
                |> Tuple.mapFirst
                    (\outgoing ->
                        Dict.map
                            (\_ internalConfig ->
                                case internalConfig.retryStrategy of
                                    Backoff (_ :: next :: tail) max ->
                                        internalConfig
                                            |> updateRetryStrategy
                                                (Backoff (next :: tail) max)
                                            |> updateTimeoutTick 0

                                    _ ->
                                        updateTimeoutTick 0 internalConfig
                            )
                            outgoing
                    )
    in
    Model model
        |> updateTimeoutPushes
            (Dict.filter
                (\_ internalPush ->
                    not (internalPush.retryStrategy == Backoff [] Nothing)
                )
                toKeep
            )
        |> sendAllPushes toGo


sendAllPushes : Dict Int InternalPush -> Model -> ( Model, Cmd Msg )
sendAllPushes pushConfigs model =
    pushConfigs
        |> Dict.toList
        |> List.map Tuple.second
        |> List.foldl
            batchPush
            ( model, Cmd.none )


batchPush : InternalPush -> ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
batchPush pushConfig ( model, cmd ) =
    let
        ( model_, cmd_ ) =
            pushIfConnected
                pushConfig
                model
    in
    ( model_
    , Cmd.batch [ cmd, cmd_ ]
    )


addTimeoutPush : InternalPush -> Model -> Model
addTimeoutPush internalConfig (Model model) =
    updateTimeoutPushes
        (Dict.insert internalConfig.ref internalConfig model.timeoutPushes)
        (Model model)



{- Receiving -}


{-| Receive `Msg`s from the Socket, Channels and Phoenix Presence.

    import Phoenix

    type Msg
        = PhoenixMsg Phoenix.Msg
        | ...

    subscriptions : Model -> Sub Msg
    subscriptions model =
        Sub.map PhoenixMsg <|
            Phoenix.subscriptions
                model.phoenix

-}
subscriptions : Model -> Sub Msg
subscriptions (Model model) =
    Sub.batch
        [ Channel.subscriptions
            ReceivedChannelMsg
            model.portConfig.channelReceiver
        , Socket.subscriptions
            ReceivedSocketMsg
            model.portConfig.socketReceiver
        , Presence.subscriptions
            ReceivedPresenceMsg
            model.portConfig.presenceReceiver
        , if Dict.isEmpty model.timeoutPushes then
            Sub.none

          else
            Time.every 1000 TimeoutTick
        ]


{-| Add the [Event](#Event)s you want to receive from the Channel identified by
[Topic](#Topic).
-}
addEvents : Topic -> List Event -> Model -> ( Model, Cmd Msg )
addEvents topic events (Model model) =
    ( Model model
    , Channel.allOn
        { topic = topic
        , events = events
        }
        model.portConfig.phoenixSend
    )


{-| Remove [Event](#Event)s you no longer want to receive from the Channel
identified by [Topic](#Topic).
-}
dropEvents : Topic -> List Event -> Model -> ( Model, Cmd Msg )
dropEvents topic events (Model model) =
    ( Model model
    , Channel.allOff
        { topic = topic
        , events = events
        }
        model.portConfig.phoenixSend
    )



{- Update -}


{-| The `Msg` type that you pass into the [update](#update) function.

This is an opaque type as it carries the _raw_ `Msg` data from the lower level
[Socket](Phoenix.Socket#Msg), [Channel](Phoenix.Channel#Msg) and
[Presence](Phoenix.Presence#Msg) `Msg`s.

For pattern matching, use the [phoenixMsg](#phoenixMsg) function to return a
[PhoenixMsg](#PhoenixMsg) which has nicer pattern matching options.

-}
type Msg
    = ReceivedChannelMsg Channel.Msg
    | ReceivedPresenceMsg Presence.Msg
    | ReceivedSocketMsg Socket.Msg
    | TimeoutTick Time.Posix


{-| This is a standard `update` function that you should be used to.

    import Phoenix

    type Msg
        = PhoenixMsg Phoenix.Msg
        | ...

    update : Msg -> Model -> (Model, Cmd Msg)
    update msg model =
        case msg of
            PhoenixMsg subMsg ->
                let
                    (phoenix, phoenixCmd) =
                        Phoenix.update subMsg model.phoenix
                in
                ( { model | phoenix = phoenix}
                , Cmd.map PhoenixMsg phoenixCmd
                )

            ...

-}
update : Msg -> Model -> ( Model, Cmd Msg )
update msg (Model model) =
    case msg of
        ReceivedChannelMsg channelMsg ->
            case channelMsg of
                Channel.Closed topic ->
                    ( updatePhoenixMsg (ChannelClosed topic) (Model model), Cmd.none )

                Channel.Error topic ->
                    ( updatePhoenixMsg (Error (Channel topic)) (Model model), Cmd.none )

                Channel.JoinError topic payload ->
                    ( updatePhoenixMsg (ChannelResponse (JoinError topic payload)) (Model model), Cmd.none )

                Channel.JoinOk topic payload ->
                    Model model
                        |> addJoinedChannel topic
                        |> dropChannelBeingJoined topic
                        |> updatePhoenixMsg (ChannelResponse (JoinOk topic payload))
                        |> sendQueuedPushesByTopic topic

                Channel.JoinTimeout topic payload ->
                    ( updatePhoenixMsg (ChannelResponse (JoinTimeout topic payload)) (Model model), Cmd.none )

                Channel.LeaveOk topic ->
                    ( Model model
                        |> dropJoinedChannel topic
                        |> updatePhoenixMsg (ChannelResponse (LeaveOk topic))
                    , Cmd.none
                    )

                Channel.Message topic msgResult payloadResult ->
                    case ( msgResult, payloadResult ) of
                        ( Ok event, Ok payload ) ->
                            ( updatePhoenixMsg (ChannelEvent topic event payload) (Model model), Cmd.none )

                        _ ->
                            ( Model model, Cmd.none )

                Channel.PushError topic msgResult payloadResult refResult ->
                    case ( msgResult, payloadResult, refResult ) of
                        ( Ok msg_, Ok payload, Ok internalRef ) ->
                            let
                                pushRef =
                                    case Dict.get internalRef model.queuedPushes of
                                        Just internalConfig ->
                                            internalConfig.push.ref

                                        Nothing ->
                                            Just ""
                            in
                            ( Model model
                                |> dropQueuedInternalPush internalRef
                                |> updatePhoenixMsg (ChannelResponse (PushError topic msg_ pushRef payload))
                            , Cmd.none
                            )

                        _ ->
                            ( Model model, Cmd.none )

                Channel.PushOk topic msgResult payloadResult refResult ->
                    case ( msgResult, payloadResult, refResult ) of
                        ( Ok msg_, Ok payload, Ok internalRef ) ->
                            let
                                pushRef =
                                    case Dict.get internalRef model.queuedPushes of
                                        Just internalConfig ->
                                            internalConfig.push.ref

                                        Nothing ->
                                            Just ""
                            in
                            ( Model model
                                |> dropQueuedInternalPush internalRef
                                |> updatePhoenixMsg (ChannelResponse (PushOk topic msg_ pushRef payload))
                            , Cmd.none
                            )

                        _ ->
                            ( Model model, Cmd.none )

                Channel.PushTimeout topic msgResult payloadResult refResult ->
                    case ( msgResult, payloadResult, refResult ) of
                        ( Ok msg_, Ok payload, Ok internalRef ) ->
                            case Dict.get internalRef model.queuedPushes of
                                Just internalConfig ->
                                    let
                                        pushRef =
                                            internalConfig.push.ref

                                        responseModel =
                                            Model model
                                                |> dropQueuedInternalPush internalConfig.ref
                                                |> updatePhoenixMsg
                                                    (ChannelResponse (PushTimeout topic msg_ pushRef payload))
                                    in
                                    case internalConfig.retryStrategy of
                                        Drop ->
                                            ( responseModel, Cmd.none )

                                        _ ->
                                            ( addTimeoutPush internalConfig responseModel, Cmd.none )

                                Nothing ->
                                    ( updatePhoenixMsg
                                        (ChannelResponse (PushTimeout topic msg_ Nothing payload))
                                        (Model model)
                                    , Cmd.none
                                    )

                        _ ->
                            ( Model model, Cmd.none )

                Channel.InvalidMsg topic invalidMsg payload ->
                    ( updatePhoenixMsg (InvalidMsg (ChannelMsg topic invalidMsg payload)) (Model model), Cmd.none )

        ReceivedPresenceMsg presenceMsg ->
            case presenceMsg of
                Presence.Diff topic diffResult ->
                    case diffResult of
                        Ok diff ->
                            ( Model model
                                |> addPresenceDiff topic diff
                                |> updatePhoenixMsg (PresenceEvent (Diff topic diff))
                            , Cmd.none
                            )

                        _ ->
                            ( Model model, Cmd.none )

                Presence.Join topic presenceResult ->
                    case presenceResult of
                        Ok presence ->
                            ( Model model
                                |> addPresenceJoin topic presence
                                |> updatePhoenixMsg (PresenceEvent (Join topic presence))
                            , Cmd.none
                            )

                        _ ->
                            ( Model model, Cmd.none )

                Presence.Leave topic presenceResult ->
                    case presenceResult of
                        Ok presence ->
                            ( Model model
                                |> addPresenceLeave topic presence
                                |> updatePhoenixMsg (PresenceEvent (Leave topic presence))
                            , Cmd.none
                            )

                        _ ->
                            ( Model model, Cmd.none )

                Presence.State topic stateResult ->
                    case stateResult of
                        Ok state ->
                            ( Model model
                                |> replacePresenceState topic state
                                |> updatePhoenixMsg (PresenceEvent (State topic state))
                            , Cmd.none
                            )

                        _ ->
                            ( Model model, Cmd.none )

                Presence.InvalidMsg topic message ->
                    ( updatePhoenixMsg (InvalidMsg (PresenceMsg topic message)) (Model model)
                    , Cmd.none
                    )

        ReceivedSocketMsg subMsg ->
            case subMsg of
                Socket.Opened ->
                    Model model
                        |> updateSocketState Connected
                        |> updatePhoenixMsg (StateChanged Connected)
                        |> joinChannels model.queuedChannels

                Socket.Closed infoResult ->
                    case infoResult of
                        Ok info ->
                            ( Model model
                                |> updateSocketState (Disconnected info)
                                |> updatePhoenixMsg (StateChanged (Disconnected info))
                            , Cmd.none
                            )

                        _ ->
                            ( Model model, Cmd.none )

                Socket.Error result ->
                    case result of
                        Ok _ ->
                            ( updatePhoenixMsg (Error Socket) (Model model)
                            , Cmd.none
                            )

                        Err _ ->
                            ( Model model
                            , Cmd.none
                            )

                Socket.Message result ->
                    case result of
                        Ok message ->
                            ( updatePhoenixMsg (SocketMessage message) (Model model)
                            , Cmd.none
                            )

                        Err _ ->
                            ( Model model
                            , Cmd.none
                            )

                Socket.Heartbeat result ->
                    case result of
                        Ok message ->
                            ( updatePhoenixMsg (Heartbeat message) (Model model)
                            , Cmd.none
                            )

                        Err _ ->
                            ( Model model
                            , Cmd.none
                            )

                Socket.Info infoResponse ->
                    case infoResponse of
                        Socket.All result ->
                            case result of
                                Ok info ->
                                    ( Model model
                                        |> updateSocketInfo info
                                        |> updatePhoenixMsg NoOp
                                    , Cmd.none
                                    )

                                Err _ ->
                                    ( Model model
                                    , Cmd.none
                                    )

                        _ ->
                            ( updatePhoenixMsg NoOp (Model model), Cmd.none )

                Socket.InvalidMsg message ->
                    ( updatePhoenixMsg (InvalidMsg (SocketMsg message)) (Model model)
                    , Cmd.none
                    )

        TimeoutTick _ ->
            Model model
                |> timeoutTick
                |> sendTimeoutPushes


timeoutTick : Model -> Model
timeoutTick (Model model) =
    updateTimeoutPushes
        (Dict.map
            (\_ internalPushConfig ->
                updateTimeoutTick
                    (internalPushConfig.timeoutTick + 1)
                    internalPushConfig
            )
            model.timeoutPushes
        )
        (Model model)


addPresenceDiff : Topic -> PresenceDiff -> Model -> Model
addPresenceDiff topic diff (Model model) =
    updatePresenceDiff
        (Dict.prependOne topic diff model.presenceDiff)
        (Model model)


addPresenceJoin : Topic -> Presence -> Model -> Model
addPresenceJoin topic presence (Model model) =
    updatePresenceJoin
        (Dict.prependOne topic presence model.presenceJoin)
        (Model model)


addPresenceLeave : Topic -> Presence -> Model -> Model
addPresenceLeave topic presence (Model model) =
    updatePresenceLeave
        (Dict.prependOne topic presence model.presenceLeave)
        (Model model)


replacePresenceState : Topic -> List Presence -> Model -> Model
replacePresenceState topic state (Model model) =
    updatePresenceState
        (Dict.insert topic state model.presenceState)
        (Model model)


{-| -}
type SocketState
    = Connected
    | Disconnected
        { reason : String
        , code : Int
        , wasClean : Bool
        }


{-| A type alias representing the `ref` set on the original [push](#PushConfig).
-}
type alias PushRef =
    Maybe String


{-| A type alias representing the original payload that was sent with the
[push](#PushConfig).
-}
type alias OriginalPayload =
    Payload


{-| -}
type ChannelResponse
    = JoinOk Topic Payload
    | JoinError Topic Payload
    | JoinTimeout Topic OriginalPayload
    | PushOk Topic Event PushRef Payload
    | PushError Topic Event PushRef Payload
    | PushTimeout Topic Event PushRef OriginalPayload
    | LeaveOk Topic


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


{-| -}
type PresenceEvent
    = Join Topic Presence
    | Leave Topic Presence
    | State Topic (List Presence)
    | Diff Topic PresenceDiff


{-| The `Error` type is received when the JS `onError` function fires for the
Socket or a Channel. No useful information is provided by the Socket or the
Channel, so all that can be returned to Elm is the Channel [Topic](#Topic).

`JoinError`s or `PushError`s received by a [ChannelResponse](#ChannelResponse)
are not considered errors in this context.

-}
type Error
    = Channel Topic
    | Socket


{-| The `InvalidMsg` type is received when a message comes in from JS that
cannot be handled. This should never happen, but if it does, it is because the
JS is out of sync with this package.

If you ever receive this message, please
[raise an issue](https://github.com/phollyer/elm-phoenix-websocket/issues).

-}
type InvalidMsg
    = SocketMsg String
    | ChannelMsg Topic String Payload
    | PresenceMsg Topic String


{-| The `Msg`s that you can pattern match on in your `update` function.
-}
type PhoenixMsg
    = NoOp
    | StateChanged SocketState
    | ChannelResponse ChannelResponse
    | ChannelEvent Topic Event Payload
    | ChannelClosed Topic
    | PresenceEvent PresenceEvent
    | SocketMessage
        { joinRef : Maybe String
        , ref : Maybe String
        , topic : String
        , event : String
        , payload : Value
        }
    | Heartbeat
        { joinRef : Maybe String
        , ref : Maybe String
        , topic : String
        , event : String
        , payload : Value
        }
    | Error Error
    | InvalidMsg InvalidMsg


{-| Retrieve the [PhoenixMsg](#PhoenixMsg). Use it to pattern match on.

    import Phoenix

    type alias Model =
        { phoenix : Phoenix.Model
        ...
        }

    type Msg
        = ReceivedPhoenixMsg Phoenix.Msg
        | ...

    update : Msg -> Model -> (Model, Cmd Msg)
    update msg model =
        case msg of
            ReceivedPhoenixMsg subMsg ->
                let
                    (phoenix, phoenixCmd) =
                        Phoenix.update subMsg model.phoenix
                in
                case Phoenix.phoenixMsg phoenix of
                    ChannelResponse (JoinOk "topic:subTopic" payload) ->
                        ...

                    StateChange state ->
                        case state of
                            Connected ->
                                ...

                            Disconnected {reason, code, wasClean} ->
                                ...

                    ChannelEvent topic event payload ->
                        ...

-}
phoenixMsg : Model -> PhoenixMsg
phoenixMsg (Model model) =
    model.phoenixMsg



{- Accessing the Model -}
{- Socket -}


{-| The current [state](#SocketState) of the Socket.
-}
socketState : Model -> SocketState
socketState (Model model) =
    model.socketState


{-| Whether the Socket is connected or not.
-}
isConnected : Model -> Bool
isConnected (Model model) =
    model.socketInfo.isConnected


{-| The current connection state of the Socket as a String.
-}
connectionState : Model -> String
connectionState (Model model) =
    model.socketInfo.connectionState


{-| The endpoint URL for the Socket.
-}
endPointURL : Model -> String
endPointURL (Model model) =
    model.socketInfo.endPointURL


{-| The protocol being used by the Socket.
-}
protocol : Model -> String
protocol (Model model) =
    model.socketInfo.protocol



{- Channel -}


{-| Channels that are queued waiting to join.
-}
queuedChannels : Model -> Set String
queuedChannels (Model model) =
    model.queuedChannels


{-| Channels that have joined successfully.
-}
joinedChannels : Model -> Set String
joinedChannels (Model model) =
    model.joinedChannels


{-| Determine if a Channel is in the queue to join.
-}
channelQueued : Topic -> Model -> Bool
channelQueued topic (Model model) =
    Set.member topic model.queuedChannels


{-| Determine if a Channel has joined successfully.
-}
channelJoined : Topic -> Model -> Bool
channelJoined topic (Model model) =
    Set.member topic model.joinedChannels



{- Pushes -}


{-| Pushes that are queued and waiting for their Channel to join before being
sent.
-}
queuedPushes : Model -> Dict Topic (List Push)
queuedPushes (Model model) =
    Dict.foldl
        (\_ internalPush queued ->
            Dict.update
                internalPush.push.topic
                (\maybeQueue ->
                    case maybeQueue of
                        Nothing ->
                            Just [ internalPush.push ]

                        Just queue ->
                            Just (internalPush.push :: queue)
                )
                queued
        )
        Dict.empty
        model.queuedPushes


{-| Determine if a Push is in the queue to be sent when its' Channel joins.

    pushQueued
        (\push -> push.ref == "custom ref")
        model.phoenix

-}
pushQueued : (Push -> Bool) -> Model -> Bool
pushQueued compareFunc (Model model) =
    model.queuedPushes
        |> Dict.partition
            (\_ v -> compareFunc v.push)
        |> Tuple.first
        |> Dict.isEmpty
        |> not


{-| Cancel a queued [Push](#Push) that is waiting for its' Channel to
[join](#join).

    dropQueuedPush
        (\push -> push.topic == "topic:subTopic")
        model.phoenix

-}
dropQueuedPush : (Push -> Bool) -> Model -> Model
dropQueuedPush compare (Model model) =
    updateQueuedPushes
        (Dict.filter
            (\_ internalPush -> not (compare internalPush.push))
            model.queuedPushes
        )
        (Model model)


{-| Pushes that have timed out and are waiting to be sent again in accordance
with their [RetryStrategy](#RetryStrategy).

Pushes with a [RetryStrategy](#RetryStrategy) of `Drop`, won't make it here.

-}
timeoutPushes : Model -> Dict String (List Push)
timeoutPushes (Model model) =
    Dict.foldl
        (\_ internalPush queued ->
            Dict.update
                internalPush.push.topic
                (\maybeQueue ->
                    case maybeQueue of
                        Nothing ->
                            Just [ internalPush.push ]

                        Just queue ->
                            Just (internalPush.push :: queue)
                )
                queued
        )
        Dict.empty
        model.timeoutPushes


{-| Determine if a Push has timed out and will be tried again in accordance
with it's [RetryStrategy](#RetryStrategy).

    pushTimedOut
        (\push -> push.ref == "custom ref")
        model.phoenix

-}
pushTimedOut : (Push -> Bool) -> Model -> Bool
pushTimedOut compareFunc (Model model) =
    model.timeoutPushes
        |> Dict.partition
            (\_ v -> compareFunc v.push)
        |> Tuple.first
        |> Dict.isEmpty
        |> not


{-| Cancel a timed out [Push](#Push).

    dropTimeoutPush
        (\push -> push.topic == "topic:subTopic")
        model.phoenix

-}
dropTimeoutPush : (Push -> Bool) -> Model -> Model
dropTimeoutPush compare (Model model) =
    updateTimeoutPushes
        (Dict.filter
            (\_ internalPush ->
                not (compare internalPush.push)
            )
            model.timeoutPushes
        )
        (Model model)


{-| Maybe get the number of seconds until a push is retried.

This is useful if you want to show a countdown timer to your users.

-}
pushTimeoutCountdown : (Push -> Bool) -> Model -> Maybe Int
pushTimeoutCountdown compareFunc (Model model) =
    let
        internalPush =
            model.timeoutPushes
                |> Dict.partition
                    (\_ v -> compareFunc v.push)
                |> Tuple.first
    in
    if internalPush == Dict.empty then
        Nothing

    else
        case Dict.values internalPush of
            first :: _ ->
                case first.push.retryStrategy of
                    Drop ->
                        Nothing

                    Every seconds ->
                        Just (seconds - first.timeoutTick)

                    Backoff (seconds :: _) _ ->
                        Just (seconds - first.timeoutTick)

                    Backoff [] (Just max) ->
                        Just (max - first.timeoutTick)

                    Backoff [] Nothing ->
                        Nothing

            [] ->
                Nothing


{-| Cancel a [Push](#Push), regardless of if it is in the queue to be sent when
its' Channel joins, or if it has timed out.
-}
dropPush : (Push -> Bool) -> Model -> Model
dropPush compare model =
    model
        |> dropQueuedPush compare
        |> dropTimeoutPush compare



{- Presence -}


{-| A list of Presences on the Channel referenced by [Topic](#Topic).
-}
presenceState : Topic -> Model -> List Presence
presenceState topic (Model model) =
    Dict.get topic model.presenceState
        |> Maybe.withDefault []


{-| A list of Presence diffs on the Channel referenced by [Topic](#Topic).
-}
presenceDiff : Topic -> Model -> List PresenceDiff
presenceDiff topic (Model model) =
    Dict.get topic model.presenceDiff
        |> Maybe.withDefault []


{-| A list of Presences that have joined the Channel referenced by
[Topic](#Topic).
-}
presenceJoins : Topic -> Model -> List Presence
presenceJoins topic (Model model) =
    Dict.get topic model.presenceJoin
        |> Maybe.withDefault []


{-| A list of Presences that have left the Channel referenced by
[Topic](#Topic).
-}
presenceLeaves : Topic -> Model -> List Presence
presenceLeaves topic (Model model) =
    Dict.get topic model.presenceLeave
        |> Maybe.withDefault []


{-| Maybe the last Presence to join the Channel referenced by [Topic](#Topic).
-}
lastPresenceJoin : Topic -> Model -> Maybe Presence
lastPresenceJoin topic (Model model) =
    Dict.get topic model.presenceJoin
        |> Maybe.withDefault []
        |> List.head


{-| Maybe the last Presence to leave the Channel referenced by [Topic](#Topic).
-}
lastPresenceLeave : Topic -> Model -> Maybe Presence
lastPresenceLeave topic (Model model) =
    Dict.get topic model.presenceLeave
        |> Maybe.withDefault []
        |> List.head



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
[startLogging](#startLogging) function, or you can pass the `Logger True`
[ConnectOption](#Phoenix.Socket#ConnectOption) to the [init](#init) function.

    import Phoenix
    import Phoenix.Socket exposing (ConnectOption(..))
    import Ports.Phoenix as Ports

    init : Model
    init =
        { phoenix =
            Phoenix.init
                Ports.config
                [ Logger True ]
        ...
        }

-}
log : String -> String -> Value -> Model -> Cmd Msg
log kind msg data (Model model) =
    Socket.log kind msg data model.portConfig.phoenixSend


{-| Activate the socket's logger function. This will log all messages that the
socket sends and receives.
-}
startLogging : Model -> Cmd Msg
startLogging (Model model) =
    Socket.startLogging model.portConfig.phoenixSend


{-| Deactivate the socket's logger function.
-}
stopLogging : Model -> Cmd Msg
stopLogging (Model model) =
    Socket.stopLogging model.portConfig.phoenixSend



{- Update Model Fields -}


updateChannelsBeingJoined : Set Topic -> Model -> Model
updateChannelsBeingJoined channels (Model model) =
    Model
        { model
            | queuedChannels = channels
        }


updateChannelsJoined : Set Topic -> Model -> Model
updateChannelsJoined channels (Model model) =
    Model
        { model
            | joinedChannels = channels
        }


updateConnectOptions : List Socket.ConnectOption -> Model -> Model
updateConnectOptions options (Model model) =
    Model
        { model
            | connectOptions = options
        }


updateConnectParams : Payload -> Model -> Model
updateConnectParams params (Model model) =
    Model
        { model
            | connectParams = params
        }


updateJoinConfigs : Dict String JoinConfig -> Model -> Model
updateJoinConfigs configs (Model model) =
    Model
        { model
            | joinConfigs = configs
        }


updatePhoenixMsg : PhoenixMsg -> Model -> Model
updatePhoenixMsg msg (Model model) =
    Model
        { model
            | phoenixMsg = msg
        }


updatePresenceDiff : Dict String (List PresenceDiff) -> Model -> Model
updatePresenceDiff diff (Model model) =
    Model
        { model
            | presenceDiff = diff
        }


updatePresenceJoin : Dict String (List Presence) -> Model -> Model
updatePresenceJoin presence (Model model) =
    Model
        { model
            | presenceJoin = presence
        }


updatePresenceLeave : Dict String (List Presence) -> Model -> Model
updatePresenceLeave presence (Model model) =
    Model
        { model
            | presenceLeave = presence
        }


updatePresenceState : Dict String (List Presence) -> Model -> Model
updatePresenceState state (Model model) =
    Model
        { model
            | presenceState = state
        }


updatePushCount : Int -> Model -> Model
updatePushCount count (Model model) =
    Model
        { model
            | pushCount = count
        }


updateQueuedPushes : Dict Int InternalPush -> Model -> Model
updateQueuedPushes queuedPushes_ (Model model) =
    Model
        { model
            | queuedPushes = queuedPushes_
        }


updateSocketInfo : SocketInfo.Info -> Model -> Model
updateSocketInfo info (Model model) =
    Model
        { model
            | socketInfo = info
        }


updateSocketState : SocketState -> Model -> Model
updateSocketState state (Model model) =
    Model
        { model
            | socketState = state
        }


updateTimeoutPushes : Dict Int InternalPush -> Model -> Model
updateTimeoutPushes pushConfig (Model model) =
    Model
        { model
            | timeoutPushes = pushConfig
        }


updateRetryStrategy : RetryStrategy -> InternalPush -> InternalPush
updateRetryStrategy retryStrategy pushConfig =
    { pushConfig
        | retryStrategy = retryStrategy
    }


updateTimeoutTick : Int -> InternalPush -> InternalPush
updateTimeoutTick tick internalPushConfig =
    { internalPushConfig
        | timeoutTick = tick
    }
