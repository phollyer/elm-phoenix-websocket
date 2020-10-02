module Controller exposing
    ( Model
    , Msg
    , PushResponse(..)
    , getConnectionState
    , getEndpointURL
    , getHasLogger
    , getIsConnected
    , getProtocol
    , getSocketInfo
    , init
    , makeRef
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
    , connectionState = Nothing
    , endpointURL = Nothing
    , hasLogger = Nothing
    , invalidSocketEvent = Nothing
    , invalidSocketEvents = []
    , isConnected = False
    , lastSocketMessage = Nothing
    , nextMessageRef = Nothing
    , protocol = Nothing
    , pushResponse = Nothing
    , queuedEvents = []
    , socketError = ""
    , socketMessages = []
    , socketOutFunc = socketOutFunc
    , socketState = Closed
    , timeoutEvents = []
    }



{- Model -}


type alias Model =
    { channelsBeingJoined : List Topic
    , channelsJoined : List Topic
    , channelOutFunc : PackageOut -> Cmd Channel.EventIn
    , connectionState : Maybe String
    , endpointURL : Maybe String
    , hasLogger : Maybe Bool
    , invalidSocketEvent : Maybe String
    , invalidSocketEvents : List String
    , isConnected : Bool
    , lastSocketMessage : Maybe Socket.MessageConfig
    , nextMessageRef : Maybe String
    , protocol : Maybe String
    , pushResponse : Maybe PushResponse
    , queuedEvents : List QueuedEvent
    , socketError : String
    , socketOutFunc : PackageOut -> Cmd Socket.EventIn
    , socketMessages : List Socket.MessageConfig
    , socketState : SocketState
    , timeoutEvents : List TimeoutEvent
    }


type alias EventOut =
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
    = Open
    | Opening
    | Closed


type alias TimeoutEvent =
    { event : EventOut
    , payload : JE.Value
    , timeUntilRetry : Int
    , topic : Topic
    }


type alias Topic =
    String


type alias PackageOut =
    { event : String
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
    let
        _ =
            Debug.log "" msg
    in
    case msg of
        ChannelMsg (Channel.Closed _) ->
            ( model, Cmd.none )

        ChannelMsg (Channel.Error _ _) ->
            ( model, Cmd.none )

        ChannelMsg (Channel.InvalidEvent _ _ _) ->
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

        PresenceMsg (Presence.Diff _ _) ->
            ( model, Cmd.none )

        PresenceMsg (Presence.InvalidEvent _ _) ->
            ( model, Cmd.none )

        PresenceMsg (Presence.Join _ _) ->
            ( model, Cmd.none )

        PresenceMsg (Presence.Leave _ _) ->
            ( model, Cmd.none )

        PresenceMsg (Presence.State _ _) ->
            ( model, Cmd.none )

        SocketMsg subMsg ->
            case subMsg of
                Socket.Closed ->
                    ( updateSocketState Closed model
                    , Cmd.none
                    )

                Socket.ConnectionStateReply connectionState_ ->
                    ( updateConnectionState (Just connectionState_) model
                    , Cmd.none
                    )

                Socket.EndPointURLReply endpointURL_ ->
                    ( updateEndpointURL (Just endpointURL_) model
                    , Cmd.none
                    )

                Socket.Error error ->
                    ( updateSocketError error model
                    , Cmd.none
                    )

                Socket.HasLoggerReply hasLogger_ ->
                    ( updateHasLogger hasLogger_ model
                    , Cmd.none
                    )

                Socket.InvalidEvent event ->
                    ( model
                        |> addInvalidSocketEvent event
                        |> updateInvalidSocketEvent (Just event)
                    , Cmd.none
                    )

                Socket.IsConnectedReply isConnected_ ->
                    ( updateIsConnected isConnected_ model
                    , Cmd.none
                    )

                Socket.MakeRefReply ref ->
                    ( updateNextMessageRef (Just ref) model
                    , Cmd.none
                    )

                Socket.Message message ->
                    ( model
                        |> addSocketMessage message
                        |> updateLastSocketMessage (Just message)
                    , Cmd.none
                    )

                Socket.Opened ->
                    ( model
                        |> updateIsConnected True
                        |> updateSocketState Open
                    , joinChannels
                        model.channelsBeingJoined
                        model.channelOutFunc
                    )

                Socket.ProtocolReply protocol ->
                    ( updateProtocol (Just protocol) model
                    , Cmd.none
                    )

        TimeoutTick _ ->
            model
                |> timeoutTick
                |> retryTimeoutEvents



{- Subscriptions -}


subscriptions : Socket.PortIn Msg -> Channel.PortIn Msg -> Maybe (Channel.PortIn Msg) -> Model -> Sub Msg
subscriptions socketReceiver channelReceiver maybePeresenceReceiver model =
    Sub.batch
        [ Channel.subscriptions
            ChannelMsg
            channelReceiver
        , Socket.subscriptions
            SocketMsg
            socketReceiver
        , case maybePeresenceReceiver of
            Just presenceReceiver ->
                Presence.subscriptions
                    PresenceMsg
                    presenceReceiver

            Nothing ->
                Sub.none
        , if (model.timeoutEvents |> List.length) > 0 then
            Time.every 1000 TimeoutTick

          else
            Sub.none
        ]



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



{- Socket -}


connect : (PackageOut -> Cmd Socket.EventIn) -> Cmd Msg
connect channelOutFunc =
    Cmd.map SocketMsg <|
        Socket.send
            (Socket.Connect Nothing)
            channelOutFunc


getConnectionState : Model -> Cmd Msg
getConnectionState model =
    sendToSocket
        Socket.ConnectionState
        model


getEndpointURL : Model -> Cmd Msg
getEndpointURL model =
    sendToSocket
        Socket.EndPointURL
        model


getHasLogger : Model -> Cmd Msg
getHasLogger model =
    sendToSocket
        Socket.HasLogger
        model


getIsConnected : Model -> Cmd Msg
getIsConnected model =
    sendToSocket
        Socket.IsConnected
        model


getProtocol : Model -> Cmd Msg
getProtocol model =
    sendToSocket
        Socket.Protocol
        model


getSocketInfo : Model -> Cmd Msg
getSocketInfo model =
    Cmd.batch
        [ getConnectionState model
        , getHasLogger model
        , getIsConnected model
        , getProtocol model
        , makeRef model
        ]


makeRef : Model -> Cmd Msg
makeRef model =
    sendToSocket
        Socket.MakeRef
        model


sendToSocket : Socket.EventOut -> Model -> Cmd Msg
sendToSocket event model =
    Cmd.map SocketMsg <|
        Socket.send
            event
            model.socketOutFunc



{- Socket Events -}


addInvalidSocketEvent : String -> Model -> Model
addInvalidSocketEvent event model =
    model
        |> updateInvalidSocketEvents
            (event :: model.invalidSocketEvents)



{- Socket Messages -}


addSocketMessage : Socket.MessageConfig -> Model -> Model
addSocketMessage message model =
    model
        |> updateSocketMessages
            (message :: model.socketMessages)



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
        Open ->
            sendIfJoined
                topic
                event
                payload
                model

        Opening ->
            ( model
                |> addChannelBeingJoined topic
                |> addEventToQueue
                    { event = event
                    , payload = payload
                    , topic = topic
                    }
            , Cmd.none
            )

        Closed ->
            ( model
                |> addChannelBeingJoined topic
                |> addEventToQueue
                    { event = event
                    , payload = payload
                    , topic = topic
                    }
                |> updateSocketState Opening
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


updateConnectionState : Maybe String -> Model -> Model
updateConnectionState connectionState_ model =
    { model
        | connectionState = connectionState_
    }


updateHasLogger : Maybe Bool -> Model -> Model
updateHasLogger hasLogger_ model =
    { model
        | hasLogger = hasLogger_
    }


updateEndpointURL : Maybe String -> Model -> Model
updateEndpointURL endpointURL_ model =
    { model
        | endpointURL = endpointURL_
    }


updateInvalidSocketEvent : Maybe String -> Model -> Model
updateInvalidSocketEvent event model =
    { model
        | invalidSocketEvent = event
    }


updateInvalidSocketEvents : List String -> Model -> Model
updateInvalidSocketEvents events model =
    { model
        | invalidSocketEvents = events
    }


updateIsConnected : Bool -> Model -> Model
updateIsConnected isConnected_ model =
    { model
        | isConnected = isConnected_
    }


updateProtocol : Maybe String -> Model -> Model
updateProtocol protocol model =
    { model
        | protocol = protocol
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


updateLastSocketMessage : Maybe Socket.MessageConfig -> Model -> Model
updateLastSocketMessage message model =
    { model
        | lastSocketMessage = message
    }


updateNextMessageRef : Maybe String -> Model -> Model
updateNextMessageRef ref model =
    { model
        | nextMessageRef = ref
    }


updateSocketError : String -> Model -> Model
updateSocketError error model =
    { model
        | socketError = error
    }


updateSocketMessages : List Socket.MessageConfig -> Model -> Model
updateSocketMessages messages model =
    { model
        | socketMessages = messages
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
