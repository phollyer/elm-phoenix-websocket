module Page.HandleSocketMessages exposing
    ( Model
    , Msg
    , init
    , subscriptions
    , toSession
    , update
    , view
    )

import Browser.Navigation as Nav
import Colors.Opaque as Color
import Element as El exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Example exposing (Action(..), Example(..))
import Extra.String as String
import Json.Decode as JD
import Json.Decode.Extra exposing (andMap)
import Json.Encode as JE exposing (Value)
import Json.Encode.Extra exposing (maybe)
import Phoenix
import Phoenix.Socket as Socket
import Route
import Session exposing (Session)
import View.Example as Example
import View.Layout as Layout
import View.Menu as Menu



{- Init -}


init : Session -> Maybe String -> Maybe ID -> ( Model, Cmd Msg )
init session maybeExample maybeId =
    let
        example =
            case maybeExample of
                Just ex ->
                    Example.fromString ex

                Nothing ->
                    ManageSocketHeartbeat Connect
    in
    getExampleId
        { session = session
        , example = example
        , exampleId = maybeId
        , userId = Nothing
        , heartbeatCount = 0
        , heartbeat = True
        , channelMessages = True
        , channelMessageCount = 0
        , channelMessageList = []
        , presenceMessages = True
        , presenceMessageCount = 0
        , presenceState = []
        }



{- exampleId is a unique ID supplied by "example_controller:control" that
   is used to identify the example in each tab. The tabs can then all join the
   same controlling Channel which routes messages between them.
-}


getExampleId : Model -> ( Model, Cmd Msg )
getExampleId model =
    let
        topic =
            case model.exampleId of
                Just id ->
                    "example_controller:" ++ id

                Nothing ->
                    "example_controller:control"
    in
    case model.example of
        ManagePresenceMessages _ ->
            Phoenix.join topic (Session.phoenix model.session)
                |> updatePhoenix model

        _ ->
            ( model, Cmd.none )



{- Model -}


type alias Model =
    { session : Session
    , example : Example
    , exampleId : Maybe ID
    , userId : Maybe ID
    , heartbeatCount : Int
    , heartbeat : Bool
    , channelMessages : Bool
    , channelMessageCount : Int
    , channelMessageList : List ChannelMsg
    , presenceMessages : Bool
    , presenceMessageCount : Int
    , presenceState : List Presence
    }


type alias ID =
    String


type alias ChannelMsg =
    { topic : Phoenix.Topic
    , event : Phoenix.Event
    , payload : Value
    , joinRef : Maybe String
    , ref : Maybe String
    }


type alias Presence =
    { id : String
    , meta : Meta
    }


type alias Meta =
    { exampleState : ExampleState }


type ExampleState
    = Joined
    | Joining
    | Leaving
    | NotJoined


controllerTopic : Maybe String -> String
controllerTopic maybeId =
    case maybeId of
        Just id ->
            "example_controller:" ++ id

        Nothing ->
            ""


pushConfig : Phoenix.Push
pushConfig =
    { topic = ""
    , event = ""
    , payload = JE.null
    , timeout = Nothing
    , retryStrategy = Phoenix.Drop
    , ref = Nothing
    }



{- Update -}


type Msg
    = GotButtonClick Example
    | GotHomeBtnClick
    | GotRemoteButtonClick ID Example
    | GotMenuItem Example
    | GotPhoenixMsg Phoenix.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        phoenix =
            Session.phoenix model.session
    in
    case msg of
        GotHomeBtnClick ->
            ( model
            , Route.pushUrl
                (Session.navKey model.session)
                Route.Home
            )

        GotMenuItem example ->
            Phoenix.disconnectAndReset (Just 1000) phoenix
                |> updatePhoenix
                    (reset model)
                |> updateExample example

        GotButtonClick example ->
            case example of
                ManageSocketHeartbeat action ->
                    case action of
                        Connect ->
                            phoenix
                                |> Phoenix.setConnectOptions [ Socket.HeartbeatIntervalMillis 1000 ]
                                |> Phoenix.connect
                                |> updatePhoenix model

                        Disconnect ->
                            Phoenix.disconnect (Just 1000) phoenix
                                |> updatePhoenix model
                                |> resetHeartbeatCount

                        On ->
                            Phoenix.heartbeatMessagesOn phoenix
                                |> setHeartbeat True model

                        Off ->
                            Phoenix.heartbeatMessagesOff phoenix
                                |> setHeartbeat False model

                        _ ->
                            ( model, Cmd.none )

                ManageChannelMessages action ->
                    case action of
                        Send ->
                            Phoenix.push
                                { pushConfig
                                    | topic = "example:manage_channel_messages"
                                    , event = "empty_message"
                                }
                                phoenix
                                |> updatePhoenix model

                        On ->
                            Phoenix.socketChannelMessagesOn phoenix
                                |> setChannelMessages True model

                        Off ->
                            Phoenix.socketChannelMessagesOff phoenix
                                |> setChannelMessages False model

                        _ ->
                            ( model, Cmd.none )

                ManagePresenceMessages action ->
                    case action of
                        Join ->
                            Phoenix.join "example:manage_presence_messages" phoenix
                                |> updatePhoenix model

                        Leave ->
                            Phoenix.leave "example:manage_presence_messages" phoenix
                                |> updatePhoenix model

                        On ->
                            Phoenix.socketPresenceMessagesOn phoenix
                                |> setPresenceMessages True model

                        Off ->
                            Phoenix.socketPresenceMessagesOff phoenix
                                |> setPresenceMessages False model

                        _ ->
                            ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        GotRemoteButtonClick userId example ->
            case example of
                ManagePresenceMessages action ->
                    case action of
                        Join ->
                            Phoenix.push
                                { pushConfig
                                    | topic = controllerTopic model.exampleId
                                    , event = "join_example"
                                    , payload = encodeUserId userId
                                }
                                phoenix
                                |> updatePhoenix model

                        Leave ->
                            Phoenix.push
                                { pushConfig
                                    | topic = controllerTopic model.exampleId
                                    , event = "leave_example"
                                    , payload = encodeUserId userId
                                }
                                phoenix
                                |> updatePhoenix model

                        _ ->
                            ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        GotPhoenixMsg subMsg ->
            let
                ( newModel, cmd ) =
                    Phoenix.update subMsg phoenix
                        |> updatePhoenix model

                phx =
                    Session.phoenix newModel.session
            in
            case Phoenix.phoenixMsg phx of
                Phoenix.SocketMessage (Phoenix.Heartbeat _) ->
                    ( { newModel | heartbeatCount = newModel.heartbeatCount + 1 }, cmd )

                Phoenix.SocketMessage (Phoenix.ChannelMessage msgInfo) ->
                    ( { newModel
                        | channelMessageCount = newModel.channelMessageCount + 1
                        , channelMessageList = msgInfo :: newModel.channelMessageList
                      }
                    , cmd
                    )

                Phoenix.SocketMessage (Phoenix.PresenceMessage presenceMsg) ->
                    ( { newModel | presenceMessageCount = newModel.presenceMessageCount + 1 }, cmd )

                Phoenix.ChannelResponse (Phoenix.JoinOk "example:manage_presence_messages" payload) ->
                    Phoenix.push
                        { pushConfig
                            | topic = controllerTopic newModel.exampleId
                            , event = "joined_example"
                        }
                        phx
                        |> updatePhoenix newModel
                        |> batch [ cmd ]

                Phoenix.ChannelResponse (Phoenix.LeaveOk "example:manage_presence_messages") ->
                    Phoenix.push
                        { pushConfig
                            | topic = controllerTopic newModel.exampleId
                            , event = "left_example"
                        }
                        phx
                        |> updatePhoenix newModel
                        |> batch [ cmd ]

                {- Remote Control -}
                Phoenix.ChannelResponse (Phoenix.JoinOk topic payload) ->
                    case Phoenix.topicParts topic of
                        ( "example_controller", "control" ) ->
                            case decodeExampleId payload of
                                Ok exampleId ->
                                    Phoenix.batch
                                        [ Phoenix.leave "example_controller:control"
                                        , Phoenix.join (controllerTopic (Just exampleId))
                                        ]
                                        phx
                                        |> updatePhoenix { newModel | exampleId = Just exampleId }
                                        |> batch [ cmd ]

                                _ ->
                                    ( newModel, cmd )

                        ( "example_controller", _ ) ->
                            case decodeUserId payload of
                                Ok id ->
                                    ( { newModel | userId = Just id }
                                    , Cmd.batch
                                        [ cmd
                                        , Cmd.map GotPhoenixMsg <|
                                            Phoenix.addEvents (controllerTopic newModel.exampleId)
                                                [ "join_example"
                                                , "leave_example"
                                                ]
                                                phoenix
                                        ]
                                    )

                                _ ->
                                    ( newModel, cmd )

                        _ ->
                            ( newModel, cmd )

                Phoenix.ChannelEvent _ event payload ->
                    case ( event, decodeUserId payload ) of
                        ( "join_example", Ok userId ) ->
                            if newModel.userId == Just userId then
                                Phoenix.batch
                                    [ Phoenix.join "example:manage_presence_messages"
                                    , Phoenix.push
                                        { pushConfig
                                            | topic = controllerTopic newModel.exampleId
                                            , event = "joining_example"
                                        }
                                    ]
                                    phoenix
                                    |> updatePhoenix newModel

                            else
                                ( newModel, cmd )

                        ( "leave_example", Ok userId ) ->
                            if newModel.userId == Just userId then
                                Phoenix.batch
                                    [ Phoenix.leave "example:manage_presence_messages"
                                    , Phoenix.push
                                        { pushConfig
                                            | topic = controllerTopic newModel.exampleId
                                            , event = "leaving_example"
                                        }
                                    ]
                                    phoenix
                                    |> updatePhoenix newModel

                            else
                                ( newModel, cmd )

                        _ ->
                            ( newModel, cmd )

                Phoenix.PresenceEvent (Phoenix.State topic state) ->
                    case Phoenix.topicParts topic of
                        ( "example_controller", _ ) ->
                            ( { newModel
                                | presenceState =
                                    toPresenceState state
                              }
                            , cmd
                            )

                        _ ->
                            ( newModel, cmd )

                _ ->
                    ( newModel, cmd )


toPresenceState : List Phoenix.Presence -> List Presence
toPresenceState presences =
    List.map toPresence presences


toPresence : Phoenix.Presence -> Presence
toPresence presence =
    { id = presence.id
    , meta =
        case presence.metas of
            -- There will only ever be one meta in the list because each new
            -- join will be considered a new user, so a user cannot have
            -- multiple joins.
            meta :: _ ->
                case decodeMeta meta of
                    Ok m ->
                        m

                    _ ->
                        { exampleState = NotJoined }

            [] ->
                { exampleState = NotJoined }
    }


setChannelMessages : Bool -> Model -> Cmd Phoenix.Msg -> ( Model, Cmd Msg )
setChannelMessages channelMessages model phxCmd =
    ( { model
        | channelMessages = channelMessages
      }
    , Cmd.map GotPhoenixMsg phxCmd
    )


setHeartbeat : Bool -> Model -> Cmd Phoenix.Msg -> ( Model, Cmd Msg )
setHeartbeat heartbeat model phxCmd =
    ( { model
        | heartbeat = heartbeat
      }
    , Cmd.map GotPhoenixMsg phxCmd
    )


setPresenceMessages : Bool -> Model -> Cmd Phoenix.Msg -> ( Model, Cmd Msg )
setPresenceMessages presenceMessages model phxCmd =
    ( { model
        | presenceMessages = presenceMessages
      }
    , Cmd.map GotPhoenixMsg phxCmd
    )


reset : Model -> Model
reset model =
    { model
        | exampleId = Nothing
        , userId = Nothing
        , heartbeatCount = 0
        , heartbeat = True
        , channelMessages = True
        , channelMessageCount = 0
        , channelMessageList = []
        , presenceMessages = True
        , presenceMessageCount = 0
        , presenceState = []
    }


resetHeartbeatCount : ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
resetHeartbeatCount ( model, cmd ) =
    ( { model
        | heartbeatCount = 0
      }
    , cmd
    )


updateExample : Example -> ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
updateExample example ( model, cmd ) =
    getExampleId { model | example = example }
        |> Tuple.mapSecond (\cmd_ -> Cmd.batch [ cmd, cmd_ ])


updatePhoenix : Model -> ( Phoenix.Model, Cmd Phoenix.Msg ) -> ( Model, Cmd Msg )
updatePhoenix model ( phoenix, phoenixCmd ) =
    ( { model
        | session = Session.updatePhoenix phoenix model.session
      }
    , Cmd.map GotPhoenixMsg phoenixCmd
    )


batch : List (Cmd Msg) -> ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
batch cmds ( model, cmd ) =
    ( model
    , Cmd.batch (cmd :: cmds)
    )



{- Decoders -}


decodeExampleId : Value -> Result JD.Error String
decodeExampleId payload =
    JD.decodeValue (JD.field "example_id" JD.string) payload


decodeUserId : Value -> Result JD.Error String
decodeUserId payload =
    JD.decodeValue (JD.field "user_id" JD.string) payload


metaDecoder : JD.Decoder Meta
metaDecoder =
    JD.succeed
        Meta
        |> andMap
            (JD.field "example_state" JD.string
                |> JD.andThen stateDecoder
            )


stateDecoder : String -> JD.Decoder ExampleState
stateDecoder state =
    case state of
        "Joined" ->
            JD.succeed Joined

        "Joining" ->
            JD.succeed Joining

        "Leaving" ->
            JD.succeed Leaving

        "Not Joined" ->
            JD.succeed NotJoined

        _ ->
            JD.fail <|
                "Not a valid Example State: "
                    ++ state


decodeMeta : Value -> Result JD.Error Meta
decodeMeta payload =
    JD.decodeValue metaDecoder payload



{- Encoders -}


encodeUserId : String -> Value
encodeUserId userId =
    JE.object
        [ ( "user_id", JE.string userId ) ]



{- View -}


view : Model -> { title : String, content : Element Msg }
view model =
    let
        phoenix =
            Session.phoenix model.session
    in
    { title = "Handle Socket Messages"
    , content =
        Layout.init
            |> Layout.homeMsg (Just GotHomeBtnClick)
            |> Layout.title "Handle Socket Messages"
            |> Layout.introduction
                [ Layout.paragraph Layout.Example
                    [ El.text "By default, the PhoenixJS "
                    , Layout.code Layout.Example "onMessage"
                    , El.text " handler for the Socket is setup to send all Socket messages through the incoming "
                    , Layout.code Layout.Example "port"
                    , El.text ", which you may, or may not, want. These examples show how to control the types of messages that are allowed through."
                    ]
                , Layout.paragraph Layout.Example
                    [ El.text "Clicking on a function will take you to its documentation." ]
                ]
            |> Layout.menu
                (Menu.init
                    |> Menu.options
                        [ ( Example.toString (ManageSocketHeartbeat Anything), GotMenuItem (ManageSocketHeartbeat Anything) )
                        , ( Example.toString (ManageChannelMessages Anything), GotMenuItem (ManageChannelMessages Anything) )
                        , ( Example.toString (ManagePresenceMessages Anything), GotMenuItem (ManagePresenceMessages Anything) )
                        ]
                    |> Menu.selected
                        (Example.toString model.example)
                    |> Menu.render Menu.Default
                )
            |> Layout.example
                (Example.init
                    |> Example.id model.exampleId
                    |> Example.userId model.userId
                    |> Example.description
                        (description model.example model.exampleId)
                    |> Example.controls
                        (controls model phoenix)
                    |> Example.remoteControls
                        (remoteControls model phoenix)
                    |> Example.info
                        (info model)
                    |> Example.applicableFunctions
                        (applicableFunctions model.example)
                    |> Example.usefulFunctions
                        (usefulFunctions model.example phoenix)
                    |> Example.render Example.Default
                )
            |> Layout.render Layout.Example
    }


description : Example -> Maybe ID -> List (Element msg)
description example maybeId =
    case example of
        ManageSocketHeartbeat _ ->
            [ Layout.paragraph Layout.Example
                [ El.text "Choose whether to receive the heartbeat as an incoming Socket message. For this example, the heartbeat interval is set at 1 second." ]
            ]

        ManageChannelMessages _ ->
            [ Layout.paragraph Layout.Example
                [ El.text "Choose whether to receive Channel messages as an incoming Socket message. "
                , El.text ""
                ]
            ]

        ManagePresenceMessages _ ->
            [ Layout.paragraph Layout.Example
                [ El.text "Choose whether to receive Presence messages as an incoming Socket message. "
                , El.text "To get the best out of this example, you should open it in mulitple tabs. Click "
                , El.newTabLink
                    [ Font.color Color.dodgerblue
                    , El.mouseOver
                        [ Font.color Color.lavender ]
                    ]
                    { url =
                        case maybeId of
                            Just id ->
                                "/HandleSocketMessages?example=ManagePresenceMessages&id=" ++ id

                            Nothing ->
                                "/HandleSocketMessages?example=ManagePresenceMessages"
                    , label = El.text "here"
                    }
                , El.text " to open a new tab(s). You will then be able to control each tab from the tab you are in."
                ]
            ]

        _ ->
            []


controls : Model -> Phoenix.Model -> Element Msg
controls { example, heartbeat, channelMessages, presenceMessages } phoenix =
    case example of
        ManageSocketHeartbeat _ ->
            buttons
                [ connectButton ManageSocketHeartbeat phoenix
                , heartbeatOnButton ManageSocketHeartbeat heartbeat
                , heartbeatOffButton ManageSocketHeartbeat heartbeat
                , disconnectButton ManageSocketHeartbeat phoenix
                ]

        ManageChannelMessages _ ->
            buttons
                [ sendMessageButton ManageChannelMessages
                , channelMessagesOn ManageChannelMessages channelMessages
                , channelMessagesOff ManageChannelMessages channelMessages
                ]

        ManagePresenceMessages _ ->
            buttons
                [ joinButton ManagePresenceMessages GotButtonClick (not <| Phoenix.channelJoined "example:manage_presence_messages" phoenix)
                , presenceOnButton ManagePresenceMessages presenceMessages
                , presenceOffButton ManagePresenceMessages presenceMessages
                , leaveButton ManagePresenceMessages GotButtonClick (Phoenix.channelJoined "example:manage_presence_messages" phoenix)
                ]

        _ ->
            El.none


remoteControls : Model -> Phoenix.Model -> List ( String, Element Msg )
remoteControls { example, userId, presenceState } phoenix =
    case example of
        ManagePresenceMessages _ ->
            List.filterMap (maybeRemoteControl userId) presenceState

        _ ->
            []


maybeRemoteControl : Maybe ID -> Presence -> Maybe ( String, Element Msg )
maybeRemoteControl userId presence =
    if userId == Just presence.id then
        Nothing

    else
        Just <|
            ( presence.id
            , buttons
                [ joinButton ManagePresenceMessages (GotRemoteButtonClick presence.id) (presence.meta.exampleState == NotJoined)
                , leaveButton ManagePresenceMessages (GotRemoteButtonClick presence.id) (presence.meta.exampleState == Joined)
                ]
            )


buttons : List (Element Msg) -> Element Msg
buttons btns =
    El.row
        [ El.width El.fill
        , El.height <| El.px 60
        , El.spacing 20
        ]
    <|
        List.map
            (El.el
                [ El.width El.fill
                , El.centerY
                ]
            )
            btns


connectButton : (Action -> Example) -> Phoenix.Model -> Element Msg
connectButton example phoenix =
    El.el
        [ El.alignRight ]
    <|
        Layout.button Layout.Example
            { label = "Connect"
            , example = example Connect
            , onPress = GotButtonClick
            , enabled =
                case Phoenix.socketState phoenix of
                    Phoenix.Disconnected _ ->
                        True

                    _ ->
                        False
            }


disconnectButton : (Action -> Example) -> Phoenix.Model -> Element Msg
disconnectButton example phoenix =
    El.el
        [ El.alignLeft ]
    <|
        Layout.button Layout.Example
            { label = "Disconnect"
            , example = example Disconnect
            , onPress = GotButtonClick
            , enabled = Phoenix.socketState phoenix == Phoenix.Connected
            }


heartbeatOnButton : (Action -> Example) -> Bool -> Element Msg
heartbeatOnButton example heartbeat =
    El.el
        [ El.centerX ]
    <|
        Layout.button Layout.Example
            { label = "Heartbeat On"
            , example = example On
            , onPress = GotButtonClick
            , enabled = not heartbeat
            }


heartbeatOffButton : (Action -> Example) -> Bool -> Element Msg
heartbeatOffButton example heartbeat =
    El.el
        [ El.centerX ]
    <|
        Layout.button Layout.Example
            { label = "Heartbeat Off"
            , example = example Off
            , onPress = GotButtonClick
            , enabled = heartbeat
            }


joinButton : (Action -> Example) -> (Example -> Msg) -> Bool -> Element Msg
joinButton example onPress enabled =
    El.el
        [ El.alignRight ]
    <|
        Layout.button Layout.Example
            { label = "Join Channel"
            , example = example Join
            , onPress = onPress
            , enabled = enabled
            }


leaveButton : (Action -> Example) -> (Example -> Msg) -> Bool -> Element Msg
leaveButton example onPress enabled =
    El.el
        [ El.alignLeft ]
    <|
        Layout.button Layout.Example
            { label = "Leave Channel"
            , example = example Leave
            , onPress = onPress
            , enabled = enabled
            }


presenceOnButton : (Action -> Example) -> Bool -> Element Msg
presenceOnButton example presence =
    El.el
        [ El.centerX ]
    <|
        Layout.button Layout.Example
            { label = "Presence On"
            , example = example On
            , onPress = GotButtonClick
            , enabled = not presence
            }


presenceOffButton : (Action -> Example) -> Bool -> Element Msg
presenceOffButton example presence =
    El.el
        [ El.centerX ]
    <|
        Layout.button Layout.Example
            { label = "Presence Off"
            , example = example Off
            , onPress = GotButtonClick
            , enabled = presence
            }


sendMessageButton : (Action -> Example) -> Element Msg
sendMessageButton example =
    El.el
        [ El.alignRight ]
    <|
        Layout.button Layout.Example
            { label = "Push Message"
            , example = example Send
            , onPress = GotButtonClick
            , enabled = True
            }


channelMessagesOn : (Action -> Example) -> Bool -> Element Msg
channelMessagesOn example channelMessages =
    El.el
        [ El.centerX ]
    <|
        Layout.button Layout.Example
            { label = "Messages On"
            , example = example On
            , onPress = GotButtonClick
            , enabled = not channelMessages
            }


channelMessagesOff : (Action -> Example) -> Bool -> Element Msg
channelMessagesOff example channelMessages =
    El.el
        [ El.alignLeft ]
    <|
        Layout.button Layout.Example
            { label = "Messages Off"
            , example = example Off
            , onPress = GotButtonClick
            , enabled = channelMessages
            }


info : Model -> List (Element Msg)
info model =
    let
        container =
            El.el
                [ El.paddingXY 0 10 ]
    in
    case model.example of
        ManageSocketHeartbeat _ ->
            [ container
                (El.text ("Heartbeat Count: " ++ String.fromInt model.heartbeatCount))
            ]

        ManageChannelMessages _ ->
            container
                (El.paragraph
                    []
                    [ El.el [ Font.color Color.darkslateblue ] (El.text "Message Count: ")
                    , El.text (String.fromInt model.channelMessageCount)
                    ]
                )
                :: List.map formatChannelMessages model.channelMessageList

        ManagePresenceMessages _ ->
            [ container
                (El.text ("Message Count: " ++ String.fromInt model.presenceMessageCount))
            ]

        _ ->
            [ El.none ]


formatChannelMessages : ChannelMsg -> Element Msg
formatChannelMessages msg =
    let
        formatted =
            List.map
                (\( label, value ) ->
                    El.paragraph
                        []
                        [ El.el [ Font.color Color.darkslateblue ] (El.text label)
                        , El.text value
                        ]
                )
                [ ( "Topic: ", msg.topic )
                , ( "Event: ", msg.event )
                , ( "Payload: ", JE.encode 2 msg.payload )
                , ( "Join Ref: ", Maybe.withDefault "Nothing" msg.joinRef )
                , ( "Ref: ", Maybe.withDefault "Nothing" msg.ref )
                ]
    in
    El.column
        [ El.spacing 10 ]
    <|
        List.append
            [ El.el
                [ Font.bold ]
                (El.text "Channel Message")
            ]
            formatted


applicableFunctions : Example -> List String
applicableFunctions example =
    case example of
        ManageSocketHeartbeat _ ->
            [ "Phoenix.setConnectOptions"
            , "Phoenix.heartbeatMessagesOn"
            , "Phoenix.heartbeatMessagesOff"
            ]

        ManageChannelMessages _ ->
            [ "Phoenix.push"
            , "Phoenix.socketChannelMessagesOn"
            , "Phoenix.socketChannelMessagesOff"
            ]

        ManagePresenceMessages _ ->
            [ "Phoenix.join"
            , "Phoenix.socketPresenceMessagesOn"
            , "Phoenix.socketPresenceMessagesOff"
            , "Phoeinx.leave"
            ]

        _ ->
            []


usefulFunctions : Example -> Phoenix.Model -> List ( String, String )
usefulFunctions example phoenix =
    case example of
        ManageSocketHeartbeat _ ->
            [ ( "Phoenix.socketState", Phoenix.socketStateToString phoenix )
            , ( "Phoenix.connectionState", Phoenix.connectionState phoenix |> String.printQuoted )
            , ( "Phoenix.isConnected", Phoenix.isConnected phoenix |> String.printBool )
            ]

        ManageChannelMessages _ ->
            [ ( "Phoenix.socketState", Phoenix.socketStateToString phoenix )
            , ( "Phoenix.connectionState", Phoenix.connectionState phoenix |> String.printQuoted )
            , ( "Phoenix.isConnected", Phoenix.isConnected phoenix |> String.printBool )
            , ( "Phoenix.channelJoined", Phoenix.channelJoined "example:manage_channel_messages" phoenix |> String.printBool )
            , ( "Phoenix.joinedChannels", Phoenix.joinedChannels phoenix |> String.printList )
            ]

        ManagePresenceMessages _ ->
            [ ( "Phoenix.socketState", Phoenix.socketStateToString phoenix )
            , ( "Phoenix.connectionState", Phoenix.connectionState phoenix |> String.printQuoted )
            , ( "Phoenix.isConnected", Phoenix.isConnected phoenix |> String.printBool )
            , ( "Phoenix.channelJoined", Phoenix.channelJoined "example:manage_presence_messages" phoenix |> String.printBool )
            , ( "Phoenix.joinedChannels"
              , Phoenix.joinedChannels phoenix
                    |> List.filter (String.startsWith "example:")
                    |> String.printList
              )
            , ( "Phoenix.lastPresenceJoin", Phoenix.lastPresenceJoin "example:manage_presence_messages" phoenix |> String.printMaybe "Presence" )
            , ( "Phoenix.lastPresenceLeave", Phoenix.lastPresenceLeave "example:manage_presence_messages" phoenix |> String.printMaybe "Presence" )
            ]

        _ ->
            []



{- Subscriptions -}


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.map GotPhoenixMsg <|
        Phoenix.subscriptions (Session.phoenix model.session)



{- Session -}


toSession : Model -> Session
toSession model =
    model.session
