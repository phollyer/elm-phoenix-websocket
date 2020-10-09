module Phoenix exposing
    ( Model
    , PortConfig, init
    , connect, addConnectOptions, setConnectOptions, Payload, setConnectParams
    , Topic, join, JoinConfig, addJoinConfig
    , RetryStrategy(..), Push, push, pushAll
    , subscriptions
    , addIncoming, dropIncoming
    , Msg, update
    , SocketState(..), SocketInfo(..), SocketResponse(..)
    , OriginalPayload, OriginalMessage, PushRef, ChannelResponse(..), IncomingMessage
    , Message(..)
    , PresenceResponse(..)
    , PhoenixMsg(..), lastMsg
    , log, startLogging, stopLogging
    , requestConnectionState, requestEndpointURL, requestHasLogger, requestIsConnected, requestMakeRef, requestProtocol, requestSocketInfo
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

@docs Topic, join, JoinConfig, addJoinConfig


# Talking to Channels

When pushing a message to a Channel, opening the Socket, and joining the
Channel is handled automatically. Pushes will be queued until the Channel has
been joined, at which point, any queued pushes will be sent in a batch.

See [Connecting to the Socket](#connecting-to-the-socket) and
[Joining a Channel](#joining-a-channel) for more details on handling these
processes manually.

If the Socket is open and the Channel already joined, the push will be sent
immediately.


## Pushing Messages

@docs RetryStrategy, Push, push, pushAll


## Receiving Messages

@docs subscriptions


### Incoming

@docs addIncoming, dropIncoming


# Update

@docs Msg, update


## Pattern Matching


### Socket

@docs SocketState, SocketInfo, SocketResponse


### Channel

@docs OriginalPayload, OriginalMessage, PushRef, ChannelResponse, IncomingMessage


### Incoming Messages

@docs Message

### Pheonix Presence

@docs PresenceResponse


### Matching

@docs PhoenixMsg, lastMsg


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


# Requesting Socket Information

These functions allow you to request information from the socket. The request
will go out through the `port` and come back as [SocketInfo](#SocketInfo).

@docs requestConnectionState, requestEndpointURL, requestHasLogger, requestIsConnected, requestMakeRef, requestProtocol, requestSocketInfo

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
        { channelsBeingJoined : Set Topic
        , channelsJoined : Set Topic
        , connectOptions : List Socket.ConnectOption
        , connectParams : Payload
        , incomingChannelMessages : Dict String (List String)
        , invalidSocketEvents : List String
        , joinConfigs : Dict String JoinConfig
        , lastInvalidSocketEvent : Maybe String
        , phoenixMsg : PhoenixMsg
        , portConfig : PortConfig
        , presenceDiff : Dict String (List Presence.PresenceDiff)
        , presenceJoin : Dict String (List Presence.Presence)
        , presenceLeave : Dict String (List Presence.Presence)
        , presenceState : Dict String Presence.PresenceState
        , pushCount : Int
        , queuedPushes : Dict Int InternalPush
        , socketError : String
        , socketInfo : SocketInfo.Info
        , socketMessage : Maybe Socket.MessageConfig
        , socketMessages : List Socket.MessageConfig
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
init portConfig connectOptions =
    Model
        { channelsBeingJoined = Set.empty
        , channelsJoined = Set.empty
        , connectOptions = connectOptions
        , connectParams = JE.null
        , incomingChannelMessages = Dict.empty
        , invalidSocketEvents = []
        , joinConfigs = Dict.empty
        , lastInvalidSocketEvent = Nothing
        , phoenixMsg = NoOp
        , portConfig = portConfig
        , presenceDiff = Dict.empty
        , presenceJoin = Dict.empty
        , presenceLeave = Dict.empty
        , presenceState = Dict.empty
        , pushCount = 0
        , queuedPushes = Dict.empty
        , socketError = ""
        , socketInfo = SocketInfo.init
        , socketMessage = Nothing
        , socketMessages = []
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
Socket when connecting.

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
addConnectOptions connectOptions (Model model) =
    updateConnectOptions
        (List.append model.connectOptions connectOptions)
        (Model model)


{-| Provide some [ConnectOption](Phoenix.Socket#ConnectOption)s to set on the
Socket when connecting.

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
        model

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

Connecting to the Socket is automatic if it has not already been opened. Once
the Socket is open, the join will be attempted.

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
                            , incoming = []
                            , timeout = Nothing
                            }
                        |> join topic

        Connecting ->
            ( addChannelBeingJoined topic (Model model)
            , Cmd.none
            )

        Disconnected _ ->
            Model model
                |> addChannelBeingJoined topic
                |> connect


{-| A type alias representing the optional config for joining a Channel.

  - `topic` - The channel topic id, for example: `"topic:subTopic"`.

  - `payload` - Optional data to be sent to the channel when joining.

  - `incoming` - A list of messages to receive on the Channel.

  - `timeout` - Optional timeout, in ms, before retrying to join if the previous
    attempt failed.

-}
type alias JoinConfig =
    { topic : Topic
    , payload : Maybe Payload
    , incoming : List String
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

**Note:** Internally, [JoinConfg](#JoinConfig)s are stored by `topic`, so subsequent
additions with the same `topic` will overwrite previous ones.

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
        (Set.insert topic model.channelsBeingJoined)
        (Model model)


dropChannelBeingJoined : Topic -> Model -> Model
dropChannelBeingJoined topic (Model model) =
    updateChannelsBeingJoined
        (Set.remove topic model.channelsBeingJoined)
        (Model model)


addJoinedChannel : Topic -> Model -> Model
addJoinedChannel topic (Model model) =
    updateChannelsJoined
        (Set.insert topic model.channelsJoined)
        (Model model)


dropJoinedChannel : Topic -> Model -> Model
dropJoinedChannel topic (Model model) =
    updateChannelsJoined
        (Set.remove topic model.channelsJoined)
        (Model model)



{- Talking to Channels -}


{-| The retry strategy to use when a push times out.

  - `Drop` - Drop the push and don't try again.

  - `Every second` - The number of seconds to wait between retries.

  - `Backoff [List seconds] max` - A backoff strategy enabling you to increase
    the delay between retries. When the list has been exhausted, `max` will be
    used for each subsequent attempt.

        Backoff [ 1, 5, 10, 20 ] 30

    An empty list will use the `max` value and is equivalent to `Every second`.

        -- Backoff [] 10 == Every 10



-}
type RetryStrategy
    = Drop
    | Every Int
    | Backoff (List Int) Int


{-| A type alias representing the config for pushing a message to a Channel.

  - `topic` - The Channel topic to send the push to.
  - `msg` - The message to send to the Channel.
  - `payload` - The params to send with the message. If you don't need to
    send any params, set this to
    [Json.Encode.null](https://package.elm-lang.org/packages/elm/json/latest/Json-Encode#null) .
  - `timeout` - Optional timeout in milliseconds to set on the push request.
  - `retryStrategy` - The retry strategy to use when a push times out.
  - `ref` - Optional reference you can provide that you can later use to
    identify the response to a push if you're sending lots of the same `msg`s.

-}
type alias Push =
    { topic : Topic
    , msg : String
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
        , msg = "new_comment"
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


dropQueuedPush : Int -> Model -> Model
dropQueuedPush ref (Model model) =
    updateQueuedPushes
        (Dict.remove ref model.queuedPushes)
        (Model model)


{-| Send a list of [Push](#Push)es to Elixir.

The [Push](#Push)es will be batched together and sent as a single `Cmd`. The
order in which they will arrive at the Elixir end is unknown.

-}
pushAll : List Push -> Model -> ( Model, Cmd Msg )
pushAll pushes model =
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
        |> sendQueuedPushes


pushIfJoined : InternalPush -> Model -> ( Model, Cmd Msg )
pushIfJoined config (Model model) =
    if Set.member config.push.topic model.channelsJoined then
        ( Model model
        , Channel.push
            config.push
            model.portConfig.phoenixSend
        )

    else if Set.member config.push.topic model.channelsBeingJoined then
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

        Connecting ->
            ( Model model
                |> addChannelBeingJoined config.push.topic
                |> addPushToQueue config
            , Cmd.none
            )

        Disconnected _ ->
            ( Model model
                |> addChannelBeingJoined config.push.topic
                |> updateSocketState Connecting
            , Socket.connect
                model.connectOptions
                (Just model.connectParams)
                model.portConfig.phoenixSend
            )


sendQueuedPushes : Model -> ( Model, Cmd Msg )
sendQueuedPushes (Model model) =
    sendAllPushes model.queuedPushes (Model model)


sendQueuedPushesByTopic : Topic -> Model -> ( Model, Cmd Msg )
sendQueuedPushesByTopic topic model =
    let
        ( toGo, toKeep ) =
            model
                |> queuedPushes
                |> Dict.partition
                    (\_ internalConfig -> internalConfig.push.topic == topic)
    in
    model
        |> updateQueuedPushes toKeep
        |> sendAllPushes toGo


sendTimeoutPushes : Model -> ( Model, Cmd Msg )
sendTimeoutPushes model =
    let
        ( toGo, toKeep ) =
            model
                |> timeoutPushes
                |> Dict.partition
                    (\_ internalConfig ->
                        case internalConfig.retryStrategy of
                            Every secs ->
                                internalConfig.timeoutTick == secs

                            Backoff (head :: _) _ ->
                                internalConfig.timeoutTick == head

                            Backoff [] max ->
                                internalConfig.timeoutTick == max

                            Drop ->
                                -- This branch should never match because
                                -- pushes with a Drop strategy should never
                                -- end up in this list.
                                False
                    )
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
    model
        |> updateTimeoutPushes toKeep
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



{- Receiving Messages -}


{-| Receive messages from the Socket, Channels and Phoenix Presence.

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
            ChannelMsg
            model.portConfig.channelReceiver
        , Socket.subscriptions
            SocketMsg
            model.portConfig.socketReceiver
        , Presence.subscriptions
            PresenceMsg
            model.portConfig.presenceReceiver
        , if Dict.isEmpty model.timeoutPushes then
            Sub.none

          else
            Time.every 1000 TimeoutTick
        ]


{-| Add the messages you want to receive from the Channel identified by
[Topic](#Topic).
-}
addIncoming : Topic -> List String -> Model -> ( Model, Cmd Msg )
addIncoming topic messages (Model model) =
    ( Model model
    , Channel.allOn
        { topic = topic
        , msgs = messages
        }
        model.portConfig.phoenixSend
    )


{-| Remove messages you no longer want to receive from the Channel identified
by [Topic](#Topic).
-}
dropIncoming : Topic -> List String -> Model -> ( Model, Cmd Msg )
dropIncoming topic messages (Model model) =
    ( Model model
    , Channel.allOff
        { topic = topic
        , msgs = messages
        }
        model.portConfig.phoenixSend
    )



{- Update -}


{-| The `Msg` type that you pass into the [update](#update) function.

This is an opaque type as it carries the _raw_ `Msg` data from the lower level
[Socket](Phoenix.Socket#Msg), [Channel](Phoenix.Channel#Msg) and
[Presence](Phoenix.Presence#Msg) `Msg`s.

For pattern matching, use the [lastMsg](#lastMsg) function to return a
[PhoenixMsg](#PhoenixMsg) which has nicer pattern matching options.

-}
type Msg
    = ChannelMsg Channel.Msg
    | PresenceMsg Presence.Msg
    | SocketMsg Socket.Msg
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
        ChannelMsg (Channel.Closed topic) ->
            ( updatePhoenixMsg (ChannelResponse (Closed topic)) (Model model), Cmd.none )

        ChannelMsg (Channel.Error topic) ->
            ( updatePhoenixMsg (ChannelResponse (ChannelError topic)) (Model model), Cmd.none )

        ChannelMsg (Channel.InvalidMsg topic invalidMsg payload) ->
            ( updatePhoenixMsg (ChannelResponse (InvalidChannelMsg topic invalidMsg payload)) (Model model), Cmd.none )

        ChannelMsg (Channel.JoinError topic payload) ->
            ( updatePhoenixMsg (ChannelResponse (JoinError topic payload)) (Model model), Cmd.none )

        ChannelMsg (Channel.JoinOk topic payload) ->
            Model model
                |> addJoinedChannel topic
                |> dropChannelBeingJoined topic
                |> updatePhoenixMsg (ChannelResponse (JoinOk topic payload))
                |> sendQueuedPushesByTopic topic

        ChannelMsg (Channel.JoinTimeout topic payload) ->
            ( updatePhoenixMsg (ChannelResponse (JoinTimeout topic payload)) (Model model), Cmd.none )

        ChannelMsg (Channel.LeaveOk topic) ->
            ( Model model
                |> dropJoinedChannel topic
                |> updatePhoenixMsg (ChannelResponse (LeaveOk topic))
            , Cmd.none
            )

        ChannelMsg (Channel.Message topic msgResult payloadResult) ->
            case ( msgResult, payloadResult ) of
                ( Ok message, Ok payload ) ->
                    ( updatePhoenixMsg (Message (Channel topic message payload)) (Model model), Cmd.none )

                _ ->
                    ( Model model, Cmd.none )

        ChannelMsg (Channel.PushError topic msgResult payloadResult refResult) ->
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
                        |> dropQueuedPush internalRef
                        |> updatePhoenixMsg (ChannelResponse (PushError topic msg_ pushRef payload))
                    , Cmd.none
                    )

                _ ->
                    ( Model model, Cmd.none )

        ChannelMsg (Channel.PushOk topic msgResult payloadResult refResult) ->
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
                        |> dropQueuedPush internalRef
                        |> updatePhoenixMsg (ChannelResponse (PushOk topic msg_ pushRef payload))
                    , Cmd.none
                    )

                _ ->
                    ( Model model, Cmd.none )

        ChannelMsg (Channel.PushTimeout topic msgResult payloadResult refResult) ->
            case ( msgResult, payloadResult, refResult ) of
                ( Ok msg_, Ok payload, Ok internalRef ) ->
                    case Dict.get internalRef model.queuedPushes of
                        Just internalConfig ->
                            let
                                pushRef =
                                    internalConfig.push.ref

                                responseModel =
                                    Model model
                                        |> dropQueuedPush internalConfig.ref
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

        PresenceMsg (Presence.Diff topic diffResult) ->
            case diffResult of
                Ok diff ->
                    ( Model model
                        |> addPresenceDiff topic diff
                        |> updatePhoenixMsg (PresenceResponse (Diff topic diff))
                    , Cmd.none
                    )

                _ ->
                    ( Model model, Cmd.none )

        PresenceMsg (Presence.Join topic presenceResult) ->
            case presenceResult of
                Ok presence ->
                    ( Model model
                        |> addPresenceJoin topic presence
                        |> updatePhoenixMsg (PresenceResponse (Join topic presence))
                    , Cmd.none
                    )

                _ ->
                    ( Model model, Cmd.none )

        PresenceMsg (Presence.Leave topic presenceResult) ->
            case presenceResult of
                Ok presence ->
                    ( Model model
                        |> addPresenceLeave topic presence
                        |> updatePhoenixMsg (PresenceResponse (Leave topic presence))
                    , Cmd.none
                    )

                _ ->
                    ( Model model, Cmd.none )

        PresenceMsg (Presence.State topic stateResult) ->
            case stateResult of
                Ok state ->
                    ( Model model
                        |> replacePresenceState topic state
                        |> updatePhoenixMsg (PresenceResponse (State topic state))
                    , Cmd.none
                    )

                _ ->
                    ( Model model, Cmd.none )

        PresenceMsg (Presence.InvalidMsg _ _) ->
            ( Model model, Cmd.none )

        SocketMsg subMsg ->
            case subMsg of
                Socket.Opened ->
                    Model model
                        |> updateSocketState Connected
                        |> updatePhoenixMsg (SocketResponse (StateChange Connected))
                        |> joinChannels model.channelsBeingJoined

                Socket.Closed infoResult ->
                    case infoResult of
                        Ok info ->
                            ( Model model
                                |> updateSocketState (Disconnected info)
                                |> updatePhoenixMsg (SocketResponse (StateChange (Disconnected info)))
                            , Cmd.none
                            )

                        _ ->
                            ( Model model, Cmd.none )

                Socket.Error result ->
                    case result of
                        Ok error ->
                            ( Model model
                                |> updateSocketError error
                                |> updatePhoenixMsg (SocketResponse SocketError)
                            , Cmd.none
                            )

                        Err _ ->
                            ( Model model
                            , Cmd.none
                            )

                Socket.Message result ->
                    case result of
                        Ok message ->
                            ( Model model
                                |> addMessage message
                                |> updateSocketMessage (Just message)
                                |> updatePhoenixMsg (Message (Socket message))
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
                                        |> updatePhoenixMsg (SocketResponse (SocketInfo All))
                                    , Cmd.none
                                    )

                                Err _ ->
                                    ( Model model
                                    , Cmd.none
                                    )

                        Socket.MakeRef result ->
                            case result of
                                Ok ref ->
                                    ( Model model
                                        |> updateSocketInfo
                                            (SocketInfo.updateMakeRef ref model.socketInfo)
                                        |> updatePhoenixMsg (SocketResponse (SocketInfo (MakeRef ref)))
                                    , Cmd.none
                                    )

                                Err _ ->
                                    ( Model model
                                    , Cmd.none
                                    )

                        _ ->
                            ( Model model, Cmd.none )

                Socket.InvalidMsg message ->
                    ( Model model
                        |> addInvalidSocketEvent message
                        |> updateLastInvalidSocketEvent (Just message)
                    , Cmd.none
                    )

        TimeoutTick _ ->
            Model model
                |> timeoutTick
                |> sendTimeoutPushes


addPresenceDiff : Topic -> Presence.PresenceDiff -> Model -> Model
addPresenceDiff topic diff (Model model) =
    updatePresenceDiff
        (Dict.prependOne topic diff model.presenceDiff)
        (Model model)


addPresenceJoin : Topic -> Presence.Presence -> Model -> Model
addPresenceJoin topic presence (Model model) =
    updatePresenceJoin
        (Dict.prependOne topic presence model.presenceJoin)
        (Model model)


addPresenceLeave : Topic -> Presence.Presence -> Model -> Model
addPresenceLeave topic presence (Model model) =
    updatePresenceLeave
        (Dict.prependOne topic presence model.presenceLeave)
        (Model model)


replacePresenceState : Topic -> Presence.PresenceState -> Model -> Model
replacePresenceState topic state (Model model) =
    updatePresenceState
        (Dict.insert topic state model.presenceState)
        (Model model)


{-| All the possible states of the Socket.
-}
type SocketState
    = Connected
    | Connecting
    | Disconnected Socket.ClosedInfo


{-| Information about the Socket.
-}
type SocketInfo
    = All
    | ConnectionState String
    | EndPointURL String
    | HasLogger (Maybe Bool)
    | IsConnected Bool
    | MakeRef String
    | Protocol String


{-| All the responses that can be received from the Socket.
-}
type SocketResponse
    = StateChange SocketState
    | SocketError
    | SocketInfo SocketInfo


{-| A type alias representing the original payload that was sent with the
[push](#PushConfig).
-}
type alias OriginalPayload =
    Payload


{-| A type alias representing the original message that was sent with the
[push](#PushConfig).
-}
type alias OriginalMessage =
    String


{-| A type alias representing the `ref` set on the original [push](#PushConfig).
-}
type alias PushRef =
    Maybe String


{-| All the responses that can be received from a Channel.
-}
type ChannelResponse
    = JoinOk Topic Payload
    | JoinError Topic Payload
    | JoinTimeout Topic OriginalPayload
    | PushOk Topic OriginalMessage PushRef Payload
    | PushError Topic OriginalMessage PushRef Payload
    | PushTimeout Topic OriginalMessage PushRef OriginalPayload
    | Closed Topic
    | ChannelError Topic
    | LeaveOk Topic
    | InvalidChannelMsg Topic String Payload


{-| -}
type PresenceResponse
    = Join Topic Presence.Presence
    | Leave Topic Presence.Presence
    | State Topic Presence.PresenceState
    | Diff Topic Presence.PresenceDiff


{-| A type alias representing a message that is `push`ed or `broadcast`ed from
a Channel.

So if you did this from your Elixir Channel:

    broadcast(socket, "new_msg", %{id: 1, text: "Hello everyone."})

`IncomingMessage` would have the value `"new_msg"`.

-}
type alias IncomingMessage =
    String


{-| A message that has come in from a Channel or the Socket.
-}
type Message
    = Channel Topic IncomingMessage Payload
    | Socket
        { joinRef : Maybe String
        , ref : Maybe String
        , topic : String
        , event : String
        , payload : Value
        }


{-| The messages that you can pattern match on for your own program logic.
-}
type PhoenixMsg
    = NoOp
    | Message Message
    | SocketResponse SocketResponse
    | ChannelResponse ChannelResponse
    | PresenceResponse PresenceResponse


{-| Retrieve the last message received. Use it to pattern match on.

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
                case Phoenix.lastMsg phoenix of
                    ChannelResponse (JoinOk "topic:subTopic" payload) ->
                        ...

                    SocketResponse (StateChange state) ->
                        case state of
                            Connected ->
                                ...

                            Disconnected {reason, code, wasClean} ->
                                ...

                    Message (Channel topic incoming_msg payload) ->
                        ...

-}
lastMsg : Model -> PhoenixMsg
lastMsg (Model model) =
    model.phoenixMsg



{- Logging -}


{-| Log some data to the console.

    import Json.Encode as JE

    log "info" "foo"
        (JE.object
            [ ( "bar", JE.string "foo bar" ) ]
        )
        model

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



{- Request information about the Socket -}


{-| -}
requestConnectionState : Model -> Cmd Msg
requestConnectionState (Model model) =
    Socket.connectionState model.portConfig.phoenixSend


{-| -}
requestEndpointURL : Model -> Cmd Msg
requestEndpointURL (Model model) =
    Socket.endPointURL model.portConfig.phoenixSend


{-| -}
requestHasLogger : Model -> Cmd Msg
requestHasLogger (Model model) =
    Socket.hasLogger model.portConfig.phoenixSend


{-| -}
requestIsConnected : Model -> Cmd Msg
requestIsConnected (Model model) =
    Socket.isConnected model.portConfig.phoenixSend


{-| -}
requestMakeRef : Model -> Cmd Msg
requestMakeRef (Model model) =
    Socket.makeRef model.portConfig.phoenixSend


{-| -}
requestProtocol : Model -> Cmd Msg
requestProtocol (Model model) =
    Socket.protocol model.portConfig.phoenixSend


{-| -}
requestSocketInfo : Model -> Cmd Msg
requestSocketInfo (Model model) =
    Socket.info model.portConfig.phoenixSend



{- Socket -}


addInvalidSocketEvent : String -> Model -> Model
addInvalidSocketEvent msg (Model model) =
    updateInvalidSocketEvents
        (msg :: model.invalidSocketEvents)
        (Model model)



{- Socket Messages -}


addMessage : Socket.MessageConfig -> Model -> Model
addMessage message (Model model) =
    updateSocketMessages
        (message :: model.socketMessages)
        (Model model)



{- Timeout Events -}


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



{- Access Model Fields -}


queuedPushes : Model -> Dict Int InternalPush
queuedPushes (Model model) =
    model.queuedPushes


timeoutPushes : Model -> Dict Int InternalPush
timeoutPushes (Model model) =
    model.timeoutPushes



{- Update Model Fields -}


updateChannelsBeingJoined : Set Topic -> Model -> Model
updateChannelsBeingJoined channelsBeingJoined (Model model) =
    Model
        { model
            | channelsBeingJoined = channelsBeingJoined
        }


updateChannelsJoined : Set Topic -> Model -> Model
updateChannelsJoined channelsJoined (Model model) =
    Model
        { model
            | channelsJoined = channelsJoined
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


updateIncomingChannelMessages : Dict String (List String) -> Model -> Model
updateIncomingChannelMessages messages (Model model) =
    Model { model | incomingChannelMessages = messages }


updateInvalidSocketEvents : List String -> Model -> Model
updateInvalidSocketEvents msgs (Model model) =
    Model
        { model
            | invalidSocketEvents = msgs
        }


updateJoinConfigs : Dict String JoinConfig -> Model -> Model
updateJoinConfigs configs (Model model) =
    Model
        { model
            | joinConfigs = configs
        }


updateLastInvalidSocketEvent : Maybe String -> Model -> Model
updateLastInvalidSocketEvent msg (Model model) =
    Model
        { model
            | lastInvalidSocketEvent = msg
        }


updatePhoenixMsg : PhoenixMsg -> Model -> Model
updatePhoenixMsg msg (Model model) =
    Model
        { model
            | phoenixMsg = msg
        }


updatePresenceDiff : Dict String (List Presence.PresenceDiff) -> Model -> Model
updatePresenceDiff diff (Model model) =
    Model
        { model
            | presenceDiff = diff
        }


updatePresenceJoin : Dict String (List Presence.Presence) -> Model -> Model
updatePresenceJoin presence (Model model) =
    Model
        { model
            | presenceJoin = presence
        }


updatePresenceLeave : Dict String (List Presence.Presence) -> Model -> Model
updatePresenceLeave presence (Model model) =
    Model
        { model
            | presenceLeave = presence
        }


updatePresenceState : Dict String Presence.PresenceState -> Model -> Model
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


updateSocketError : String -> Model -> Model
updateSocketError error (Model model) =
    Model
        { model
            | socketError = error
        }


updateSocketInfo : SocketInfo.Info -> Model -> Model
updateSocketInfo socketInfo (Model model) =
    Model
        { model
            | socketInfo = socketInfo
        }


updateSocketMessage : Maybe Socket.MessageConfig -> Model -> Model
updateSocketMessage message (Model model) =
    Model
        { model
            | socketMessage = message
        }


updateSocketMessages : List Socket.MessageConfig -> Model -> Model
updateSocketMessages messages (Model model) =
    Model
        { model
            | socketMessages = messages
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
