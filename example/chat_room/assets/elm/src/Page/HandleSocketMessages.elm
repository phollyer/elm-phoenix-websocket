module Page.HandleSocketMessages exposing
    ( Model
    , Msg
    , init
    , subscriptions
    , toSession
    , update
    , view
    )

import Colors.Opaque as Color
import Element as El exposing (Element)
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Example exposing (Action(..), Example(..))
import Extra.String as String
import Json.Decode as JD
import Json.Decode.Extra exposing (andMap)
import Json.Encode as JE exposing (Value)
import Json.Encode.Extra exposing (maybe)
import Page
import Phoenix
import Phoenix.Socket as Socket
import Session exposing (Session)



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



{- The example ID is a unique ID supplied by "example_controller:control" that
   is used to identify each tab, and so enable remote control of each tab.
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
    Phoenix.join topic (Session.phoenix model.session)
        |> updatePhoenix model


pushConfig : Phoenix.Push
pushConfig =
    { topic = ""
    , event = ""
    , payload = JE.null
    , timeout = Nothing
    , retryStrategy = Phoenix.Drop
    , ref = Nothing
    }



{- Model -}


type alias Presence =
    { id : String
    , meta : Meta
    }


type alias Meta =
    { exampleJoined : Bool }


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


type alias ChannelMsg =
    { topic : Phoenix.Topic
    , event : Phoenix.Event
    , payload : Value
    , joinRef : Maybe String
    , ref : Maybe String
    }


type alias ID =
    String


controllerTopic : Maybe String -> String
controllerTopic maybeId =
    case maybeId of
        Just id ->
            "example_controller:" ++ id

        Nothing ->
            "example_controller:control"



{- Update -}


type Msg
    = GotButtonClick Example
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
        GotButtonClick example ->
            case example of
                ManageSocketHeartbeat action ->
                    case action of
                        Connect ->
                            phoenix
                                |> Phoenix.setConnectOptions
                                    [ Socket.HeartbeatIntervalMillis 1000 ]
                                |> Phoenix.connect
                                |> updatePhoenix model

                        Disconnect ->
                            Phoenix.disconnect phoenix
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

        GotMenuItem example ->
            Phoenix.disconnect phoenix
                |> updatePhoenix model
                |> updateExample example

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
                    ( { newModel
                        | heartbeatCount =
                            newModel.heartbeatCount + 1
                      }
                    , cmd
                    )

                Phoenix.SocketMessage (Phoenix.ChannelMessage msgInfo) ->
                    ( { newModel
                        | channelMessageCount =
                            newModel.channelMessageCount + 1
                        , channelMessageList =
                            msgInfo :: newModel.channelMessageList
                      }
                    , cmd
                    )

                Phoenix.SocketMessage (Phoenix.PresenceMessage presenceMsg) ->
                    ( { newModel
                        | presenceMessageCount =
                            newModel.presenceMessageCount + 1
                      }
                    , cmd
                    )

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
                                        [ ( Phoenix.leave, [ "example_controller:control" ] )
                                        , ( Phoenix.join, [ controllerTopic (Just exampleId) ] )
                                        ]
                                        phx
                                        |> updatePhoenix
                                            { newModel
                                                | exampleId = Just exampleId
                                            }
                                        |> batch
                                            [ cmd ]

                                _ ->
                                    ( newModel, cmd )

                        ( "example_controller", _ ) ->
                            case decodeUserId payload of
                                Ok id ->
                                    ( { newModel
                                        | userId = Just id
                                      }
                                    , Cmd.batch
                                        [ cmd
                                        , Cmd.map GotPhoenixMsg <|
                                            Phoenix.addEvents (controllerTopic model.exampleId)
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
                                Phoenix.join "example:manage_presence_messages" phoenix
                                    |> updatePhoenix model

                            else
                                ( newModel, Cmd.none )

                        ( "leave_example", Ok userId ) ->
                            if newModel.userId == Just userId then
                                Phoenix.leave "example:manage_presence_messages" phoenix
                                    |> updatePhoenix model

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
                            , Cmd.none
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
                        { exampleJoined = False }

            [] ->
                { exampleJoined = False }
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


resetHeartbeatCount : ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
resetHeartbeatCount ( model, cmd ) =
    ( { model
        | heartbeatCount = 0
      }
    , cmd
    )


updateExample : Example -> ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
updateExample example ( model, cmd ) =
    ( { model
        | example = example
      }
    , cmd
    )


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
        |> andMap (JD.field "example_joined" JD.bool)


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
        Page.container
            [ Page.header "Handle Socket Messages"
            , Page.introduction
                [ Page.paragraph
                    [ El.text "By default, the PhoenixJS "
                    , Page.code "onMessage"
                    , El.text " handler for the Socket is setup to send all Socket messages through the incoming "
                    , Page.code "port"
                    , El.text ", which you may, or may not, want. These examples show how to control the types of messages that are allowed through."
                    ]
                , Page.paragraph
                    [ El.text "Clicking on a function will take you to its documentation." ]
                ]
            , Page.menu
                [ ( Example.toString (ManageSocketHeartbeat Anything), GotMenuItem (ManageSocketHeartbeat Anything) )
                , ( Example.toString (ManageChannelMessages Anything), GotMenuItem (ManageChannelMessages Anything) )
                , ( Example.toString (ManagePresenceMessages Anything), GotMenuItem (ManagePresenceMessages Anything) )
                ]
                (Example.toString model.example)
            , Example.init
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
                |> Example.view
            ]
    }


description : Example -> Maybe ID -> List (Element msg)
description example maybeId =
    case example of
        ManageSocketHeartbeat _ ->
            [ Page.paragraph
                [ El.text "Choose whether to receive the heartbeat as an incoming Socket message. For this example, the heartbeat interval is set at 1 second." ]
            ]

        ManageChannelMessages _ ->
            [ Page.paragraph
                [ El.text "Choose whether to receive Channel messages as an incoming Socket message. "
                , El.text ""
                ]
            ]

        ManagePresenceMessages _ ->
            [ Page.paragraph
                [ El.text "Choose whether to receive Presence messages as an incoming Socket message. "
                , El.text "To get the best out of this example, you should open it in mulitple tabs. Click "
                , El.newTabLink
                    []
                    { url =
                        case maybeId of
                            Just id ->
                                "/HandleSocketMessages?example=ManagePresenceMessages&id=" ++ id

                            Nothing ->
                                "/HandleSocketMessages?example=ManagePresenceMessages"
                    , label =
                        El.el
                            [ Font.color Color.dodgerblue
                            , El.mouseOver
                                [ Font.color Color.lavender ]
                            ]
                            (El.text "here")
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
remoteControls { example, userId, presenceState, presenceMessages } phoenix =
    case example of
        ManagePresenceMessages _ ->
            List.filterMap
                (\presence ->
                    if Just presence.id == userId then
                        Nothing

                    else
                        Just <|
                            ( presence.id
                            , buttons
                                [ joinButton ManagePresenceMessages (GotRemoteButtonClick presence.id) (not presence.meta.exampleJoined)
                                , presenceOnButton ManagePresenceMessages presenceMessages
                                , presenceOffButton ManagePresenceMessages presenceMessages
                                , leaveButton ManagePresenceMessages (GotRemoteButtonClick presence.id) presence.meta.exampleJoined
                                ]
                            )
                )
                presenceState

        _ ->
            []


buttons : List (Element Msg) -> Element Msg
buttons btns =
    El.row
        [ El.width El.fill
        , El.height <| El.px 60
        , El.spacing 20
        ]
    <|
        List.map
            (\button ->
                El.el
                    [ El.width El.fill
                    , El.centerY
                    ]
                    button
            )
            btns


connectButton : (Action -> Example) -> Phoenix.Model -> Element Msg
connectButton exampleFunc phoenix =
    El.el
        [ El.alignRight ]
    <|
        Page.button
            { label = "Connect"
            , example = exampleFunc Connect
            , onPress = GotButtonClick
            , enabled =
                case Phoenix.socketState phoenix of
                    Phoenix.Disconnected _ ->
                        True

                    _ ->
                        False
            }


disconnectButton : (Action -> Example) -> Phoenix.Model -> Element Msg
disconnectButton exampleFunc phoenix =
    El.el
        [ El.alignLeft ]
    <|
        Page.button
            { label = "Disconnect"
            , example = exampleFunc Disconnect
            , onPress = GotButtonClick
            , enabled = Phoenix.socketState phoenix == Phoenix.Connected
            }


heartbeatOnButton : (Action -> Example) -> Bool -> Element Msg
heartbeatOnButton exampleFunc heartbeat =
    El.el
        [ El.centerX ]
    <|
        Page.button
            { label = "Heartbeat On"
            , example = exampleFunc On
            , onPress = GotButtonClick
            , enabled = not heartbeat
            }


heartbeatOffButton : (Action -> Example) -> Bool -> Element Msg
heartbeatOffButton exampleFunc heartbeat =
    El.el
        [ El.centerX ]
    <|
        Page.button
            { label = "Heartbeat Off"
            , example = exampleFunc Off
            , onPress = GotButtonClick
            , enabled = heartbeat
            }


joinButton : (Action -> Example) -> (Example -> Msg) -> Bool -> Element Msg
joinButton example onPress enabled =
    El.el
        [ El.alignRight ]
    <|
        Page.button
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
        Page.button
            { label = "Leave Channel"
            , example = example Leave
            , onPress = onPress
            , enabled = enabled
            }


presenceOnButton : (Action -> Example) -> Bool -> Element Msg
presenceOnButton exampleFunc presence =
    El.el
        [ El.centerX ]
    <|
        Page.button
            { label = "Presence On"
            , example = exampleFunc On
            , onPress = GotButtonClick
            , enabled = not presence
            }


presenceOffButton : (Action -> Example) -> Bool -> Element Msg
presenceOffButton exampleFunc presence =
    El.el
        [ El.centerX ]
    <|
        Page.button
            { label = "Presence Off"
            , example = exampleFunc Off
            , onPress = GotButtonClick
            , enabled = presence
            }


sendMessageButton : (Action -> Example) -> Element Msg
sendMessageButton exampleFunc =
    El.el
        [ El.alignRight ]
    <|
        Page.button
            { label = "Push Message"
            , example = exampleFunc Send
            , onPress = GotButtonClick
            , enabled = True
            }


channelMessagesOn : (Action -> Example) -> Bool -> Element Msg
channelMessagesOn exampleFunc channelMessages =
    El.el
        [ El.centerX ]
    <|
        Page.button
            { label = "Messages On"
            , example = exampleFunc On
            , onPress = GotButtonClick
            , enabled = not channelMessages
            }


channelMessagesOff : (Action -> Example) -> Bool -> Element Msg
channelMessagesOff exampleFunc channelMessages =
    El.el
        [ El.alignLeft ]
    <|
        Page.button
            { label = "Messages Off"
            , example = exampleFunc Off
            , onPress = GotButtonClick
            , enabled = channelMessages
            }


info : Model -> List (Element Msg)
info model =
    case model.example of
        ManageSocketHeartbeat _ ->
            [ El.el
                [ El.paddingXY 0 10 ]
                (El.text ("Heartbeat Count: " ++ String.fromInt model.heartbeatCount))
            ]

        ManageChannelMessages _ ->
            El.el
                [ El.paddingXY 0 10
                ]
                (El.paragraph
                    []
                    [ El.el [ Font.color Color.darkslateblue ] (El.text "Message Count: ")
                    , El.text (String.fromInt model.channelMessageCount)
                    ]
                )
                :: List.map formatChannelMessages model.channelMessageList

        ManagePresenceMessages _ ->
            [ El.el
                [ El.paddingXY 0 10 ]
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
            , ( "Phoenix.connectionState", Phoenix.connectionState phoenix )
            , ( "Phoenix.isConnected", Phoenix.isConnected phoenix |> String.fromBool )
            ]

        ManageChannelMessages _ ->
            [ ( "Phoenix.socketState", Phoenix.socketStateToString phoenix )
            , ( "Phoenix.connectionState", Phoenix.connectionState phoenix )
            , ( "Phoenix.isConnected", Phoenix.isConnected phoenix |> String.fromBool )
            , ( "Phoenix.channelJoined", Phoenix.channelJoined "example:manage_channel_messages" phoenix |> String.fromBool )
            , ( "Phoenix.joinedChannels"
              , Phoenix.joinedChannels phoenix
                    |> List.foldl
                        (\channel str ->
                            str ++ ", " ++ channel
                        )
                        ""
                    |> String.dropLeft 2
              )
            ]

        ManagePresenceMessages _ ->
            [ ( "Phoenix.socketState", Phoenix.socketStateToString phoenix )
            , ( "Phoenix.connectionState", Phoenix.connectionState phoenix )
            , ( "Phoenix.isConnected", Phoenix.isConnected phoenix |> String.fromBool )
            , ( "Phoenix.channelJoined", Phoenix.channelJoined "example:manage_presence_messages" phoenix |> String.fromBool )
            , ( "Phoenix.joinedChannels"
              , Phoenix.joinedChannels phoenix
                    |> List.filter (String.startsWith "example:")
                    |> List.foldl
                        (\channel str ->
                            str ++ ", " ++ channel
                        )
                        ""
                    |> String.dropLeft 2
                    |> String.listAsString
              )
            , ( "Phoenix.lastPresenceJoin"
              , case Phoenix.lastPresenceJoin "example:manage_presence_messages" phoenix of
                    Nothing ->
                        "Nothing"

                    Just presence ->
                        "Just presence"
              )
            , ( "Phoenix.lastPresenceLeave"
              , case Phoenix.lastPresenceLeave "example:manage_presence_messages" phoenix of
                    Nothing ->
                        "Nothing"

                    Just presence ->
                        "Just presence"
              )
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
