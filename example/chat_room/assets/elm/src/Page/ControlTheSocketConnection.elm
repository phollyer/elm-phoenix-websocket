module Page.ControlTheSocketConnection exposing
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
import Html exposing (Html)
import Json.Encode as JE
import Phoenix
import Route
import Session exposing (Session)
import View.Example as Example
import View.Layout as Layout
import View.Menu as Menu



{- Init -}


init : Session -> ( Model, Cmd Msg )
init session =
    ( { session = session
      , example = SimpleConnect Connect
      }
    , Cmd.none
    )



{- Model -}


type alias Model =
    { session : Session
    , example : Example
    }



{- Update -}


type Msg
    = GotButtonClick Example
    | GotHomeBtnClick
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

        GotPhoenixMsg subMsg ->
            Phoenix.update subMsg phoenix
                |> updatePhoenix model

        GotMenuItem example ->
            Phoenix.disconnect Nothing phoenix
                |> updatePhoenix model
                |> updateExample example

        GotButtonClick example ->
            case example of
                SimpleConnect action ->
                    case action of
                        Connect ->
                            Phoenix.connect phoenix
                                |> updatePhoenix model

                        Disconnect ->
                            Phoenix.disconnect (Just 1000) phoenix
                                |> updatePhoenix model

                        _ ->
                            ( model, Cmd.none )

                ConnectWithGoodParams action ->
                    case action of
                        Connect ->
                            phoenix
                                |> Phoenix.setConnectParams
                                    (JE.object
                                        [ ( "good_params", JE.bool True ) ]
                                    )
                                |> Phoenix.connect
                                |> updatePhoenix model

                        Disconnect ->
                            Phoenix.disconnect (Just 1000) phoenix
                                |> updatePhoenix model

                        _ ->
                            ( model, Cmd.none )

                ConnectWithBadParams action ->
                    case action of
                        Connect ->
                            phoenix
                                |> Phoenix.setConnectParams
                                    (JE.object
                                        [ ( "good_params", JE.bool False ) ]
                                    )
                                |> Phoenix.connect
                                |> updatePhoenix model

                        Disconnect ->
                            Phoenix.disconnect (Just 1000) phoenix
                                |> updatePhoenix model

                        _ ->
                            ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )


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
    , Cmd.batch
        [ Cmd.map GotPhoenixMsg phoenixCmd
        , Cmd.map GotPhoenixMsg (Phoenix.heartbeatMessagesOff phoenix)
        ]
    )



{- View -}


view : Model -> { title : String, content : Html Msg }
view model =
    let
        phoenix =
            Session.phoenix model.session
    in
    { title = "Control The Socket Connection"
    , content =
        Layout.init
            |> Layout.backButton homeButton
            |> Layout.title "Control The Socket Connection"
            |> Layout.introduction
                [ Layout.paragraph Layout.Example
                    [ El.text "Connecting to the Socket is taken care of automatically when a request to join a Channel is made, or when a Channel is pushed to, "
                    , El.text "however, if you want to take manual control, here's a few examples."
                    ]
                , Layout.paragraph Layout.Example
                    [ El.text "Clicking on a function will take you to its documentation." ]
                ]
            |> Layout.menu
                (Menu.init
                    |> Menu.options
                        [ ( Example.toString (SimpleConnect Anything), GotMenuItem (SimpleConnect Anything) )
                        , ( Example.toString (ConnectWithGoodParams Anything), GotMenuItem (ConnectWithGoodParams Anything) )
                        , ( Example.toString (ConnectWithBadParams Anything), GotMenuItem (ConnectWithBadParams Anything) )
                        ]
                    |> Menu.selected
                        (Example.toString model.example)
                    |> Menu.render Menu.Default
                )
            |> Layout.example
                (Example.init
                    |> Example.description
                        (description model.example)
                    |> Example.controls
                        (controls model.example phoenix)
                    |> Example.applicableFunctions
                        (applicableFunctions model.example)
                    |> Example.usefulFunctions
                        (usefulFunctions model.example phoenix)
                    |> Example.render Example.Default
                )
            |> Layout.render Layout.Example
    }


description : Example -> List (Element msg)
description example =
    case example of
        SimpleConnect _ ->
            [ Layout.paragraph Layout.Example
                [ El.text "A simple connection to the Socket without sending any params or setting any connect options." ]
            ]

        ConnectWithGoodParams _ ->
            [ Layout.paragraph Layout.Example
                [ El.text "Connect to the Socket with authentication params that are accepted." ]
            ]

        ConnectWithBadParams _ ->
            [ Layout.paragraph Layout.Example
                [ El.text "Try to connect to the Socket with authentication params that are not accepted, causing the connection to be denied." ]
            ]

        _ ->
            []


controls : Example -> Phoenix.Model -> Element Msg
controls example phoenix =
    case example of
        SimpleConnect _ ->
            buttons
                [ connectButton SimpleConnect phoenix
                , disconnectButton SimpleConnect phoenix
                ]

        ConnectWithGoodParams _ ->
            buttons
                [ connectButton ConnectWithGoodParams phoenix
                , disconnectButton ConnectWithGoodParams phoenix
                ]

        ConnectWithBadParams _ ->
            buttons
                [ connectButton ConnectWithBadParams phoenix
                , disconnectButton ConnectWithBadParams phoenix
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
            (El.el
                [ El.width El.fill
                , El.centerY
                ]
            )
            btns


homeButton : Element Msg
homeButton =
    Input.button
        [ El.mouseOver <|
            [ Font.color Color.aliceblue
            ]
        , Font.color Color.darkslateblue
        , Font.size 20
        ]
        { label = El.text "Home"
        , onPress = Just GotHomeBtnClick
        }


connectButton : (Action -> Example) -> Phoenix.Model -> Element Msg
connectButton exampleFunc phoenix =
    El.el
        [ El.alignRight ]
    <|
        Layout.button Layout.Example
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
        Layout.button Layout.Example
            { label = "Disconnect"
            , example = exampleFunc Disconnect
            , onPress = GotButtonClick
            , enabled = Phoenix.socketState phoenix == Phoenix.Connected
            }


applicableFunctions : Example -> List String
applicableFunctions example =
    case example of
        SimpleConnect _ ->
            [ "Phoenix.connect"
            , "Phoenix.disconnect"
            ]

        ConnectWithGoodParams _ ->
            [ "Phoenix.setConnectParams"
            , "Phoenix.connect"
            , "Phoenix.disconnect"
            ]

        ConnectWithBadParams _ ->
            [ "Phoenix.setConnectParams"
            , "Phoenix.connect"
            , "Phoenix.disconnect"
            ]

        _ ->
            []


usefulFunctions : Example -> Phoenix.Model -> List ( String, String )
usefulFunctions example phoenix =
    case example of
        SimpleConnect _ ->
            [ ( "Phoenix.socketState", Phoenix.socketStateToString phoenix )
            , ( "Phoenix.connectionState", Phoenix.connectionState phoenix |> String.printQuoted )
            , ( "Phoenix.isConnected", Phoenix.isConnected phoenix |> String.printBool )
            ]

        ConnectWithGoodParams _ ->
            [ ( "Phoenix.socketState", Phoenix.socketStateToString phoenix )
            , ( "Phoenix.connectionState", Phoenix.connectionState phoenix |> String.printQuoted )
            , ( "Phoenix.isConnected", Phoenix.isConnected phoenix |> String.printBool )
            ]

        ConnectWithBadParams _ ->
            [ ( "Phoenix.disconnectReason"
              , case Phoenix.disconnectReason phoenix of
                    Nothing ->
                        "Nothing"

                    Just reason ->
                        "Just " ++ String.printQuoted reason
              )
            , ( "Phoenix.socketState", Phoenix.socketStateToString phoenix )
            , ( "Phoenix.connectionState", Phoenix.connectionState phoenix |> String.printQuoted )
            , ( "Phoenix.isConnected", Phoenix.isConnected phoenix |> String.printBool )
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
