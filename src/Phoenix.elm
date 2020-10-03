module Phoenix exposing
    ( Model
    , init
    , setConnectOptions, setConnectParams
    , sendMessage
    , subscriptions
    , Msg, update
    , DecoderError(..), PushResponse(..)
    , requestConnectionState, requestEndpointURL, requestHasLogger, requestIsConnected, requestMakeRef, requestProtocol, requestSocketInfo
    )

{-| This module is a wrapper around the [Socket](Phoenix.Socket),
[Channel](Phoenix.Channel) and [Presence](Phoenix.Presence) modules. It handles
all the low level stuff with a simple API, automates a few processes, and
generally simplifies working with Phoenix WebSockets.

You can use the [Socket](Phoenix.Socket), [Channel](Phoenix.Channel) and
[Presence](Phoenix.Presence) modules directly, but it is probably unlikely you
will need to do so. The benefit(?) of using these modules directly, is that
they do not carry any state, and so do not need to be attached to your model.

In order for this module to provide the benefits that it does, it is required
to add it to your model so that it can carry its own state and internal logic.
So, once you have installed the package, and followed the simple setup instructions
[here](https://package.elm-lang.org/packages/phollyer/elm-phoenix-websocket/latest/),
configuring this module is as simple as this:

    import Phoenix
    import Port

    type alias Model =
        { phoenix : Phoenix.Model Phoenix.Msg
        ...
        }


    init : Model
    init =
        { phoenix =
            Phoenix.init
                Port.phoenixSend
                Nothing
                Nothing
        ...
        }

    type Msg
        = PhoenixMsg Phoenix.Msg
        | ...

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

    subscriptions : Model -> Sub Msg
    subscriptions model =
        Sub.map PhoenixMsg <|
            Phoenix.subscriptions
                Port.socketReceiver
                Port.channelReceiver
                Port.presenceReceiver
                model.phoenix


# API

@docs Model

@docs init

@docs setConnectOptions, setConnectParams

@docs sendMessage

@docs subscriptions

@docs Msg, update

@docs DecoderError, PushResponse

@docs requestConnectionState, requestEndpointURL, requestHasLogger, requestIsConnected, requestMakeRef, requestProtocol, requestSocketInfo

-}

import Json.Decode as JD
import Json.Encode as JE
import Phoenix.Channel as Channel
import Phoenix.Presence as Presence
import Phoenix.Socket as Socket
import Time


{-| The model that carries the internal state.

This is an opaque type, so use the provided API to access its fields.

-}
type Model msg
    = Model
        { channelsBeingJoined : List Topic
        , channelsJoined : List Topic
        , connectionState : Maybe String
        , connectOptions : Maybe Socket.ConnectOptions
        , connectParams : Maybe JE.Value
        , decoderErrors : List DecoderError
        , endpointURL : Maybe String
        , hasLogger : Maybe Bool
        , invalidSocketEvents : List String
        , isConnected : Bool
        , lastDecoderError : Maybe DecoderError
        , lastInvalidSocketEvent : Maybe String
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


{-| Init
-}
init : (PackageOut -> Cmd msg) -> Maybe Socket.ConnectOptions -> Maybe JE.Value -> Model msg
init portOut connectOptions connectParams =
    Model
        { channelsBeingJoined = []
        , channelsJoined = []
        , connectionState = Nothing
        , connectOptions = connectOptions
        , connectParams = connectParams
        , decoderErrors = []
        , endpointURL = Nothing
        , hasLogger = Nothing
        , invalidSocketEvents = []
        , isConnected = False
        , lastDecoderError = Nothing
        , lastInvalidSocketEvent = Nothing
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


{-| -}
setConnectOptions : Socket.ConnectOptions -> Model msg -> Model msg
setConnectOptions options model =
    updateConnectOptions (Just options) model


{-| -}
setConnectParams : JE.Value -> Model msg -> Model msg
setConnectParams params model =
    updateConnectParams (Just params) model


{-| -}
type DecoderError
    = Socket JD.Error


type alias EventOut =
    String


{-| -}
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


{-| -}
type Msg
    = ChannelMsg Channel.EventIn
    | PresenceMsg Presence.EventIn
    | SocketMsg Socket.EventIn
    | TimeoutTick Time.Posix


{-| -}
update : Msg -> Model msg -> ( Model msg, Cmd msg )
update msg (Model model) =
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

                Socket.ConnectionStateReply result ->
                    case result of
                        Ok connectionState ->
                            ( updateConnectionState (Just connectionState) (Model model)
                            , Cmd.none
                            )

                        Err error ->
                            ( Model model
                                |> addDecoderError (Socket error)
                                |> updateLastDecoderError (Just (Socket error))
                            , Cmd.none
                            )

                Socket.EndPointURLReply result ->
                    case result of
                        Ok endpointURL ->
                            ( updateEndpointURL (Just endpointURL) (Model model)
                            , Cmd.none
                            )

                        Err error ->
                            ( Model model
                                |> addDecoderError (Socket error)
                                |> updateLastDecoderError (Just (Socket error))
                            , Cmd.none
                            )

                Socket.Error result ->
                    case result of
                        Ok error ->
                            ( updateSocketError error (Model model)
                            , Cmd.none
                            )

                        Err error ->
                            ( Model model
                                |> addDecoderError (Socket error)
                                |> updateLastDecoderError (Just (Socket error))
                            , Cmd.none
                            )

                Socket.HasLoggerReply result ->
                    case result of
                        Ok hasLogger ->
                            ( updateHasLogger hasLogger (Model model)
                            , Cmd.none
                            )

                        Err error ->
                            ( Model model
                                |> addDecoderError (Socket error)
                                |> updateLastDecoderError (Just (Socket error))
                            , Cmd.none
                            )

                Socket.InfoReply result ->
                    case result of
                        Ok info ->
                            ( Model model
                                |> updateConnectionState (Just info.connectionState)
                                |> updateEndpointURL (Just info.endpointURL)
                                |> updateHasLogger info.hasLogger
                                |> updateIsConnected info.isConnected
                                |> updateNextMessageRef (Just info.nextMessageRef)
                                |> updateProtocol (Just info.protocol)
                            , Cmd.none
                            )

                        Err error ->
                            ( Model model
                                |> addDecoderError (Socket error)
                                |> updateLastDecoderError (Just (Socket error))
                            , Cmd.none
                            )

                Socket.InvalidEvent event ->
                    ( Model model
                        |> addInvalidSocketEvent event
                        |> updateLastInvalidSocketEvent (Just event)
                    , Cmd.none
                    )

                Socket.IsConnectedReply result ->
                    case result of
                        Ok isConnected ->
                            ( updateIsConnected isConnected (Model model)
                            , Cmd.none
                            )

                        Err error ->
                            ( Model model
                                |> addDecoderError (Socket error)
                                |> updateLastDecoderError (Just (Socket error))
                            , Cmd.none
                            )

                Socket.MakeRefReply result ->
                    case result of
                        Ok ref ->
                            ( updateNextMessageRef (Just ref) (Model model)
                            , Cmd.none
                            )

                        Err error ->
                            ( Model model
                                |> addDecoderError (Socket error)
                                |> updateLastDecoderError (Just (Socket error))
                            , Cmd.none
                            )

                Socket.Message result ->
                    case result of
                        Ok message ->
                            ( Model model
                                |> addSocketMessage message
                                |> updateLastSocketMessage (Just message)
                            , Cmd.none
                            )

                        Err error ->
                            ( Model model
                                |> addDecoderError (Socket error)
                                |> updateLastDecoderError (Just (Socket error))
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

                Socket.ProtocolReply result ->
                    case result of
                        Ok protocol ->
                            ( updateProtocol (Just protocol) (Model model)
                            , Cmd.none
                            )

                        Err error ->
                            ( Model model
                                |> addDecoderError (Socket error)
                                |> updateLastDecoderError (Just (Socket error))
                            , Cmd.none
                            )

        TimeoutTick _ ->
            Model model
                |> timeoutTick
                |> retryTimeoutEvents



{-
   Public API
-}


{-| Send a message to a Channel.

In order for the message to be sent:

  - the Socket must be open, and
  - the Channel Topic must have been joined

If either of these processes have not been completed, the message will be
queued until the Channel has been joined - at which point, all queued messages
will be sent.

Connecting to the Socket, and joining the Channel Topic is handled internally
when the first message is sent, so you don't need to worry about these
processes.

If the Socket is open, and the Channel Topic joined, the message will be sent
immediately.

-}
sendMessage : Topic -> EventOut -> JE.Value -> Model msg -> ( Model msg, Cmd msg )
sendMessage topic event payload model =
    sendIfConnected
        topic
        event
        payload
        model



{- Request information about the Socket -}


{-| -}
requestConnectionState : Model msg -> Cmd msg
requestConnectionState model =
    sendToSocket
        Socket.ConnectionState
        model


{-| -}
requestEndpointURL : Model msg -> Cmd msg
requestEndpointURL model =
    sendToSocket
        Socket.EndPointURL
        model


{-| -}
requestHasLogger : Model msg -> Cmd msg
requestHasLogger model =
    sendToSocket
        Socket.HasLogger
        model


{-| -}
requestIsConnected : Model msg -> Cmd msg
requestIsConnected model =
    sendToSocket
        Socket.IsConnected
        model


{-| -}
requestMakeRef : Model msg -> Cmd msg
requestMakeRef model =
    sendToSocket
        Socket.MakeRef
        model


{-| -}
requestProtocol : Model msg -> Cmd msg
requestProtocol model =
    sendToSocket
        Socket.Protocol
        model


{-| -}
requestSocketInfo : Model msg -> Cmd msg
requestSocketInfo model =
    sendToSocket
        Socket.Info
        model


{-| Subscriptions
-}
subscriptions : Socket.PortIn Msg -> Channel.PortIn Msg -> Channel.PortIn Msg -> Model msg -> Sub Msg
subscriptions socketReceiver channelReceiver presenceReceiver (Model model) =
    Sub.batch
        [ Channel.subscriptions
            ChannelMsg
            channelReceiver
        , Socket.subscriptions
            SocketMsg
            socketReceiver
        , Presence.subscriptions
            PresenceMsg
            presenceReceiver
        , if (model.timeoutEvents |> List.length) > 0 then
            Time.every 1000 TimeoutTick

          else
            Sub.none
        ]



{- Decoder Errors -}


addDecoderError : DecoderError -> Model msg -> Model msg
addDecoderError decoderError (Model model) =
    if model.decoderErrors |> List.member decoderError then
        Model model

    else
        updateDecoderErrors
            (decoderError :: model.decoderErrors)
            (Model model)



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


connect : (PackageOut -> Cmd msg) -> Maybe JE.Value -> Maybe Socket.ConnectOptions -> Cmd msg
connect portOut params maybeOptions =
    case maybeOptions of
        Just options ->
            Socket.send
                (Socket.ConnectWithOptions options params)
                portOut

        Nothing ->
            Socket.send
                (Socket.Connect params)
                portOut


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
            , connect
                model.portOut
                model.connectParams
                model.connectOptions
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
updateConnectionState connectionState (Model model) =
    Model
        { model
            | connectionState = connectionState
        }


updateConnectOptions : Maybe Socket.ConnectOptions -> Model msg -> Model msg
updateConnectOptions options (Model model) =
    Model
        { model
            | connectOptions = options
        }


updateConnectParams : Maybe JE.Value -> Model msg -> Model msg
updateConnectParams params (Model model) =
    Model
        { model
            | connectParams = params
        }


updateDecoderErrors : List DecoderError -> Model msg -> Model msg
updateDecoderErrors decoderErrors (Model model) =
    Model
        { model
            | decoderErrors = decoderErrors
        }


updateEndpointURL : Maybe String -> Model msg -> Model msg
updateEndpointURL endpointURL (Model model) =
    Model
        { model
            | endpointURL = endpointURL
        }


updateHasLogger : Maybe Bool -> Model msg -> Model msg
updateHasLogger hasLogger (Model model) =
    Model
        { model
            | hasLogger = hasLogger
        }


updateInvalidSocketEvents : List String -> Model msg -> Model msg
updateInvalidSocketEvents events (Model model) =
    Model
        { model
            | invalidSocketEvents = events
        }


updateIsConnected : Bool -> Model msg -> Model msg
updateIsConnected isConnected (Model model) =
    Model
        { model
            | isConnected = isConnected
        }


updateLastDecoderError : Maybe DecoderError -> Model msg -> Model msg
updateLastDecoderError error (Model model) =
    Model
        { model
            | lastDecoderError = error
        }


updateLastInvalidSocketEvent : Maybe String -> Model msg -> Model msg
updateLastInvalidSocketEvent event (Model model) =
    Model
        { model
            | lastInvalidSocketEvent = event
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
