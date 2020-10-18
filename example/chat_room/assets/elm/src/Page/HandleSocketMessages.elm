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
import Element.Font as Font
import Element.Input as Input
import Example exposing (Action(..), Example(..))
import Extra.String as String
import Json.Encode as JE exposing (Value)
import Page
import Phoenix
import Phoenix.Socket as Socket
import Session exposing (Session)



{- Init -}


init : Session -> ( Model, Cmd Msg )
init session =
    ( { session = session
      , example = ManageSocketHeartbeat Connect
      , heartbeatCount = 0
      , heartbeat = True
      , channelMessages = True
      , channelMessageCount = 0
      , channelMessageList = []
      , presenceMessages = True
      }
    , Cmd.none
    )


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


type alias Model =
    { session : Session
    , example : Example
    , heartbeatCount : Int
    , heartbeat : Bool
    , channelMessages : Bool
    , channelMessageCount : Int
    , channelMessageList : List ChannelMsg
    , presenceMessages : Bool
    }


type alias ChannelMsg =
    { topic : Phoenix.Topic
    , event : Phoenix.Event
    , payload : Value
    , joinRef : Maybe String
    , ref : Maybe String
    }



{- Update -}


type Msg
    = GotButtonClick Example
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
                            updatePhoenix model <|
                                Phoenix.join
                                    "example:manage_presence_messages"
                                    phoenix

                        Leave ->
                            updatePhoenix model <|
                                Phoenix.leave
                                    "example:manage_presence_messages"
                                    phoenix

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

        GotMenuItem example ->
            Phoenix.disconnect phoenix
                |> updatePhoenix model
                |> updateExample example

        GotPhoenixMsg subMsg ->
            let
                ( newModel, cmd ) =
                    Phoenix.update subMsg phoenix
                        |> updatePhoenix model
            in
            case Session.phoenix newModel.session |> Phoenix.phoenixMsg of
                Phoenix.SocketMessage (Phoenix.Heartbeat _) ->
                    ( { newModel
                        | heartbeatCount =
                            newModel.heartbeatCount + 1
                      }
                    , cmd
                    )

                Phoenix.SocketMessage (Phoenix.ChannelMessage msgInfo) ->
                    ( { model
                        | channelMessageCount =
                            model.channelMessageCount + 1
                        , channelMessageList =
                            msgInfo :: model.channelMessageList
                      }
                    , cmd
                    )

                _ ->
                    ( newModel, cmd )


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
                |> Example.description
                    (description model.example)
                |> Example.controls
                    (controls model phoenix)
                |> Example.info
                    (info model)
                |> Example.applicableFunctions
                    (applicableFunctions model.example)
                |> Example.usefulFunctions
                    (usefulFunctions model.example phoenix)
                |> Example.view
            ]
    }


description : Example -> List (Element msg)
description example =
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
                [ joinButton ManagePresenceMessages phoenix
                , presenceOnButton ManagePresenceMessages presenceMessages
                , presenceOffButton ManagePresenceMessages presenceMessages
                , leaveButton ManagePresenceMessages phoenix
                ]

        _ ->
            El.none


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


joinButton : (Action -> Example) -> Phoenix.Model -> Element Msg
joinButton exampleFunc phoenix =
    El.el
        [ El.alignRight ]
    <|
        Page.button
            { label = "Join Channel"
            , example = exampleFunc Join
            , onPress = GotButtonClick
            , enabled = not <| Phoenix.channelJoined "example:manage_presence_messages" phoenix
            }


leaveButton : (Action -> Example) -> Phoenix.Model -> Element Msg
leaveButton exampleFunc phoenix =
    El.el
        [ El.alignLeft ]
    <|
        Page.button
            { label = "Leave Channel"
            , example = exampleFunc Leave
            , onPress = GotButtonClick
            , enabled = Phoenix.channelJoined "example:manage_presence_messages" phoenix
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
