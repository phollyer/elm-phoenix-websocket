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
import Session exposing (Session)



{- Init -}


init : Session -> ( Model, Cmd Msg )
init session =
    ( { session = session
      , example = ManageSocketHeartbeat Connect
      , heartbeatCount = 0
      }
    , Cmd.none
    )



{- Model -}


type alias Model =
    { session : Session
    , example : Example
    , heartbeatCount : Int
    }



{- Update -}


type Msg
    = GotButtonClick Example
    | GotButtonEnter Example
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
                            Phoenix.connect phoenix
                                |> updatePhoenix model

                        Disconnect ->
                            Phoenix.disconnect phoenix
                                |> updatePhoenix model

                        _ ->
                            ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        GotButtonEnter example ->
            ( { model
                | example = example
              }
            , Cmd.none
            )

        GotMenuItem example ->
            Phoenix.disconnect phoenix
                |> updatePhoenix model
                |> updateExample example

        GotPhoenixMsg subMsg ->
            Phoenix.update subMsg phoenix
                |> updatePhoenix model


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
                ]
                (Example.toString model.example)
            , Example.init
                |> Example.description
                    (description model.example)
                |> Example.controls
                    (controls model.example phoenix)
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
                [ El.text "Choose whether to receive the heartbeat as a Socket message." ]
            ]

        _ ->
            []


controls : Example -> Phoenix.Model -> Element Msg
controls example phoenix =
    case example of
        ManageSocketHeartbeat _ ->
            buttons ManageSocketHeartbeat phoenix

        _ ->
            El.none


buttons : (Action -> Example) -> Phoenix.Model -> Element Msg
buttons example phoenix =
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
        , onEnter = GotButtonEnter
        , enabled =
            case Phoenix.socketState phoenix of
                Phoenix.Disconnected _ ->
                    True

                _ ->
                    False
        }


disconnectButton : (Action -> Example) -> Phoenix.Model -> Element Msg
disconnectButton exampleFunc phoenix =
    Page.button
        { label = "Disconnect"
        , example = exampleFunc Disconnect
        , onPress = GotButtonClick
        , onEnter = GotButtonEnter
        , enabled = Phoenix.socketState phoenix == Phoenix.Connected
        }


applicableFunctions : Example -> List String
applicableFunctions example =
    case example of
        ManageSocketHeartbeat _ ->
            [ "Phoenix.heartbeatMessagesOn"
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
