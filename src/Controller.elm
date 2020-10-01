module Controller exposing
    ( Model
    , Msg
    , PushResponse(..)
    , init
    , sendMessage
    , subscriptions
    , update
    )

import Channel
import Json.Encode as JE
import Presence
import Socket
import Time



{- Init -}


init : (PackageOut -> Cmd Socket.EventIn) -> (PackageOut -> Cmd Channel.EventIn) -> Model
init socketOutFunc channelOutFunc =
    { channelsBeingJoined = []
    , channelsJoined = []
    , channelOutFunc = channelOutFunc
    , pushResponse = Nothing
    , queuedEvents = []
    , socketOutFunc = socketOutFunc
    , socketState = Disconnected
    , timeoutEvents = []
    }



{- Model -}


type alias Model =
    { channelsBeingJoined : List Topic
    , channelsJoined : List Topic
    , channelOutFunc : PackageOut -> Cmd Channel.EventIn
    , pushResponse : Maybe PushResponse
    , queuedEvents : List QueuedEvent
    , socketOutFunc : PackageOut -> Cmd Socket.EventIn
    , socketState : SocketState
    , timeoutEvents : List TimeoutEvent
    }


type alias EventOut =
    String


type alias Topic =
    String


type PushResponse
    = PushOk Topic EventOut JE.Value
    | PushError Topic EventOut JE.Value
    | PushTimeout Topic EventOut


type alias QueuedEvent =
    { event : EventOut
    , payload : JE.Value
    , topic : Topic
    }


type SocketState
    = Connected
    | Connecting
    | Disconnected


type alias TimeoutEvent =
    { event : EventOut
    , payload : JE.Value
    , timeUntilRetry : Int
    , topic : Topic
    }


type alias PackageOut =
    { target : String
    , event : String
    , payload : JE.Value
    }



-- Update


type Msg
    = ChannelMsg Channel.EventIn
    | PresenceMsg Presence.EventIn
    | SocketMsg Socket.EventIn
    | TimeoutTick Time.Posix


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ChannelMsg (Channel.Error _ _) ->
            ( model, Cmd.none )

        ChannelMsg (Channel.JoinError _ _) ->
            ( model, Cmd.none )

        ChannelMsg (Channel.JoinOk topic _) ->
            ( model
                |> addJoinedChannel topic
                |> dropChannelBeingJoined topic
            , model.channelOutFunc
                |> sendQueuedEvents topic model.queuedEvents
            )

        ChannelMsg (Channel.JoinTimeout _ _) ->
            ( model, Cmd.none )

        ChannelMsg (Channel.LeaveOk _) ->
            ( model, Cmd.none )

        ChannelMsg (Channel.Message _ _ _) ->
            ( model, Cmd.none )

        ChannelMsg (Channel.PushError topic event payload) ->
            handlePushError
                topic
                event
                payload
                model

        ChannelMsg (Channel.PushOk topic event payload) ->
            handlePushOk
                topic
                event
                payload
                model

        ChannelMsg (Channel.PushTimeout topic event payload) ->
            handlePushTimeout
                topic
                event
                payload
                model

        PresenceMsg _ ->
            ( model, Cmd.none )

        SocketMsg Socket.Opened ->
            ( model
                |> updateSocketState Connected
            , joinChannels
                model.channelsBeingJoined
                model.channelOutFunc
            )

        TimeoutTick _ ->
            model
                |> timeoutTick
                |> retryTimeoutEvents

        _ ->
            ( model, Cmd.none )



{- Queued Events -}


addEventToQueue : QueuedEvent -> Model -> Model
addEventToQueue event model =
    if model.queuedEvents |> List.member event then
        model

    else
        model
            |> updateQueuedEvents
                (event :: model.queuedEvents)


dropQueuedEvent : QueuedEvent -> Model -> Model
dropQueuedEvent queued model =
    model
        |> updateQueuedEvents
            (model.queuedEvents
                |> List.filter
                    (\event -> event /= queued)
            )



{- Timeout Events -}


addTimeoutEvent : TimeoutEvent -> Model -> Model
addTimeoutEvent event model =
    if model.timeoutEvents |> List.member event then
        model

    else
        model
            |> updateTimeoutEvents
                (event :: model.timeoutEvents)


retryTimeoutEvents : Model -> ( Model, Cmd Msg )
retryTimeoutEvents model =
    let
        ( eventsToSend, eventsStillTicking ) =
            model.timeoutEvents
                |> List.partition
                    (\event -> event.timeUntilRetry == 0)
    in
    model
        |> updateTimeoutEvents eventsStillTicking
        |> sendTimeoutEvents eventsToSend


timeoutTick : Model -> Model
timeoutTick model =
    model
        |> updateTimeoutEvents
            (model.timeoutEvents
                |> List.map
                    (\event -> { event | timeUntilRetry = event.timeUntilRetry - 1 })
            )



{- Socket -}


connect : (PackageOut -> Cmd Socket.EventIn) -> Cmd Msg
connect channelOutFunc =
    Cmd.map SocketMsg <|
        Socket.send
            (Socket.Connect Nothing)
            channelOutFunc



{- Channels -}


addChannelBeingJoined : Topic -> Model -> Model
addChannelBeingJoined topic model =
    if model.channelsBeingJoined |> List.member topic then
        model

    else
        updateChannelsBeingJoined
            (topic :: model.channelsBeingJoined)
            model


addJoinedChannel : Topic -> Model -> Model
addJoinedChannel topic model =
    if model.channelsJoined |> List.member topic then
        model

    else
        updateChannelsJoined
            (topic :: model.channelsJoined)
            model


dropChannelBeingJoined : Topic -> Model -> Model
dropChannelBeingJoined topic model =
    let
        channelsBeingJoined =
            model.channelsBeingJoined
                |> List.filter
                    (\channelTopic -> channelTopic /= topic)
    in
    updateChannelsBeingJoined
        channelsBeingJoined
        model


join : Topic -> (PackageOut -> Cmd Channel.EventIn) -> Cmd Msg
join topic channelOutFunc =
    Cmd.map ChannelMsg <|
        Channel.send
            (Channel.Join
                { payload = Nothing
                , topic = topic
                , timeout = Nothing
                }
            )
            channelOutFunc


joinChannels : List Topic -> (PackageOut -> Cmd Channel.EventIn) -> Cmd Msg
joinChannels channelTopics channelOutFunc =
    channelTopics
        |> List.map
            (\topic -> join topic channelOutFunc)
        |> Cmd.batch



{- Pushes -}


handlePushError : Channel.Topic -> Channel.PushEvent -> JE.Value -> Model -> ( Model, Cmd Msg )
handlePushError topic event payload model =
    let
        queued =
            { event = event
            , payload = payload
            , topic = topic
            }

        push =
            PushError
                queued.topic
                queued.event
                queued.payload
    in
    ( model
        |> dropQueuedEvent queued
        |> updatePushResponse push
    , Cmd.none
    )


handlePushOk : Channel.Topic -> Channel.PushEvent -> JE.Value -> Model -> ( Model, Cmd Msg )
handlePushOk topic event payload model =
    let
        queued =
            { event = event
            , payload = payload
            , topic = topic
            }

        push =
            PushOk
                queued.topic
                queued.event
                queued.payload
    in
    ( model
        |> dropQueuedEvent queued
        |> updatePushResponse push
    , Cmd.none
    )


handlePushTimeout : Channel.Topic -> Channel.PushEvent -> JE.Value -> Model -> ( Model, Cmd Msg )
handlePushTimeout topic event payload model =
    let
        queued =
            { event = event
            , payload = payload
            , topic = topic
            }

        push =
            PushTimeout
                queued.topic
                queued.event

        timeout =
            { event = queued.event
            , payload = payload
            , timeUntilRetry = 5
            , topic = queued.topic
            }
    in
    ( model
        |> addTimeoutEvent timeout
        |> dropQueuedEvent queued
        |> updatePushResponse push
    , Cmd.none
    )



{- Server Requests - Private API -}


sendMessage : Topic -> EventOut -> JE.Value -> Model -> ( Model, Cmd Msg )
sendMessage topic event payload model =
    sendIfConnected
        topic
        event
        payload
        model


send : Topic -> EventOut -> JE.Value -> (PackageOut -> Cmd Channel.EventIn) -> Cmd Msg
send topic event payload channelOutFunc =
    Cmd.map ChannelMsg <|
        Channel.send
            (Channel.Push
                { topic = Just topic
                , event = event
                , timeout = Nothing
                , payload = payload
                }
            )
            channelOutFunc


sendIfConnected : Topic -> EventOut -> JE.Value -> Model -> ( Model, Cmd Msg )
sendIfConnected topic event payload model =
    case model.socketState of
        Connected ->
            sendIfJoined
                topic
                event
                payload
                model

        Connecting ->
            ( model
                |> addChannelBeingJoined topic
                |> addEventToQueue
                    { event = event
                    , payload = payload
                    , topic = topic
                    }
            , Cmd.none
            )

        Disconnected ->
            ( model
                |> addChannelBeingJoined topic
                |> addEventToQueue
                    { event = event
                    , payload = payload
                    , topic = topic
                    }
                |> updateSocketState Connecting
            , connect model.socketOutFunc
            )


sendIfJoined : Topic -> EventOut -> JE.Value -> Model -> ( Model, Cmd Msg )
sendIfJoined topic event payload model =
    if model.channelsJoined |> List.member topic then
        ( model
        , send
            topic
            event
            payload
            model.channelOutFunc
        )

    else if model.channelsBeingJoined |> List.member topic then
        ( model
            |> addEventToQueue
                { event = event
                , payload = payload
                , topic = topic
                }
        , Cmd.none
        )

    else
        ( model
            |> addChannelBeingJoined topic
            |> addEventToQueue
                { event = event
                , payload = payload
                , topic = topic
                }
        , join topic model.channelOutFunc
        )


sendQueuedEvents : Topic -> List QueuedEvent -> (PackageOut -> Cmd Channel.EventIn) -> Cmd Msg
sendQueuedEvents topic queuedEvents channelOutFunc =
    queuedEvents
        |> List.filterMap
            (\event ->
                if event.topic /= topic then
                    Nothing

                else
                    Just (sendQueuedEvent event channelOutFunc)
            )
        |> Cmd.batch


sendQueuedEvent : QueuedEvent -> (PackageOut -> Cmd Channel.EventIn) -> Cmd Msg
sendQueuedEvent { event, payload, topic } channelOutFunc =
    send
        topic
        event
        payload
        channelOutFunc


sendTimeoutEvent : TimeoutEvent -> ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
sendTimeoutEvent timeoutEvent ( model, cmd ) =
    let
        ( model_, cmd_ ) =
            sendIfConnected
                timeoutEvent.topic
                timeoutEvent.event
                timeoutEvent.payload
                model
    in
    ( model_
    , Cmd.batch [ cmd, cmd_ ]
    )


sendTimeoutEvents : List TimeoutEvent -> Model -> ( Model, Cmd Msg )
sendTimeoutEvents timeoutEvents model =
    case timeoutEvents of
        [] ->
            ( model, Cmd.none )

        _ ->
            timeoutEvents
                |> List.foldl
                    sendTimeoutEvent
                    ( model, Cmd.none )



-- Subscriptions


subscriptions : Socket.PortIn Msg -> Channel.PortIn Msg -> Model -> Sub Msg
subscriptions socketReceiver channelReceiver model =
    Sub.batch
        [ Channel.subscriptions
            ChannelMsg
            channelReceiver
        , Presence.subscriptions
            PresenceMsg
            channelReceiver
        , Socket.subscriptions
            SocketMsg
            socketReceiver
        , if (model.timeoutEvents |> List.length) > 0 then
            Time.every 1000 TimeoutTick

          else
            Sub.none
        ]



{- Update Model Fields -}


updateChannelsBeingJoined : List Topic -> Model -> Model
updateChannelsBeingJoined channelsBeingJoined model =
    { model
        | channelsBeingJoined = channelsBeingJoined
    }


updateChannelsJoined : List Topic -> Model -> Model
updateChannelsJoined channelsJoined model =
    { model
        | channelsJoined = channelsJoined
    }


updatePushResponse : PushResponse -> Model -> Model
updatePushResponse response model =
    { model
        | pushResponse = Just response
    }


updateQueuedEvents : List QueuedEvent -> Model -> Model
updateQueuedEvents queuedEvents model =
    { model
        | queuedEvents = queuedEvents
    }


updateSocketState : SocketState -> Model -> Model
updateSocketState state model =
    { model
        | socketState = state
    }


updateTimeoutEvents : List TimeoutEvent -> Model -> Model
updateTimeoutEvents timeoutEvents model =
    { model
        | timeoutEvents = timeoutEvents
    }
