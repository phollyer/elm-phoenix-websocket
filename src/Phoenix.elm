module Phoenix exposing
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

import Json.Encode as JE
import Phoenix.Channel as Channel
import Phoenix.Presence as Presence
import Phoenix.Socket as Socket
import Time



{- Init -}


init : (PackageOut -> Cmd msg) -> Model msg
init portOut =
    Model
        { channelsBeingJoined = []
        , channelsJoined = []
        , connectionState = Nothing
        , endpointURL = Nothing
        , hasLogger = Nothing
        , invalidSocketEvent = Nothing
        , invalidSocketEvents = []
        , isConnected = False
        , lastSocketMessage = Nothing
        , nextMessageRef = Nothing
        , portOut = portOut
        , protocol = Nothing
        , pushResponse = Nothing
        , queuedEvents = []
        , socketError = ""
        , socketMessages = []
        , socketState = Closed
        , timeoutEvents = []
        }



{- Model -}


type Model msg
    = Model
        { channelsBeingJoined : List Topic
        , channelsJoined : List Topic
        , connectionState : Maybe String
        , endpointURL : Maybe String
        , hasLogger : Maybe Bool
        , invalidSocketEvent : Maybe String
        , invalidSocketEvents : List String
        , isConnected : Bool
        , lastSocketMessage : Maybe Socket.MessageConfig
        , nextMessageRef : Maybe String
        , portOut : PackageOut -> Cmd msg
        , protocol : Maybe String
        , pushResponse : Maybe PushResponse
        , queuedEvents : List QueuedEvent
        , socketError : String
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


update : Msg -> Model msg -> ( Model msg, Cmd msg )
update msg (Model model) =
    let
        _ =
            Debug.log "" msg
    in
    case msg of
        ChannelMsg (Channel.Closed _) ->
            ( Model model, Cmd.none )

        ChannelMsg (Channel.Error _ _) ->
            ( Model model, Cmd.none )

        ChannelMsg (Channel.InvalidEvent _ _ _) ->
            ( Model model, Cmd.none )

        ChannelMsg (Channel.JoinError _ _) ->
            ( Model model, Cmd.none )

        ChannelMsg (Channel.JoinOk topic _) ->
            ( Model model
                |> addJoinedChannel topic
                |> dropChannelBeingJoined topic
            , model.portOut
                |> sendQueuedEvents topic model.queuedEvents
            )

        ChannelMsg (Channel.JoinTimeout _ _) ->
            ( Model model, Cmd.none )

        ChannelMsg (Channel.LeaveOk _) ->
            ( Model model, Cmd.none )

        ChannelMsg (Channel.Message _ _ _) ->
            ( Model model, Cmd.none )

        ChannelMsg (Channel.PushError topic event payload) ->
            handlePushError
                topic
                event
                payload
                (Model model)

        ChannelMsg (Channel.PushOk topic event payload) ->
            handlePushOk
                topic
                event
                payload
                (Model model)

        ChannelMsg (Channel.PushTimeout topic event payload) ->
            handlePushTimeout
                topic
                event
                payload
                (Model model)

        PresenceMsg (Presence.Diff _ _) ->
            ( Model model, Cmd.none )

        PresenceMsg (Presence.InvalidEvent _ _) ->
            ( Model model, Cmd.none )

        PresenceMsg (Presence.Join _ _) ->
            ( Model model, Cmd.none )

        PresenceMsg (Presence.Leave _ _) ->
            ( Model model, Cmd.none )

        PresenceMsg (Presence.State _ _) ->
            ( Model model, Cmd.none )

        SocketMsg subMsg ->
            case subMsg of
                Socket.Closed ->
                    ( updateSocketState Closed (Model model)
                    , Cmd.none
                    )

                Socket.ConnectionStateReply connectionState_ ->
                    ( updateConnectionState (Just connectionState_) (Model model)
                    , Cmd.none
                    )

                Socket.EndPointURLReply endpointURL_ ->
                    ( updateEndpointURL (Just endpointURL_) (Model model)
                    , Cmd.none
                    )

                Socket.Error error ->
                    ( updateSocketError error (Model model)
                    , Cmd.none
                    )

                Socket.HasLoggerReply hasLogger_ ->
                    ( updateHasLogger hasLogger_ (Model model)
                    , Cmd.none
                    )

                Socket.InvalidEvent event ->
                    ( Model model
                        |> addInvalidSocketEvent event
                        |> updateInvalidSocketEvent (Just event)
                    , Cmd.none
                    )

                Socket.IsConnectedReply isConnected_ ->
                    ( updateIsConnected isConnected_ (Model model)
                    , Cmd.none
                    )

                Socket.MakeRefReply ref ->
                    ( updateNextMessageRef (Just ref) (Model model)
                    , Cmd.none
                    )

                Socket.Message message ->
                    ( Model model
                        |> addSocketMessage message
                        |> updateLastSocketMessage (Just message)
                    , Cmd.none
                    )

                Socket.Opened ->
                    ( Model model
                        |> updateIsConnected True
                        |> updateSocketState Open
                    , joinChannels
                        model.channelsBeingJoined
                        model.portOut
                    )

                Socket.ProtocolReply protocol ->
                    ( updateProtocol (Just protocol) (Model model)
                    , Cmd.none
                    )

        TimeoutTick _ ->
            Model model
                |> timeoutTick
                |> retryTimeoutEvents



{- Subscriptions -}


subscriptions : Socket.PortIn Msg -> Channel.PortIn Msg -> Maybe (Channel.PortIn Msg) -> Model msg -> Sub Msg
subscriptions socketReceiver channelReceiver maybePeresenceReceiver (Model model) =
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


addEventToQueue : QueuedEvent -> Model msg -> Model msg
addEventToQueue event (Model model) =
    if model.queuedEvents |> List.member event then
        Model model

    else
        updateQueuedEvents
            (event :: model.queuedEvents)
            (Model model)


dropQueuedEvent : QueuedEvent -> Model msg -> Model msg
dropQueuedEvent queued (Model model) =
    Model model
        |> updateQueuedEvents
            (model.queuedEvents
                |> List.filter
                    (\event -> event /= queued)
            )



{- Socket -}


connect : (PackageOut -> Cmd msg) -> Cmd msg
connect portOut =
    Socket.send
        (Socket.Connect Nothing)
        portOut


getConnectionState : Model msg -> Cmd msg
getConnectionState model =
    sendToSocket
        Socket.ConnectionState
        model


getEndpointURL : Model msg -> Cmd msg
getEndpointURL model =
    sendToSocket
        Socket.EndPointURL
        model


getHasLogger : Model msg -> Cmd msg
getHasLogger model =
    sendToSocket
        Socket.HasLogger
        model


getIsConnected : Model msg -> Cmd msg
getIsConnected model =
    sendToSocket
        Socket.IsConnected
        model


getProtocol : Model msg -> Cmd msg
getProtocol model =
    sendToSocket
        Socket.Protocol
        model


getSocketInfo : Model msg -> Cmd msg
getSocketInfo model =
    Cmd.batch
        [ getConnectionState model
        , getHasLogger model
        , getIsConnected model
        , getProtocol model
        , makeRef model
        ]


makeRef : Model msg -> Cmd msg
makeRef model =
    sendToSocket
        Socket.MakeRef
        model


sendToSocket : Socket.EventOut -> Model msg -> Cmd msg
sendToSocket event (Model model) =
    Socket.send
        event
        model.portOut



{- Socket Events -}


addInvalidSocketEvent : String -> Model msg -> Model msg
addInvalidSocketEvent event (Model model) =
    updateInvalidSocketEvents
        (event :: model.invalidSocketEvents)
        (Model model)



{- Socket Messages -}


addSocketMessage : Socket.MessageConfig -> Model msg -> Model msg
addSocketMessage message (Model model) =
    updateSocketMessages
        (message :: model.socketMessages)
        (Model model)



{- Timeout Events -}


addTimeoutEvent : TimeoutEvent -> Model msg -> Model msg
addTimeoutEvent event (Model model) =
    if model.timeoutEvents |> List.member event then
        Model model

    else
        updateTimeoutEvents
            (event :: model.timeoutEvents)
            (Model model)


retryTimeoutEvents : Model msg -> ( Model msg, Cmd msg )
retryTimeoutEvents (Model model) =
    let
        ( eventsToSend, eventsStillTicking ) =
            model.timeoutEvents
                |> List.partition
                    (\event -> event.timeUntilRetry == 0)
    in
    Model model
        |> updateTimeoutEvents eventsStillTicking
        |> sendTimeoutEvents eventsToSend


timeoutTick : Model msg -> Model msg
timeoutTick (Model model) =
    Model model
        |> updateTimeoutEvents
            (model.timeoutEvents
                |> List.map
                    (\event -> { event | timeUntilRetry = event.timeUntilRetry - 1 })
            )



{- Channels -}


addChannelBeingJoined : Topic -> Model msg -> Model msg
addChannelBeingJoined topic (Model model) =
    if model.channelsBeingJoined |> List.member topic then
        Model model

    else
        updateChannelsBeingJoined
            (topic :: model.channelsBeingJoined)
            (Model model)


addJoinedChannel : Topic -> Model msg -> Model msg
addJoinedChannel topic (Model model) =
    if model.channelsJoined |> List.member topic then
        Model model

    else
        updateChannelsJoined
            (topic :: model.channelsJoined)
            (Model model)


dropChannelBeingJoined : Topic -> Model msg -> Model msg
dropChannelBeingJoined topic (Model model) =
    let
        channelsBeingJoined =
            model.channelsBeingJoined
                |> List.filter
                    (\channelTopic -> channelTopic /= topic)
    in
    updateChannelsBeingJoined
        channelsBeingJoined
        (Model model)


join : Topic -> (PackageOut -> Cmd msg) -> Cmd msg
join topic portOut =
    Channel.send
        (Channel.Join
            { payload = Nothing
            , topic = topic
            , timeout = Nothing
            }
        )
        portOut


joinChannels : List Topic -> (PackageOut -> Cmd msg) -> Cmd msg
joinChannels channelTopics portOut =
    channelTopics
        |> List.map
            (\topic -> join topic portOut)
        |> Cmd.batch



{- Pushes -}


handlePushError : Channel.Topic -> Channel.PushEvent -> JE.Value -> Model msg -> ( Model msg, Cmd msg )
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


handlePushOk : Channel.Topic -> Channel.PushEvent -> JE.Value -> Model msg -> ( Model msg, Cmd msg )
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


handlePushTimeout : Channel.Topic -> Channel.PushEvent -> JE.Value -> Model msg -> ( Model msg, Cmd msg )
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


sendMessage : Topic -> EventOut -> JE.Value -> Model msg -> ( Model msg, Cmd msg )
sendMessage topic event payload model =
    sendIfConnected
        topic
        event
        payload
        model


send : Topic -> EventOut -> JE.Value -> (PackageOut -> Cmd msg) -> Cmd msg
send topic event payload portOut =
    Channel.send
        (Channel.Push
            { topic = Just topic
            , event = event
            , timeout = Nothing
            , payload = payload
            }
        )
        portOut


sendIfConnected : Topic -> EventOut -> JE.Value -> Model msg -> ( Model msg, Cmd msg )
sendIfConnected topic event payload (Model model) =
    case model.socketState of
        Open ->
            sendIfJoined
                topic
                event
                payload
                (Model model)

        Opening ->
            ( Model model
                |> addChannelBeingJoined topic
                |> addEventToQueue
                    { event = event
                    , payload = payload
                    , topic = topic
                    }
            , Cmd.none
            )

        Closed ->
            ( Model model
                |> addChannelBeingJoined topic
                |> addEventToQueue
                    { event = event
                    , payload = payload
                    , topic = topic
                    }
                |> updateSocketState Opening
            , connect model.portOut
            )


sendIfJoined : Topic -> EventOut -> JE.Value -> Model msg -> ( Model msg, Cmd msg )
sendIfJoined topic event payload (Model model) =
    if model.channelsJoined |> List.member topic then
        ( Model model
        , send
            topic
            event
            payload
            model.portOut
        )

    else if model.channelsBeingJoined |> List.member topic then
        ( addEventToQueue
            { event = event
            , payload = payload
            , topic = topic
            }
            (Model model)
        , Cmd.none
        )

    else
        ( Model model
            |> addChannelBeingJoined topic
            |> addEventToQueue
                { event = event
                , payload = payload
                , topic = topic
                }
        , join topic model.portOut
        )


sendQueuedEvents : Topic -> List QueuedEvent -> (PackageOut -> Cmd msg) -> Cmd msg
sendQueuedEvents topic queuedEvents portOut =
    queuedEvents
        |> List.filterMap
            (\event ->
                if event.topic /= topic then
                    Nothing

                else
                    Just (sendQueuedEvent event portOut)
            )
        |> Cmd.batch


sendQueuedEvent : QueuedEvent -> (PackageOut -> Cmd msg) -> Cmd msg
sendQueuedEvent { event, payload, topic } portOut =
    send
        topic
        event
        payload
        portOut


sendTimeoutEvent : TimeoutEvent -> ( Model msg, Cmd msg ) -> ( Model msg, Cmd msg )
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


sendTimeoutEvents : List TimeoutEvent -> Model msg -> ( Model msg, Cmd msg )
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


updateChannelsBeingJoined : List Topic -> Model msg -> Model msg
updateChannelsBeingJoined channelsBeingJoined (Model model) =
    Model
        { model
            | channelsBeingJoined = channelsBeingJoined
        }


updateChannelsJoined : List Topic -> Model msg -> Model msg
updateChannelsJoined channelsJoined (Model model) =
    Model
        { model
            | channelsJoined = channelsJoined
        }


updateConnectionState : Maybe String -> Model msg -> Model msg
updateConnectionState connectionState_ (Model model) =
    Model
        { model
            | connectionState = connectionState_
        }


updateHasLogger : Maybe Bool -> Model msg -> Model msg
updateHasLogger hasLogger_ (Model model) =
    Model
        { model
            | hasLogger = hasLogger_
        }


updateEndpointURL : Maybe String -> Model msg -> Model msg
updateEndpointURL endpointURL_ (Model model) =
    Model
        { model
            | endpointURL = endpointURL_
        }


updateInvalidSocketEvent : Maybe String -> Model msg -> Model msg
updateInvalidSocketEvent event (Model model) =
    Model
        { model
            | invalidSocketEvent = event
        }


updateInvalidSocketEvents : List String -> Model msg -> Model msg
updateInvalidSocketEvents events (Model model) =
    Model
        { model
            | invalidSocketEvents = events
        }


updateIsConnected : Bool -> Model msg -> Model msg
updateIsConnected isConnected_ (Model model) =
    Model
        { model
            | isConnected = isConnected_
        }


updateProtocol : Maybe String -> Model msg -> Model msg
updateProtocol protocol (Model model) =
    Model
        { model
            | protocol = protocol
        }


updatePushResponse : PushResponse -> Model msg -> Model msg
updatePushResponse response (Model model) =
    Model
        { model
            | pushResponse = Just response
        }


updateQueuedEvents : List QueuedEvent -> Model msg -> Model msg
updateQueuedEvents queuedEvents (Model model) =
    Model
        { model
            | queuedEvents = queuedEvents
        }


updateLastSocketMessage : Maybe Socket.MessageConfig -> Model msg -> Model msg
updateLastSocketMessage message (Model model) =
    Model
        { model
            | lastSocketMessage = message
        }


updateNextMessageRef : Maybe String -> Model msg -> Model msg
updateNextMessageRef ref (Model model) =
    Model
        { model
            | nextMessageRef = ref
        }


updateSocketError : String -> Model msg -> Model msg
updateSocketError error (Model model) =
    Model
        { model
            | socketError = error
        }


updateSocketMessages : List Socket.MessageConfig -> Model msg -> Model msg
updateSocketMessages messages (Model model) =
    Model
        { model
            | socketMessages = messages
        }


updateSocketState : SocketState -> Model msg -> Model msg
updateSocketState state (Model model) =
    Model
        { model
            | socketState = state
        }


updateTimeoutEvents : List TimeoutEvent -> Model msg -> Model msg
updateTimeoutEvents timeoutEvents (Model model) =
    Model
        { model
            | timeoutEvents = timeoutEvents
        }
