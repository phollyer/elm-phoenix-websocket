module Phoenix exposing
    ( Model
    , PortConfig, init
    , connect, addConnectOptions, setConnectOptions, Payload, setConnectParams, disconnect, disconnectAndReset
    , Topic, join, Event, JoinConfig, joinConfig, setJoinConfig
    , leave, LeaveConfig, setLeaveConfig
    , RetryStrategy(..), PushConfig, pushConfig, push
    , subscriptions
    , addEvent, addEvents, dropEvent, dropEvents
    , Msg, update, updateWith
    , SocketState(..), SocketMessage(..)
    , OriginalPayload, PushRef, ChannelResponse(..)
    , Presence, PresenceDiff, PresenceEvent(..)
    , InternalError(..)
    , PhoenixMsg(..)
    , socketState, socketStateToString, isConnected, connectionState, disconnectReason, endPointURL, protocol
    , queuedChannels, channelQueued, joinedChannels, channelJoined, topicParts
    , allQueuedPushes, queuedPushes, pushQueued, dropQueuedPush
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
                    (newModel, cmd, phoenixMsg) =
                        Phoenix.update subMsg model.phoenix
                            |> Phoenix.updateWith PhoenixMsg model
                in
                case phoenixMsg of
                    ...
            ...


    -- Subscribe to receive Phoenix Msgs

    subscriptions : Model -> Sub Msg
    subscriptions model =
        Sub.map PhoenixMsg <|
            Phoenix.subscriptions model.phoenix


# Model

@docs Model


# Initialising the Model

@docs PortConfig, init


# Connecting to the Socket

Connecting to the Socket is automatic on the first [push](#push) to a Channel.
However, if you want to connect before hand, you can use the
[connect](#connect) function.

If you want to set any [ConnectOption](Phoenix.Socket#ConnectOption)s on the
socket you can use the [addConnectOptions](#addConnectOptions) or
[setConnectOptions](#setConnectOptions) functions.

If you want to send any params to the Socket when it connects at the Elixir
end, such as authenticating a user for example, then you can use the
[setConnectParams](#setConnectParams) function.

@docs connect, addConnectOptions, setConnectOptions, Payload, setConnectParams, disconnect, disconnectAndReset


# Joining a Channel

Joining a Channel is automatic on the first [push](#push) to the Channel.
However, if you want to join before hand, you can use the [join](#join)
function.

If you want to send any params to the Channel when you join at the Elixir end
you can use the [setJoinConfig](#setJoinConfig) function.

@docs Topic, join, Event, JoinConfig, joinConfig, setJoinConfig


# Leaving a Channel

@docs leave, LeaveConfig, setLeaveConfig


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

@docs RetryStrategy, PushConfig, pushConfig, push


## Receiving

@docs subscriptions


### Incoming Events

@docs addEvent, addEvents, dropEvent, dropEvents


# Update

@docs Msg, update, updateWith


## Pattern Matching


### Socket

@docs SocketState, SocketMessage


### Channel

@docs OriginalPayload, PushRef, ChannelResponse

### Phoenix Presence

@docs Presence, PresenceDiff, PresenceEvent


### Internal Errors

@docs InternalError


### PhoenixMsg

@docs PhoenixMsg


# Helpers


## Socket Information

@docs socketState, socketStateToString, isConnected, connectionState, disconnectReason, endPointURL, protocol


## Channels

@docs queuedChannels, channelQueued, joinedChannels, channelJoined, topicParts


## Pushes

@docs allQueuedPushes, queuedPushes, pushQueued, dropQueuedPush

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
        , queuedLeaves : Set Topic
        , joinedChannels : Set Topic
        , connectOptions : List Socket.ConnectOption
        , connectParams : Payload
        , disconnectReason : Maybe String
        , joinConfigs : Dict Topic JoinConfig
        , leaveConfigs : Dict Topic LeaveConfig
        , portConfig : PortConfig
        , presenceDiff : Dict Topic (List PresenceDiff)
        , presenceJoin : Dict Topic (List Presence)
        , presenceLeave : Dict Topic (List Presence)
        , presenceState : Dict Topic (List Presence)
        , pushCount : Int
        , queuedPushes : Dict String InternalPush
        , sentPushes : Dict String InternalPush
        , socketInfo : SocketInfo.Info
        , socketState : SocketState
        , timeoutPushes : Dict String InternalPush
        }


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
        { queuedChannels = Set.empty
        , queuedLeaves = Set.empty
        , joinedChannels = Set.empty
        , connectOptions = []
        , connectParams = JE.null
        , disconnectReason = Nothing
        , joinConfigs = Dict.empty
        , leaveConfigs = Dict.empty
        , portConfig = portConfig
        , presenceDiff = Dict.empty
        , presenceJoin = Dict.empty
        , presenceLeave = Dict.empty
        , presenceState = Dict.empty
        , pushCount = 0
        , queuedPushes = Dict.empty
        , sentPushes = Dict.empty
        , socketInfo = SocketInfo.init
        , socketState = Disconnected (Socket.ClosedInfo Nothing 0 False "" False)
        , timeoutPushes = Dict.empty
        }



{- Connecting to the Socket -}


{-| Connect to the Socket.
-}
connect : Model -> ( Model, Cmd Msg )
connect (Model model) =
    case model.socketState of
        Disconnected _ ->
            ( updateSocketState Connecting (Model model)
            , Socket.connect
                model.connectOptions
                (Just model.connectParams)
                model.portConfig.phoenixSend
            )

        Disconnecting ->
            ( updateSocketState Connecting (Model model)
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

**Note:** This will overwrite any
[ConnectOption](Phoenix.Socket.ConnectOption)s that have already been set.

    import Phoenix
    import Phoenix.Socket as Socket
    import Ports.Phoenix as Ports

    init =
        { phoenix =
            Phoenix.init Ports.config
                |> Phoenix.addConnectOptions
                    [ Socket.Timeout 7000
                    , Socket.HeartbeatIntervalMillis 2000
                    ]
                |> Phoenix.addConnectOptions
                    [ Socket.Timeout 5000 ]
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
                |> Phoenix.addConnectOptions
                    [ Socket.HeartbeatIntervalMillis 2000 ]
                |> Phoenix.setConnectOptions
                    [ Socket.Timeout 7000 ]
                |> Phoenix.setConnectOptions
                    [ Socket.Timeout 5000 ]
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
    import Phoenix

    Phoenix.setConnectParams
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


{-| Disconnect the Socket, maybe providing a status
[code](https://developer.mozilla.org/en-US/docs/Web/API/CloseEvent#Status_codes)
for the closure.
-}
disconnect : Maybe Int -> Model -> ( Model, Cmd Msg )
disconnect code (Model model) =
    case model.socketState of
        Disconnected _ ->
            ( Model model, Cmd.none )

        Disconnecting ->
            ( Model model, Cmd.none )

        _ ->
            ( updateSocketState Disconnecting (Model model)
            , Socket.disconnect code
                model.portConfig.phoenixSend
            )


{-| Disconnect the Socket, maybe providing a status
[code](https://developer.mozilla.org/en-US/docs/Web/API/CloseEvent#Status_codes)
for the closure.

This will also reset the internal model, so information relating to
Channels that have been joined, Pushes queued, Presence's and configs will all
be reset.

-}
disconnectAndReset : Maybe Int -> Model -> ( Model, Cmd Msg )
disconnectAndReset code (Model model) =
    case model.socketState of
        Disconnected _ ->
            ( reset (Model model), Cmd.none )

        Disconnecting ->
            ( Model model, Cmd.none )

        _ ->
            Model model
                |> reset
                |> disconnect code


reset : Model -> Model
reset model =
    model
        |> updateChannelsBeingJoined Set.empty
        |> updateChannelsBeingLeft Set.empty
        |> updateChannelsJoined Set.empty
        |> updateConnectOptions []
        |> updateConnectParams JE.null
        |> updateJoinConfigs Dict.empty
        |> updateLeaveConfigs Dict.empty
        |> updateQueuedPushes Dict.empty
        |> updateTimeoutPushes Dict.empty
        |> updatePresenceState Dict.empty
        |> updatePresenceJoin Dict.empty
        |> updatePresenceLeave Dict.empty
        |> updatePresenceDiff Dict.empty



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
    if channelJoined topic (Model model) then
        ( Model model, Cmd.none )

    else
        case model.socketState of
            Connected ->
                case Dict.get topic model.joinConfigs of
                    Just joinConfig_ ->
                        ( addChannelBeingJoined topic (Model model)
                        , Channel.join
                            joinConfig_
                            model.portConfig.phoenixSend
                        )

                    Nothing ->
                        Model model
                            |> setJoinConfig
                                { topic = topic
                                , payload = JE.null
                                , events = []
                                , timeout = Nothing
                                }
                            |> join topic

            Connecting ->
                ( addChannelBeingJoined topic (Model model)
                , Cmd.none
                )

            Disconnecting ->
                ( addChannelBeingJoined topic (Model model)
                , Cmd.none
                )

            Disconnected _ ->
                Model model
                    |> addChannelBeingJoined topic
                    |> connect


{-| A type alias representing an event that is sent to, or received from, a
Channel.

So if you have this handler in your Elixir Channel:

    def handle_in("new_msg", %{"msg" => msg, "id" => id}, socket) do
      broadcast(socket, "send_msg", %{id: id, text: msg})

      {:reply, :ok, socket}
    end

You would [push](#push) the `"new_msg"` `Event` and pattern match on the
`"send_msg"` `Event` when you handle the [ChannelEvent](#PhoenixMsg) in your
[update](#update) function.

-}
type alias Event =
    String


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
    { topic : Topic
    , payload : Payload
    , events : List Event
    , timeout : Maybe Int
    }


{-| A helper function for creating a [JoinConfig](#JoinConfig).

    import Phoenix exposing (joinConfig)

    Phoenix.setJoinConfig
        { joinConfig
        | topic = "topic:subTopic"
        , events = [ "event1", "event2" ]
        }
        model.phoenix

-}
joinConfig : JoinConfig
joinConfig =
    { topic = ""
    , payload = JE.null
    , events = []
    , timeout = Nothing
    }


{-| Set a [JoinConfig](#JoinConfig) to be used when joining a Channel
referenced by the [Topic](#Topic).

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
                |> setJoinConfig
                    { joinConfig
                    | topic = "topic:subTopic"
                    , events = [ "event1", "event2" ]
                    }
        ...
        }

-}
setJoinConfig : JoinConfig -> Model -> Model
setJoinConfig config (Model model) =
    updateJoinConfigs
        (Dict.insert config.topic config model.joinConfigs)
        (Model model)


{-| Leave a Channel referenced by the [Topic](#Topic).
-}
leave : Topic -> Model -> ( Model, Cmd Msg )
leave topic (Model model) =
    case model.socketState of
        Connected ->
            case Dict.get topic model.leaveConfigs of
                Just config ->
                    ( addChannelBeingLeft topic (Model model)
                    , Channel.leave config model.portConfig.phoenixSend
                    )

                Nothing ->
                    Model model
                        |> setLeaveConfig
                            { topic = topic
                            , timeout = Nothing
                            }
                        |> leave topic

        _ ->
            ( addChannelBeingLeft topic (Model model)
            , Cmd.none
            )


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


{-| Set a [LeaveConfig](#LeaveConfig) to be used when leaving a Channel
referenced by the [Topic](#Topic).
-}
setLeaveConfig : LeaveConfig -> Model -> Model
setLeaveConfig config (Model model) =
    updateLeaveConfigs
        (Dict.insert config.topic config model.leaveConfigs)
        (Model model)


addChannelBeingJoined : Topic -> Model -> Model
addChannelBeingJoined topic (Model model) =
    updateChannelsBeingJoined
        (Set.insert topic model.queuedChannels)
        (Model model)


addChannelBeingLeft : Topic -> Model -> Model
addChannelBeingLeft topic (Model model) =
    updateChannelsBeingLeft
        (Set.insert topic model.queuedLeaves)
        (Model model)


dropChannelBeingJoined : Topic -> Model -> Model
dropChannelBeingJoined topic (Model model) =
    updateChannelsBeingJoined
        (Set.remove topic model.queuedChannels)
        (Model model)


dropChannelBeingLeft : Topic -> Model -> Model
dropChannelBeingLeft topic (Model model) =
    updateChannelsBeingJoined
        (Set.remove topic model.queuedLeaves)
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


{-| A type alias representing the config for pushing a message to a Channel.

  - `topic` - The Channel topic to send the push to.

  - `event` - The event to send to the Channel.

  - `payload` - The params to send with the push. If you don't need to send
    any params, set this to
    [Json.Encode.null](https://package.elm-lang.org/packages/elm/json/latest/Json-Encode#null).

  - `timeout` - Optional timeout in milliseconds to set on the push request.

  - `retryStrategy` - The retry strategy to use if the push times out.

  - `ref` - Optional reference that can later be used to identify the push.
    This is useful when using functions that need to find the push in order to
    do their thing, such as [dropPush](#dropPush) or
    [pushTimeoutCountdown](#pushTimeoutCountdown).

-}
type alias PushConfig =
    { topic : Topic
    , event : Event
    , payload : Payload
    , timeout : Maybe Int
    , retryStrategy : RetryStrategy
    , ref : Maybe String
    }


{-| A helper function for creating a [PushConfig](#PushConfig).

    import Phoenix exposing (pushConfig)

    Phoenix.push
        { pushConfig
        | topic = "topic:subTopic"
        , event = "hello"
        }
        model.phoenix

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


type alias InternalPush =
    { push : PushConfig
    , ref : String
    , retryStrategy : RetryStrategy
    , timeoutTick : Int
    }


{-| Push a message to a Channel.

    import Json.Encode as JE
    import Phoenix exposing (pushConfig)

    Phoenix.push
        { pushConfig
        | topic = "topic:subTopic"
        , event = "event1"
        }
        model.phoenix

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
push : PushConfig -> Model -> ( Model, Cmd Msg )
push config (Model model) =
    let
        ( pushRef, pushCount ) =
            case config.ref of
                Nothing ->
                    ( model.pushCount + 1 |> String.fromInt
                    , model.pushCount + 1
                    )

                Just ref ->
                    ( ref, model.pushCount )

        internalConfig =
            { push = config
            , ref = pushRef
            , retryStrategy = config.retryStrategy
            , timeoutTick = 0
            }
    in
    Model model
        |> addPushToQueue internalConfig
        |> updatePushCount pushCount
        |> pushIfJoined internalConfig


addPushToQueue : InternalPush -> Model -> Model
addPushToQueue config (Model model) =
    updateQueuedPushes
        (Dict.insert config.ref config model.queuedPushes)
        (Model model)


dropQueuedInternalPush : String -> Model -> Model
dropQueuedInternalPush ref (Model model) =
    updateQueuedPushes
        (Dict.remove ref model.queuedPushes)
        (Model model)


pushIfJoined : InternalPush -> Model -> ( Model, Cmd Msg )
pushIfJoined config (Model model) =
    if Set.member config.push.topic model.joinedChannels then
        let
            push_ =
                config.push
        in
        ( addSentPush config (Model model)
        , Channel.push
            { push_
                | ref =
                    case push_.ref of
                        Nothing ->
                            Just config.ref

                        Just ref ->
                            Just ref
            }
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


addSentPush : InternalPush -> Model -> Model
addSentPush config (Model model) =
    updateSentPushes
        (Dict.insert config.ref config model.sentPushes)
        (Model model)


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
                            -- end up in this Dict.
                            False
                )
                model.timeoutPushes
                |> Tuple.mapFirst
                    (\outgoing ->
                        Dict.map
                            (\_ internalConfig ->
                                case internalConfig.retryStrategy of
                                    Backoff [] max ->
                                        internalConfig
                                            |> updateRetryStrategy
                                                (Backoff [] max)
                                            |> updateTimeoutTick 0

                                    Backoff list max ->
                                        internalConfig
                                            |> updateRetryStrategy
                                                (Backoff (List.drop 1 list) max)
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


sendAllPushes : Dict String InternalPush -> Model -> ( Model, Cmd Msg )
sendAllPushes pushConfigs model =
    pushConfigs
        |> Dict.toList
        |> List.map Tuple.second
        |> List.foldl
            batchPush
            ( model, Cmd.none )


batchPush : InternalPush -> ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
batchPush internalPushConfig ( model, cmd ) =
    let
        ( model_, cmd_ ) =
            pushIfJoined
                internalPushConfig
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
            Phoenix.subscriptions model.phoenix

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


{-| Add the [Event](#Event) you want to receive from the Channel identified by
[Topic](#Topic).
-}
addEvent : Topic -> Event -> Model -> Cmd Msg
addEvent topic event (Model model) =
    Channel.on
        { topic = topic
        , event = event
        }
        model.portConfig.phoenixSend


{-| Add the [Event](#Event)s you want to receive from the Channel identified by
[Topic](#Topic).
-}
addEvents : Topic -> List Event -> Model -> Cmd Msg
addEvents topic events (Model model) =
    Channel.allOn
        { topic = topic
        , events = events
        }
        model.portConfig.phoenixSend


{-| Remove an [Event](#Event) you no longer want to receive from the Channel
identified by [Topic](#Topic).
-}
dropEvent : Topic -> Event -> Model -> Cmd Msg
dropEvent topic event (Model model) =
    Channel.off
        { topic = topic
        , event = event
        }
        model.portConfig.phoenixSend


{-| Remove [Event](#Event)s you no longer want to receive from the Channel
identified by [Topic](#Topic).
-}
dropEvents : Topic -> List Event -> Model -> Cmd Msg
dropEvents topic events (Model model) =
    Channel.allOff
        { topic = topic
        , events = events
        }
        model.portConfig.phoenixSend



{- Update -}


{-| The `Msg` type that you pass into the [update](#update) function.

This is an opaque type as it carries the _raw_ `Msg` data from the lower level
[Socket](Phoenix.Socket#Msg), [Channel](Phoenix.Channel#Msg) and
[Presence](Phoenix.Presence#Msg) `Msg`s.

For pattern matching use [PhoenixMsg](#PhoenixMsg).

-}
type Msg
    = ReceivedChannelMsg Channel.Msg
    | ReceivedPresenceMsg Presence.Msg
    | ReceivedSocketMsg Socket.Msg
    | TimeoutTick Time.Posix


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
                    (newModel, cmd, phoenixMsg) =
                        Phoenix.update subMsg model.phoenix
                            |> Phoenix.updateWith PhoenixMsg model
                in
                case phoenixMsg of
                    ChannelClosed topic ->
                        ( newModel , cmd )

                    ...

            ...

-}
update : Msg -> Model -> ( Model, Cmd Msg, PhoenixMsg )
update msg (Model model) =
    case msg of
        ReceivedChannelMsg channelMsg ->
            case channelMsg of
                Channel.Closed topic ->
                    ( Model model, Cmd.none, ChannelClosed topic )

                Channel.Error topic ->
                    ( Model model, Cmd.none, ChannelResponse (ChannelError topic) )

                Channel.JoinError topic payload ->
                    ( Model model, Cmd.none, ChannelResponse (JoinError topic payload) )

                Channel.JoinOk topic payload ->
                    Model model
                        |> addJoinedChannel topic
                        |> dropChannelBeingJoined topic
                        |> sendQueuedPushesByTopic topic
                        |> toPhoenixMsg (ChannelResponse (JoinOk topic payload))

                Channel.JoinTimeout topic payload ->
                    ( Model model, Cmd.none, ChannelResponse (JoinTimeout topic payload) )

                Channel.LeaveOk topic ->
                    ( Model model
                        |> dropJoinedChannel topic
                        |> dropChannelBeingLeft topic
                    , Cmd.none
                    , ChannelResponse (LeaveOk topic)
                    )

                Channel.Message topic event payload ->
                    ( Model model, Cmd.none, ChannelEvent topic event payload )

                Channel.PushError topic event payload ref ->
                    let
                        pushRef =
                            case Dict.get ref model.queuedPushes of
                                Just internalConfig ->
                                    internalConfig.push.ref

                                Nothing ->
                                    Nothing
                    in
                    ( dropQueuedInternalPush ref (Model model)
                    , Cmd.none
                    , ChannelResponse (PushError topic event pushRef payload)
                    )

                Channel.PushOk topic event payload ref ->
                    let
                        pushRef =
                            case Dict.get ref model.sentPushes of
                                Just internalConfig ->
                                    internalConfig.push.ref

                                Nothing ->
                                    Nothing
                    in
                    ( dropQueuedInternalPush ref (Model model)
                    , Cmd.none
                    , ChannelResponse (PushOk topic event pushRef payload)
                    )

                Channel.PushTimeout topic event payload ref ->
                    case Dict.get ref model.sentPushes of
                        Just internalConfig ->
                            ( case internalConfig.retryStrategy of
                                Drop ->
                                    dropQueuedInternalPush ref (Model model)

                                _ ->
                                    dropQueuedInternalPush ref (Model model)
                                        |> addTimeoutPush internalConfig
                            , Cmd.none
                            , ChannelResponse (PushTimeout topic event internalConfig.push.ref payload)
                            )

                        Nothing ->
                            ( Model model
                            , Cmd.none
                            , ChannelResponse (PushTimeout topic event Nothing payload)
                            )

                Channel.InternalError errorType ->
                    case errorType of
                        Channel.DecoderError error ->
                            ( Model model
                            , Cmd.none
                            , InternalError (DecoderError ("Channel : " ++ error))
                            )

                        Channel.InvalidMessage topic error _ ->
                            ( Model model
                            , Cmd.none
                            , InternalError (InvalidMessage ("Channel : " ++ topic ++ " : " ++ error))
                            )

        ReceivedPresenceMsg presenceMsg ->
            case presenceMsg of
                Presence.Diff topic diff ->
                    ( addPresenceDiff topic diff (Model model)
                    , Cmd.none
                    , PresenceEvent (Diff topic diff)
                    )

                Presence.Join topic join_ ->
                    ( addPresenceJoin topic join_ (Model model)
                    , Cmd.none
                    , PresenceEvent (Join topic join_)
                    )

                Presence.Leave topic leave_ ->
                    ( addPresenceLeave topic leave_ (Model model)
                    , Cmd.none
                    , PresenceEvent (Leave topic leave_)
                    )

                Presence.State topic state ->
                    ( replacePresenceState topic state (Model model)
                    , Cmd.none
                    , PresenceEvent (State topic state)
                    )

                Presence.InternalError errorType ->
                    case errorType of
                        Presence.DecoderError error ->
                            ( Model model
                            , Cmd.none
                            , InternalError (DecoderError ("Presence : " ++ error))
                            )

                        Presence.InvalidMessage topic error ->
                            ( Model model
                            , Cmd.none
                            , InternalError (InvalidMessage ("Presence : " ++ topic ++ " : " ++ error))
                            )

        ReceivedSocketMsg subMsg ->
            case subMsg of
                Socket.Opened ->
                    Model model
                        |> updateDisconnectReason Nothing
                        |> updateSocketState Connected
                        |> batchWithParams
                            [ ( join, queuedChannels (Model model) )
                            , ( leave, queuedLeaves (Model model) )
                            ]
                        |> toPhoenixMsg (SocketMessage (StateChange Connected))

                Socket.Closed closedInfo ->
                    Model model
                        |> updateDisconnectReason closedInfo.reason
                        |> updateSocketState (Disconnected closedInfo)
                        |> batchWithParams
                            [ ( join, queuedChannels (Model model) ) ]
                        |> toPhoenixMsg (SocketMessage (StateChange (Disconnected closedInfo)))

                Socket.Connecting ->
                    ( updateSocketState Connecting (Model model)
                    , Cmd.none
                    , SocketMessage (StateChange Connecting)
                    )

                Socket.Disconnecting ->
                    ( updateSocketState Disconnecting (Model model)
                    , Cmd.none
                    , SocketMessage (StateChange Disconnecting)
                    )

                Socket.Channel message ->
                    ( Model model
                    , Cmd.none
                    , SocketMessage (ChannelMessage message)
                    )

                Socket.Presence message ->
                    ( Model model
                    , Cmd.none
                    , SocketMessage (PresenceMessage message)
                    )

                Socket.Heartbeat message ->
                    ( Model model
                    , Cmd.none
                    , SocketMessage (Heartbeat message)
                    )

                Socket.Info socketInfo ->
                    case socketInfo of
                        Socket.All info ->
                            ( updateSocketInfo info (Model model)
                            , Cmd.none
                            , NoOp
                            )

                        _ ->
                            ( Model model, Cmd.none, NoOp )

                Socket.Error reason ->
                    ( Model model
                    , Cmd.none
                    , SocketMessage (SocketError reason)
                    )

                Socket.InternalError errorType ->
                    case errorType of
                        Socket.DecoderError error ->
                            ( Model model
                            , Cmd.none
                            , InternalError (DecoderError ("Socket : " ++ error))
                            )

                        Socket.InvalidMessage error ->
                            ( Model model
                            , Cmd.none
                            , InternalError (InvalidMessage ("Socket : " ++ error))
                            )

        TimeoutTick _ ->
            Model model
                |> timeoutTick
                |> sendTimeoutPushes
                |> toPhoenixMsg NoOp


toPhoenixMsg : PhoenixMsg -> ( Model, Cmd Msg ) -> ( Model, Cmd Msg, PhoenixMsg )
toPhoenixMsg phoenixMsg ( model, cmd ) =
    ( model, cmd, phoenixMsg )


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


{-| Helper function to use after [update](#update).

    import Phoenix

    type alias Model =
        { phoenix : Phoenix.Model
          ...
        }

    type Msg
        = GotPhoenixMsg Phoenix.Msg

    update : Msg -> Model -> (Model, Cmd Msg)
    update msg model =
        case msg of
            GotPhoenixMsg subMsg ->
                let
                    (newModel, cmd, phoenixMsg) =
                        Phoenix.update subMsg model.phoenix
                            |> Phoenix.updateWith GotPhoenixMsg model
                in
                case phoenixMsg of
                    ...

This function will:

  - update the `phoenix` field on the `Model`
  - map the `Cmd Msg` generated by `Phoenix.update` to `GotPhoenixMsg`

To use this function, `Phoenix.Model` needs to be stored on field `phoenix` on
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
type SocketMessage
    = StateChange SocketState
    | SocketError String
    | ChannelMessage
        { topic : Topic
        , event : Event
        , payload : Value
        , joinRef : Maybe String
        , ref : Maybe String
        }
    | PresenceMessage
        { topic : Topic
        , event : Event
        , payload : Value
        }
    | Heartbeat
        { topic : String
        , event : String
        , payload : Value
        , ref : String
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
    = ChannelError Topic
    | JoinOk Topic Payload
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


{-| An `InternalError` should never happen, but if it does, it is because the
JS is out of sync with this package.

If you ever receive this message, please
[raise an issue](https://github.com/phollyer/elm-phoenix-websocket/issues).

-}
type InternalError
    = DecoderError String
    | InvalidMessage String


{-| The `Msg`s that you can pattern match on in your `update` function.
-}
type PhoenixMsg
    = NoOp
    | SocketMessage SocketMessage
    | ChannelResponse ChannelResponse
    | ChannelEvent Topic Event Payload
    | ChannelClosed Topic
    | PresenceEvent PresenceEvent
    | InternalError InternalError



{- Accessing the Model -}
{- Socket -}


{-| The current [state](#SocketState) of the Socket.
-}
socketState : Model -> SocketState
socketState (Model model) =
    model.socketState


{-| The current [state](#SocketState) of the Socket as a String.
-}
socketStateToString : Model -> String
socketStateToString (Model model) =
    case model.socketState of
        Connected ->
            "Connected"

        Connecting ->
            "Connecting"

        Disconnecting ->
            "Disconnecting"

        Disconnected _ ->
            "Disconnected"


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


{-| The reason the Socket disconnected.
-}
disconnectReason : Model -> Maybe String
disconnectReason (Model model) =
    model.disconnectReason


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
queuedChannels : Model -> List String
queuedChannels (Model model) =
    Set.toList model.queuedChannels


{-| Channels that are queued waiting to leave.
-}
queuedLeaves : Model -> List String
queuedLeaves (Model model) =
    Set.toList model.queuedLeaves


{-| Channels that have joined successfully.
-}
joinedChannels : Model -> List String
joinedChannels (Model model) =
    Set.toList model.joinedChannels


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


{-| Split a topic into it's component parts.
-}
topicParts : Topic -> List String
topicParts topic =
    String.split ":" topic



{- Pushes -}


{-| Pushes that are queued and waiting for their Channel to join before being
sent.
-}
allQueuedPushes : Model -> Dict Topic (List PushConfig)
allQueuedPushes (Model model) =
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


{-| Retrieve a list of pushes, by [Topic](#Topic), that are queued and waiting
for their Channel to join before being sent.
-}
queuedPushes : Topic -> Model -> List PushConfig
queuedPushes topic (Model model) =
    Dict.values model.queuedPushes
        |> List.filterMap
            (\internalPushConfig ->
                if internalPushConfig.push.topic == topic then
                    Just internalPushConfig.push

                else
                    Nothing
            )


{-| Determine if a Push is in the queue to be sent when its' Channel joins.

    pushQueued
        (\push -> push.ref == "custom ref")
        model.phoenix

-}
pushQueued : (PushConfig -> Bool) -> Model -> Bool
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
dropQueuedPush : (PushConfig -> Bool) -> Model -> Model
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
timeoutPushes : Model -> Dict String (List PushConfig)
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
pushTimedOut : (PushConfig -> Bool) -> Model -> Bool
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

This will only work after a `push` has timed out and before it is re-tried.

-}
dropTimeoutPush : (PushConfig -> Bool) -> Model -> Model
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
pushTimeoutCountdown : (PushConfig -> Bool) -> Model -> Maybe Int
pushTimeoutCountdown compareFunc (Model model) =
    model.timeoutPushes
        |> Dict.filter
            (\_ internalPushConfig -> compareFunc internalPushConfig.push)
        |> Dict.values
        |> List.head
        |> Maybe.andThen
            (\internalPushConfig ->
                case internalPushConfig.retryStrategy of
                    Drop ->
                        Nothing

                    Every seconds ->
                        Just (seconds - internalPushConfig.timeoutTick)

                    Backoff (seconds :: _) _ ->
                        Just (seconds - internalPushConfig.timeoutTick)

                    Backoff [] (Just max) ->
                        Just (max - internalPushConfig.timeoutTick)

                    Backoff [] Nothing ->
                        Nothing
            )


{-| Cancel a [Push](#Push).

This will cancel pushes that are queued to be sent when their Channel joins. It
will also prevent pushes that timeout from being re-tried.

-}
dropPush : (PushConfig -> Bool) -> Model -> Model
dropPush compare model =
    model
        |> dropQueuedPush compare
        |> dropTimeoutPush compare
        |> dropSentPush compare


dropSentPush : (PushConfig -> Bool) -> Model -> Model
dropSentPush compare (Model model) =
    updateSentPushes
        (Dict.filter
            (\_ internalPush -> not (compare internalPush.push))
            model.sentPushes
        )
        (Model model)



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


updateChannelsBeingLeft : Set Topic -> Model -> Model
updateChannelsBeingLeft channels (Model model) =
    Model
        { model
            | queuedLeaves = channels
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


updateDisconnectReason : Maybe String -> Model -> Model
updateDisconnectReason maybeReason (Model model) =
    Model
        { model
            | disconnectReason = maybeReason
        }


updateJoinConfigs : Dict String JoinConfig -> Model -> Model
updateJoinConfigs configs (Model model) =
    Model
        { model
            | joinConfigs = configs
        }


updateLeaveConfigs : Dict String LeaveConfig -> Model -> Model
updateLeaveConfigs configs (Model model) =
    Model
        { model
            | leaveConfigs = configs
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


updateQueuedPushes : Dict String InternalPush -> Model -> Model
updateQueuedPushes allQueuedPushes_ (Model model) =
    Model
        { model
            | queuedPushes = allQueuedPushes_
        }


updateSentPushes : Dict String InternalPush -> Model -> Model
updateSentPushes sentPushes_ (Model model) =
    Model { model | sentPushes = sentPushes_ }


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


updateTimeoutPushes : Dict String InternalPush -> Model -> Model
updateTimeoutPushes timeoutPushes_ (Model model) =
    Model
        { model
            | timeoutPushes = timeoutPushes_
        }


updateRetryStrategy : RetryStrategy -> InternalPush -> InternalPush
updateRetryStrategy retryStrategy internalPushConfig =
    { internalPushConfig
        | retryStrategy = retryStrategy
    }


updateTimeoutTick : Int -> InternalPush -> InternalPush
updateTimeoutTick tick internalPushConfig =
    { internalPushConfig
        | timeoutTick = tick
    }
