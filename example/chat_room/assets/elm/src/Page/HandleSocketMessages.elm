module Page.HandleSocketMessages exposing
    ( Model
    , Msg
    , init
    , subscriptions
    , toSession
    , update
    , view
    )

import Element as El exposing (Element)
import Element.Font as Font
import Element.Input as Input
import Example exposing (Action(..), Example(..))
import Extra.String as String
import Json.Encode as JE
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
      }
    , Cmd.none
    )



{- Model -}


type alias Model =
    { session : Session
    , example : Example
    , heartbeatCount : Int
    , heartbeat : Bool
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

                _ ->
                    ( newModel, cmd )


setHeartbeat : Bool -> Model -> Cmd Phoenix.Msg -> ( Model, Cmd Msg )
setHeartbeat heartbeat model phxCmd =
    ( { model
        | heartbeat = heartbeat
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
                    [ El.text ""
                    ]
                , Page.paragraph
                    [ El.text "Clicking on a function will take you to its documentation." ]
                ]
            , Page.menu
                [ ( Example.toString (ManageSocketHeartbeat Anything), GotMenuItem (ManageSocketHeartbeat Anything) )
                , ( Example.toString (ManageChannelMessages Anything), GotMenuItem (ManageChannelMessages Anything) )
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
                [ El.text "Messages that arrive from a Channel are delivered as both a Channel message and a Socket message from PhoenixJS, and it is up to "
                , El.text "the developer to decide how to handle them."
                ]
            ]

        _ ->
            []


controls : Model -> Phoenix.Model -> Element Msg
controls { example, heartbeat } phoenix =
    case example of
        ManageSocketHeartbeat _ ->
            buttons ManageSocketHeartbeat heartbeat phoenix

        _ ->
            El.none


buttons : (Action -> Example) -> Bool -> Phoenix.Model -> Element Msg
buttons example heartbeat phoenix =
    El.row
        [ El.width El.fill
        , El.height <| El.px 60
        , El.spacing 20
        ]
        [ El.el
            [ El.width El.fill
            , El.centerY
            ]
            (El.el
                [ El.alignRight ]
                (connectButton example phoenix)
            )
        , El.el
            [ El.width El.fill
            , El.centerY
            ]
            (El.el
                [ El.centerX ]
                (heartbeatOnButton example heartbeat)
            )
        , El.el
            [ El.width El.fill
            , El.centerY
            ]
            (El.el
                [ El.centerX ]
                (heartbeatOffButton example heartbeat)
            )
        , El.el
            [ El.width El.fill
            , El.centerY
            ]
            (El.el
                [ El.alignLeft ]
                (disconnectButton example phoenix)
            )
        ]


connectButton : (Action -> Example) -> Phoenix.Model -> Element Msg
connectButton exampleFunc phoenix =
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


heartbeatOnButton : (Action -> Example) -> Bool -> Element Msg
heartbeatOnButton exampleFunc heartbeat =
    Page.button
        { label = "Heartbeat On"
        , example = exampleFunc On
        , onPress = GotButtonClick
        , enabled = not heartbeat
        }


heartbeatOffButton : (Action -> Example) -> Bool -> Element Msg
heartbeatOffButton exampleFunc heartbeat =
    Page.button
        { label = "Heartbeat Off"
        , example = exampleFunc Off
        , onPress = GotButtonClick
        , enabled = heartbeat
        }


disconnectButton : (Action -> Example) -> Phoenix.Model -> Element Msg
disconnectButton exampleFunc phoenix =
    Page.button
        { label = "Disconnect"
        , example = exampleFunc Disconnect
        , onPress = GotButtonClick
        , enabled = Phoenix.socketState phoenix == Phoenix.Connected
        }


info : Model -> List (Element Msg)
info model =
    case model.example of
        ManageSocketHeartbeat _ ->
            [ El.text ("Heartbeat Count: " ++ String.fromInt model.heartbeatCount) ]

        _ ->
            [ El.none ]


applicableFunctions : Example -> List String
applicableFunctions example =
    case example of
        ManageSocketHeartbeat _ ->
            [ "Phoenix.setConnectOptions"
            , "Phoenix.heartbeatMessagesOn"
            , "Phoenix.heartbeatMessagesOff"
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
