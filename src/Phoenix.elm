module Phoenix exposing
    ( Model
    , PortConfig, init
    , connect, addConnectOptions, setConnectOptions, setConnectParams
    , Topic, join, JoinConfig, addJoinConfig
    , PushConfig, push, pushAll
    , subscriptions
    , Msg, update
    , DecoderError(..), PushResponse(..), MsgOut
    , requestConnectionState, requestEndpointURL, requestHasLogger, requestIsConnected, requestMakeRef, requestProtocol, requestSocketInfo
    )

{-| This module is a wrapper around the [Socket](Phoenix.Socket),
[Channel](Phoenix.Channel) and [Presence](Phoenix.Presence) modules. It handles
all the low level stuff with a simple, but extensive API. It automates a few
processes, and generally simplifies working with Phoenix WebSockets.

In order for this module to provide the benefits that it does, it is required
to add it to your model so that it can carry its own state and internal logic.

You can use the [Socket](Phoenix.Socket), [Channel](Phoenix.Channel) and
[Presence](Phoenix.Presence) modules directly, but it is probably unlikely you
will need to do so. The benefit(?) of using these modules directly, is that
they do not carry any state, and so do not need to be attached to your model.

Once you have installed the package, and followed the simple setup instructions
[here](https://package.elm-lang.org/packages/phollyer/elm-phoenix-websocket/latest/),
configuring this module is as simple as this:

    import Phoenix
    import Port


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
                { phoenixSend = Port.phoenixSend
                , socketReceiver = Port.socketReceiver
                , channelReceiver = Port.channelReceiver
                , presenceReceiver = Port.presenceReceiver
                }
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


# API

@docs Model

@docs PortConfig, init


# Connecting to the Socket

Connecting to the Socket is automatic on the first [push](#push) to a Channel.
However, if you want to connect before hand, you can use the
[connect](#connect) function.

If you want to set any [ConnectOption](Phoenix.Socket#ConnectOption)s on the
socket you can do so when you [init](#init) the [Model](#Model), or use the
[addConnectOptions](#addConnectOptions) or
[setConnectOptions](#setConnectOptions) functions.

If you want to send any params to the Socket when it connects at the Elixir end
you can use the [setConnectParams](#setConnectParams) function.

@docs connect, addConnectOptions, setConnectOptions, setConnectParams


# Joining a Channel

Joining a Channel is automatic on the first [push](#push) to the Channel.
However, if you want to join before hand, you can use the [join](#join)
function.

If you want to send any params to the Channel when you join at the Elixir end
you can use the [addJoinConfig](#addJoinConfig) function.

@docs Topic, join, JoinConfig, addJoinConfig


# Talking to Channels

When pushing a message to a Channel, the Socket will connect, and the Channel
will be joined if so required, and the message will be queued until the
[JoinOk](Phoenix.Channel#Msg) `Msg` is received. At which point, any queued
messages will be sent in a batch.

If the Socket is open and the Channel joined, the message will be sent
immediately.


## Pushing Messages

@docs PushConfig, push, pushAll


## Receiving Messages

@docs subscriptions

@docs Msg, update

@docs DecoderError, PushResponse, MsgOut

@docs requestConnectionState, requestEndpointURL, requestHasLogger, requestIsConnected, requestMakeRef, requestProtocol, requestSocketInfo

-}

import Dict exposing (Dict)
import Json.Decode as JD
import Json.Encode as JE
import List.Extra
import Phoenix.Channel as Channel
import Phoenix.Presence as Presence
import Phoenix.Socket as Socket
import Time


{-| The model that carries the internal state.

This is an opaque type, so use the provided API to interact with it.

-}
type Model
    = Model
        { channelsBeingJoined : List Topic
        , channelsJoined : List Topic
        , connectionState : Maybe String
        , connectOptions : List Socket.ConnectOption
        , connectParams : JE.Value
        , decoderErrors : List DecoderError
        , endpointURL : Maybe String
        , hasLogger : Maybe Bool
        , invalidSocketEvents : List String
        , isConnected : Bool
        , joinConfigs : List JoinConfig
        , lastDecoderError : Maybe DecoderError
        , lastInvalidSocketEvent : Maybe String
        , lastSocketMessage : Maybe Socket.MessageConfig
        , nextMessageRef : Maybe String
        , portConfig : PortConfig
        , protocol : Maybe String
        , pushCount : Int
        , pushResponse : Maybe PushResponse
        , queuedPushes : Dict Int PushConfig
        , socketError : String
        , socketMessages : List Socket.MessageConfig
        , socketState : SocketState
        , timeoutPushes : List PushConfig
        }


{-| A type alias representing the ports to be used to communicate with JS.

You can find the `port` module
[here](https://github.com/phollyer/elm-phoenix-websocket/tree/master/ports).

-}
type alias PortConfig =
    { phoenixSend :
        { msg : String
        , payload : JE.Value
        }
        -> Cmd Msg
    , socketReceiver :
        ({ msg : String
         , payload : JE.Value
         }
         -> Msg
        )
        -> Sub Msg
    , channelReceiver :
        ({ topic : String
         , msg : String
         , payload : JE.Value
         }
         -> Msg
        )
        -> Sub Msg
    , presenceReceiver :
        ({ topic : String
         , msg : String
         , payload : JE.Value
         }
         -> Msg
        )
        -> Sub Msg
    }


{-| Initialize the [Model](#Model), providing the [PortConfig](#PortConfig) and
any [ConnectOption](Phoenix.Socket#ConnectOption)s you want to set on the socket.

    import Phoenix
    import Phoenix.Socket as Socket
    import Port

    init : Model
    init =
        { phoenix =
            Phoenix.init
                { phoenixSend = Port.phoenixSend
                , socketReceiver = Port.socketReceiver
                , channelReceiver = Port.channelReceiver
                , presenceReceiver = Port.presenceReceiver
                }
                [ Socket.Timeout 10000 ]
        ...
        }

-}
init : PortConfig -> List Socket.ConnectOption -> Model
init portConfig connectOptions =
    Model
        { channelsBeingJoined = []
        , channelsJoined = []
        , connectionState = Nothing
        , connectOptions = connectOptions
        , connectParams = JE.null
        , decoderErrors = []
        , endpointURL = Nothing
        , hasLogger = Nothing
        , invalidSocketEvents = []
        , isConnected = False
        , joinConfigs = []
        , lastDecoderError = Nothing
        , lastInvalidSocketEvent = Nothing
        , lastSocketMessage = Nothing
        , nextMessageRef = Nothing
        , portConfig = portConfig
        , protocol = Nothing
        , pushCount = 0
        , pushResponse = Nothing
        , queuedPushes = Dict.empty
        , socketError = ""
        , socketMessages = []
        , socketState = Closed
        , timeoutPushes = []
        }



{- Connecting to the Socket -}


{-| Connect to the Socket.
-}
connect : Model -> ( Model, Cmd Msg )
connect (Model model) =
    case model.socketState of
        Closed ->
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
-}
addConnectOptions : List Socket.ConnectOption -> Model -> Model
addConnectOptions connectOptions (Model model) =
    updateConnectOptions
        (List.append model.connectOptions connectOptions)
        (Model model)


{-| Provide some [ConnectOption](Phoenix.Socket#ConnectOption)s to set on the
Socket when connecting.

**Note:** This will replace any current
[ConnectOption](Phoenix.Socket.ConnectOption)s that have already been set.

-}
setConnectOptions : List Socket.ConnectOption -> Model -> Model
setConnectOptions options model =
    updateConnectOptions options model


{-| Provide some params to send to the Socket when connecting at the Elixir
end.

    import Json.Encode as JE

    setConnectParams
        JE.object
            [ ("username", JE.string "username")
            , ("password", JE.string "password")
            ]
        model

-}
setConnectParams : JE.Value -> Model -> Model
setConnectParams params model =
    updateConnectParams params model



{- Joining a Channel -}


{-| A type alias representing the Channel topic id, for example
`"topic:subTopic"`.
-}
type alias Topic =
    String


{-| Join a Channel referenced by the [Topic](#Topic).
-}
join : Topic -> Model -> ( Model, Cmd Msg )
join topic (Model model) =
    case model.socketState of
        Open ->
            case List.Extra.find (\joinConfig -> joinConfig.topic == topic) model.joinConfigs of
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
                            , timeout = Nothing
                            }
                        |> join topic

        Opening ->
            ( addChannelBeingJoined topic (Model model)
            , Cmd.none
            )

        Closed ->
            Model model
                |> addChannelBeingJoined topic
                |> connect


{-| A type alias representing the config for joining a Channel.

  - `topic` - the channel topic id, for example: `"topic:subTopic"`.

  - `payload` - optional data to be sent to the channel when joining.

  - `timeout` - optional timeout, in ms, before retrying to join if the previous
    attempt failed.

-}
type alias JoinConfig =
    { topic : Topic
    , payload : Maybe JE.Value
    , timeout : Maybe Int
    }


{-| Add a [JoinConfig](#JoinConfig) to be used when joining a Channel
referenced by the [Topic](#Topic).
-}
addJoinConfig : JoinConfig -> Model -> Model
addJoinConfig config (Model model) =
    case List.Extra.find (\joinConfig -> joinConfig.topic == config.topic) model.joinConfigs of
        Just _ ->
            updateJoinConfigs
                (replace
                    (\c1 c2 -> c1.topic == c2.topic)
                    config
                    model.joinConfigs
                )
                (Model model)

        Nothing ->
            updateJoinConfigs
                (config :: model.joinConfigs)
                (Model model)


replace : (a -> a -> Bool) -> a -> List a -> List a
replace compareFunc newItem list =
    List.map
        (\item ->
            if compareFunc item newItem then
                newItem

            else
                item
        )
        list



{- Talking to Channels -}


{-| A type alias representing the config for pushing a message to a Channel.

  - `topic` - The Channel topic to send the push to.
  - `msg` - The message to send to the Channel.
  - `payload` - The params to send with the message. If you don't need to
    send any params, set this to
    [Json.Encode.null](https://package.elm-lang.org/packages/elm/json/latest/Json-Encode#null) .
  - `timeout` - Optional timeout in milliseconds to set on the push request.
  - `retrySecs` - Optional time in seconds before retrying to send the push
    after a timeout. A value of `Nothing` will prevent any automatic retries.
  - `ref` - A unique reference to be used to identify the push. If you set this
    yourself to anything other than 0, be sure that it is unique or you might
    see some unexpected behaviour. Setting it to 0 will allow the internal
    logic to manage the value.

-}
type alias PushConfig =
    { topic : Topic
    , msg : String
    , payload : JE.Value
    , timeout : Maybe Int
    , retrySecs : Maybe Int
    , ref : Int
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
        }
        model.phoenix

-}
push : PushConfig -> Model -> ( Model, Cmd Msg )
push config (Model model) =
    let
        pushRef =
            model.pushCount + 1

        config_ =
            { config | ref = pushRef }
    in
    Model model
        |> addPushToQueue config_
        |> updatePushCount pushRef
        |> pushIfJoined config_


{-| Push a list of messages together.

The messages will batched and the order in which they reach their respective
Channels is unknown.

-}
pushAll : List PushConfig -> Model -> ( Model, Cmd Msg )
pushAll _ model =
    ( model, Cmd.none )


pushIfJoined : PushConfig -> Model -> ( Model, Cmd Msg )
pushIfJoined config (Model model) =
    if model.channelsJoined |> List.member config.topic then
        ( Model model
        , Channel.push
            config
            model.portConfig.phoenixSend
        )

    else if model.channelsBeingJoined |> List.member config.topic then
        ( Model model
        , Cmd.none
        )

    else
        Model model
            |> addChannelBeingJoined config.topic
            |> join config.topic


pushIfConnected : PushConfig -> Model -> ( Model, Cmd Msg )
pushIfConnected config (Model model) =
    case model.socketState of
        Open ->
            pushIfJoined
                config
                (Model model)

        Opening ->
            ( Model model
                |> addChannelBeingJoined config.topic
                |> addPushToQueue config
            , Cmd.none
            )

        Closed ->
            ( Model model
                |> addChannelBeingJoined config.topic
                |> addPushToQueue config
                |> updateSocketState Opening
            , Socket.connect
                model.connectOptions
                (Just model.connectParams)
                model.portConfig.phoenixSend
            )


{-| Receive messages from the Socket, Channels and Pheonix Presence.

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
        , if (model.timeoutPushes |> List.length) > 0 then
            Time.every 1000 TimeoutTick

          else
            Sub.none
        ]


{-| -}
type DecoderError
    = Socket JD.Error


{-| -}
type alias MsgOut =
    String


{-| -}
type PushResponse
    = PushOk Topic MsgOut JE.Value Int
    | PushError Topic MsgOut JE.Value Int
    | PushTimeout Topic MsgOut JE.Value Int


type SocketState
    = Open
    | Opening
    | Closed



-- Update


{-| -}
type Msg
    = ChannelMsg Channel.Msg
    | PresenceMsg Presence.Msg
    | SocketMsg Socket.MsgIn
    | TimeoutTick Time.Posix


{-| -}
update : Msg -> Model -> ( Model, Cmd Msg )
update msg (Model model) =
    case msg of
        ChannelMsg (Channel.Closed _) ->
            ( Model model, Cmd.none )

        ChannelMsg (Channel.Error _) ->
            ( Model model, Cmd.none )

        ChannelMsg (Channel.InvalidMsg _ _ _) ->
            ( Model model, Cmd.none )

        ChannelMsg (Channel.JoinError _ _) ->
            ( Model model, Cmd.none )

        ChannelMsg (Channel.JoinOk topic _) ->
            ( Model model
                |> addJoinedChannel topic
                |> dropChannelBeingJoined topic
            , model.portConfig.phoenixSend
                |> sendPushes topic model.queuedPushes
            )

        ChannelMsg (Channel.JoinTimeout _ _) ->
            ( Model model, Cmd.none )

        ChannelMsg (Channel.LeaveOk _) ->
            ( Model model, Cmd.none )

        ChannelMsg (Channel.Message _ _ _) ->
            ( Model model, Cmd.none )

        ChannelMsg (Channel.PushError topic msgResult payloadResult refResult) ->
            case ( msgResult, payloadResult, refResult ) of
                ( Ok msg_, Ok payload, Ok ref ) ->
                    ( Model model
                        |> dropQueuedPush ref
                        |> updatePushResponse (PushError topic msg_ payload ref)
                    , Cmd.none
                    )

                _ ->
                    ( Model model, Cmd.none )

        ChannelMsg (Channel.PushOk topic msgResult payloadResult refResult) ->
            case ( msgResult, payloadResult, refResult ) of
                ( Ok msg_, Ok payload, Ok ref ) ->
                    ( Model model
                        |> dropQueuedPush ref
                        |> updatePushResponse (PushOk topic msg_ payload ref)
                    , Cmd.none
                    )

                _ ->
                    ( Model model, Cmd.none )

        ChannelMsg (Channel.PushTimeout topic msgResult payloadResult refResult) ->
            case ( msgResult, payloadResult, refResult ) of
                ( Ok msg_, Ok payload, Ok ref ) ->
                    case Dict.get ref model.queuedPushes of
                        Just pushConfig ->
                            ( Model model
                                |> addTimeoutPush pushConfig
                                |> updatePushResponse (PushTimeout topic msg_ payload ref)
                            , Cmd.none
                            )

                        Nothing ->
                            ( updatePushResponse
                                (PushTimeout topic msg_ payload ref)
                                (Model model)
                            , Cmd.none
                            )

                _ ->
                    ( Model model, Cmd.none )

        PresenceMsg (Presence.Diff _ _) ->
            ( Model model, Cmd.none )

        PresenceMsg (Presence.InvalidMsg _ _) ->
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

                Socket.InvalidMsg message ->
                    ( Model model
                        |> addInvalidSocketEvent message
                        |> updateLastInvalidSocketEvent (Just message)
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
                    Model model
                        |> updateIsConnected True
                        |> updateSocketState Open
                        |> joinChannels
                            model.channelsBeingJoined

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
                |> retryTimeoutPushs



{- Request information about the Socket -}


{-| -}
requestConnectionState : Model -> Cmd Msg
requestConnectionState model =
    sendToSocket
        Socket.ConnectionState
        model


{-| -}
requestEndpointURL : Model -> Cmd Msg
requestEndpointURL model =
    sendToSocket
        Socket.EndPointURL
        model


{-| -}
requestHasLogger : Model -> Cmd Msg
requestHasLogger model =
    sendToSocket
        Socket.HasLogger
        model


{-| -}
requestIsConnected : Model -> Cmd Msg
requestIsConnected model =
    sendToSocket
        Socket.IsConnected
        model


{-| -}
requestMakeRef : Model -> Cmd Msg
requestMakeRef model =
    sendToSocket
        Socket.MakeRef
        model


{-| -}
requestProtocol : Model -> Cmd Msg
requestProtocol model =
    sendToSocket
        Socket.Protocol
        model


{-| -}
requestSocketInfo : Model -> Cmd Msg
requestSocketInfo model =
    sendToSocket
        Socket.Info
        model



{- Decoder Errors -}


addDecoderError : DecoderError -> Model -> Model
addDecoderError decoderError (Model model) =
    if model.decoderErrors |> List.member decoderError then
        Model model

    else
        updateDecoderErrors
            (decoderError :: model.decoderErrors)
            (Model model)



{- Queued Pushes -}


addPushToQueue : PushConfig -> Model -> Model
addPushToQueue pushConfig (Model model) =
    updateQueuedPushes
        (Dict.insert pushConfig.ref pushConfig model.queuedPushes)
        (Model model)


dropQueuedPush : Int -> Model -> Model
dropQueuedPush ref (Model model) =
    updateQueuedPushes
        (Dict.remove ref model.queuedPushes)
        (Model model)



{- Socket -}


sendToSocket : Socket.MsgOut -> Model -> Cmd Msg
sendToSocket msg (Model model) =
    Socket.send
        msg
        model.portConfig.phoenixSend


addInvalidSocketEvent : String -> Model -> Model
addInvalidSocketEvent msg (Model model) =
    updateInvalidSocketEvents
        (msg :: model.invalidSocketEvents)
        (Model model)



{- Socket Messages -}


addSocketMessage : Socket.MessageConfig -> Model -> Model
addSocketMessage message (Model model) =
    updateSocketMessages
        (message :: model.socketMessages)
        (Model model)



{- Timeout Events -}


addTimeoutPush : PushConfig -> Model -> Model
addTimeoutPush pushConfig (Model model) =
    if model.timeoutPushes |> List.member pushConfig then
        Model model

    else
        updateTimeoutPushes
            (pushConfig :: model.timeoutPushes)
            (Model model)


retryTimeoutPushs : Model -> ( Model, Cmd Msg )
retryTimeoutPushs (Model model) =
    let
        ( pushesToSend, pushesStillTicking ) =
            List.partition
                (\pushConfig ->
                    pushConfig.retrySecs == Just 0 || pushConfig.retrySecs == Nothing
                )
                model.timeoutPushes
    in
    Model model
        |> updateTimeoutPushes pushesStillTicking
        |> sendTimeoutPushes pushesToSend


timeoutTick : Model -> Model
timeoutTick (Model model) =
    updateTimeoutPushes
        (List.map countdownPushRetry model.timeoutPushes)
        (Model model)


countdownPushRetry : PushConfig -> PushConfig
countdownPushRetry pushConfig =
    { pushConfig
        | retrySecs =
            Just <|
                Maybe.withDefault 1
                    pushConfig.retrySecs
                    - 1
    }



{- Channels -}


addChannelBeingJoined : Topic -> Model -> Model
addChannelBeingJoined topic (Model model) =
    if model.channelsBeingJoined |> List.member topic then
        Model model

    else
        updateChannelsBeingJoined
            (topic :: model.channelsBeingJoined)
            (Model model)


addJoinedChannel : Topic -> Model -> Model
addJoinedChannel topic (Model model) =
    if model.channelsJoined |> List.member topic then
        Model model

    else
        updateChannelsJoined
            (topic :: model.channelsJoined)
            (Model model)


dropChannelBeingJoined : Topic -> Model -> Model
dropChannelBeingJoined topic (Model model) =
    let
        channelsBeingJoined =
            model.channelsBeingJoined
                |> List.filter
                    (\topic_ -> topic_ /= topic)
    in
    updateChannelsBeingJoined
        channelsBeingJoined
        (Model model)


joinChannels : List Topic -> Model -> ( Model, Cmd Msg )
joinChannels topics model =
    List.foldl
        (\topic ( model_, cmd ) ->
            let
                ( m, c ) =
                    join topic model_
            in
            ( m, Cmd.batch [ c, cmd ] )
        )
        ( model, Cmd.none )
        topics



{- Server Requests - Private API -}


sendPushes : Topic -> Dict Int PushConfig -> ({ msg : String, payload : JE.Value } -> Cmd Msg) -> Cmd Msg
sendPushes topic queuedPushes portOut =
    queuedPushes
        |> Dict.values
        |> List.filterMap
            (\pushConfig ->
                if pushConfig.topic /= topic then
                    Nothing

                else
                    Just (sendPush pushConfig portOut)
            )
        |> Cmd.batch


sendPush : PushConfig -> ({ msg : String, payload : JE.Value } -> Cmd Msg) -> Cmd Msg
sendPush pushConfig portOut =
    Channel.push
        pushConfig
        portOut


sendTimeoutPush : PushConfig -> ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
sendTimeoutPush config ( Model model, cmd ) =
    case Dict.get config.ref model.queuedPushes of
        Just pushConfig ->
            let
                ( model_, cmd_ ) =
                    pushIfConnected
                        pushConfig
                        (Model model)
            in
            ( model_
            , Cmd.batch [ cmd, cmd_ ]
            )

        Nothing ->
            ( Model model, Cmd.none )


sendTimeoutPushes : List PushConfig -> Model -> ( Model, Cmd Msg )
sendTimeoutPushes pushConfigs model =
    case pushConfigs of
        [] ->
            ( model, Cmd.none )

        _ ->
            List.foldl
                sendTimeoutPush
                ( model, Cmd.none )
                pushConfigs



{- Update Model Fields -}


updateChannelsBeingJoined : List Topic -> Model -> Model
updateChannelsBeingJoined channelsBeingJoined (Model model) =
    Model
        { model
            | channelsBeingJoined = channelsBeingJoined
        }


updateChannelsJoined : List Topic -> Model -> Model
updateChannelsJoined channelsJoined (Model model) =
    Model
        { model
            | channelsJoined = channelsJoined
        }


updateConnectionState : Maybe String -> Model -> Model
updateConnectionState connectionState (Model model) =
    Model
        { model
            | connectionState = connectionState
        }


updateConnectOptions : List Socket.ConnectOption -> Model -> Model
updateConnectOptions options (Model model) =
    Model
        { model
            | connectOptions = options
        }


updateConnectParams : JE.Value -> Model -> Model
updateConnectParams params (Model model) =
    Model
        { model
            | connectParams = params
        }


updateDecoderErrors : List DecoderError -> Model -> Model
updateDecoderErrors decoderErrors (Model model) =
    Model
        { model
            | decoderErrors = decoderErrors
        }


updateEndpointURL : Maybe String -> Model -> Model
updateEndpointURL endpointURL (Model model) =
    Model
        { model
            | endpointURL = endpointURL
        }


updateHasLogger : Maybe Bool -> Model -> Model
updateHasLogger hasLogger (Model model) =
    Model
        { model
            | hasLogger = hasLogger
        }


updateInvalidSocketEvents : List String -> Model -> Model
updateInvalidSocketEvents msgs (Model model) =
    Model
        { model
            | invalidSocketEvents = msgs
        }


updateIsConnected : Bool -> Model -> Model
updateIsConnected isConnected (Model model) =
    Model
        { model
            | isConnected = isConnected
        }


updateJoinConfigs : List JoinConfig -> Model -> Model
updateJoinConfigs configs (Model model) =
    Model
        { model
            | joinConfigs = configs
        }


updateLastDecoderError : Maybe DecoderError -> Model -> Model
updateLastDecoderError error (Model model) =
    Model
        { model
            | lastDecoderError = error
        }


updateLastInvalidSocketEvent : Maybe String -> Model -> Model
updateLastInvalidSocketEvent msg (Model model) =
    Model
        { model
            | lastInvalidSocketEvent = msg
        }


updateLastSocketMessage : Maybe Socket.MessageConfig -> Model -> Model
updateLastSocketMessage message (Model model) =
    Model
        { model
            | lastSocketMessage = message
        }


updateNextMessageRef : Maybe String -> Model -> Model
updateNextMessageRef ref (Model model) =
    Model
        { model
            | nextMessageRef = ref
        }


updateProtocol : Maybe String -> Model -> Model
updateProtocol protocol (Model model) =
    Model
        { model
            | protocol = protocol
        }


updatePushCount : Int -> Model -> Model
updatePushCount count (Model model) =
    Model
        { model
            | pushCount = count
        }


updatePushResponse : PushResponse -> Model -> Model
updatePushResponse response (Model model) =
    Model
        { model
            | pushResponse = Just response
        }


updateQueuedPushes : Dict Int PushConfig -> Model -> Model
updateQueuedPushes queuedPushes (Model model) =
    Model
        { model
            | queuedPushes = queuedPushes
        }


updateSocketError : String -> Model -> Model
updateSocketError error (Model model) =
    Model
        { model
            | socketError = error
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


updateTimeoutPushes : List PushConfig -> Model -> Model
updateTimeoutPushes pushConfig (Model model) =
    Model
        { model
            | timeoutPushes = pushConfig
        }
