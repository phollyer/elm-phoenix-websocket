module Page.ControlTheSocketConnection exposing
    ( Model
    , Msg
    , init
    , subscriptions
    , toSession
    , update
    , updateSession
    , view
    )

import Element as El exposing (Device, DeviceClass(..), Element, Orientation(..))
import Example exposing (Action(..), Example(..))
import Extra.String as String
import Json.Encode as JE
import Phoenix
import Route
import Session exposing (Session)
import View.ApplicableFunctions as ApplicableFunctions
import View.Control as Control
import View.Controls as Controls
import View.Example as Example
import View.Feedback as Feedback
import View.Group as Group
import View.Layout as Layout
import View.Menu as Menu
import View.UsefulFunctions as UsefulFunctions
import View.Utils as Utils



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
    = GotControlClick Example
    | GotHomeBtnClick
    | GotMenuItem (Action -> Example)
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

        GotControlClick example ->
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


updateExample : (Action -> Example) -> ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
updateExample example ( model, cmd ) =
    ( { model
        | example = example Anything
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



{- Subscriptions -}


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.map GotPhoenixMsg <|
        Phoenix.subscriptions (Session.phoenix model.session)



{- Session -}


toSession : Model -> Session
toSession model =
    model.session


updateSession : Session -> Model -> Model
updateSession session model =
    { model | session = session }



{- Device -}


toDevice : Model -> Device
toDevice model =
    Session.device model.session



{- View -}


view : Model -> { title : String, content : Element Msg }
view model =
    let
        phoenix =
            Session.phoenix model.session

        device =
            toDevice model
    in
    { title = "Control The Socket Connection"
    , content =
        Layout.init
            |> Layout.homeMsg (Just GotHomeBtnClick)
            |> Layout.title "Control The Socket Connection"
            |> Layout.body
                (Example.init
                    |> Example.introduction introduction
                    |> Example.menu (menu device model)
                    |> Example.description (description model)
                    |> Example.controls (controls device phoenix model)
                    |> Example.feedback (feedback device phoenix model)
                    |> Example.view device
                )
            |> Layout.view device
    }


{-| Introduction
-}
introduction : List (Element msg)
introduction =
    [ Utils.paragraph
        [ El.text "Connecting to the Socket is taken care of automatically when a request to join a Channel is made, or when a Channel is pushed to, "
        , El.text "however, if you want to take manual control, here's a few examples."
        ]
    , Utils.paragraph
        [ El.text "Clicking on a function will take you to its documentation." ]
    ]


{-| Examples Menu
-}
menu : Device -> Model -> Element Msg
menu device { example } =
    Menu.init
        |> Menu.options
            [ ( Example.toString SimpleConnect, GotMenuItem SimpleConnect )
            , ( Example.toString ConnectWithGoodParams, GotMenuItem ConnectWithGoodParams )
            , ( Example.toString ConnectWithBadParams, GotMenuItem ConnectWithBadParams )
            ]
        |> Menu.selected (Example.toString <| Example.toFunc example)
        |> Menu.group
            (Group.init
                |> Group.layouts [ ( Phone, Landscape, [ 1, 2 ] ) ]
            )
        |> Menu.view device


{-| Example Description
-}
description : Model -> List (Element msg)
description { example } =
    case example of
        SimpleConnect _ ->
            [ Utils.paragraph
                [ El.text "A simple connection to the Socket without sending any params or setting any connect options." ]
            ]

        ConnectWithGoodParams _ ->
            [ Utils.paragraph
                [ El.text "Connect to the Socket with authentication params that are accepted." ]
            ]

        ConnectWithBadParams _ ->
            [ Utils.paragraph
                [ El.text "Try to connect to the Socket with authentication params that are not accepted, causing the connection to be denied." ]
            ]

        _ ->
            []


{-| Example Controls
-}
controls : Device -> Phoenix.Model -> Model -> Element Msg
controls device phoenix model =
    Controls.init
        |> Controls.elements (buttons device phoenix model)
        |> Controls.view device


buttons : Device -> Phoenix.Model -> Model -> List (Element Msg)
buttons device phoenix { example } =
    case example of
        SimpleConnect _ ->
            [ connect SimpleConnect device phoenix
            , disconnect SimpleConnect device phoenix
            ]

        ConnectWithGoodParams _ ->
            [ connect ConnectWithGoodParams device phoenix
            , disconnect ConnectWithGoodParams device phoenix
            ]

        ConnectWithBadParams _ ->
            [ connect ConnectWithBadParams device phoenix
            , disconnect ConnectWithBadParams device phoenix
            ]

        _ ->
            []


connect : (Action -> Example) -> Device -> Phoenix.Model -> Element Msg
connect example device phoenix =
    Control.init
        |> Control.label "Connect"
        |> Control.onPress (Just (GotControlClick (example Connect)))
        |> Control.enabled
            (case Phoenix.socketState phoenix of
                Phoenix.Disconnected _ ->
                    True

                _ ->
                    False
            )
        |> Control.view device


disconnect : (Action -> Example) -> Device -> Phoenix.Model -> Element Msg
disconnect example device phoenix =
    Control.init
        |> Control.label "Disconnect"
        |> Control.onPress (Just (GotControlClick (example Disconnect)))
        |> Control.enabled (Phoenix.socketState phoenix == Phoenix.Connected)
        |> Control.view device


{-| Example Feedback and Info
-}
feedback : Device -> Phoenix.Model -> Model -> Element Msg
feedback device phoenix { example } =
    Feedback.init
        |> Feedback.elements
            [ ApplicableFunctions.init
                |> ApplicableFunctions.functions (applicableFunctions example)
                |> ApplicableFunctions.view device
            , UsefulFunctions.init
                |> UsefulFunctions.functions (usefulFunctions phoenix example)
                |> UsefulFunctions.view device
            ]
        |> Feedback.view device


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


usefulFunctions : Phoenix.Model -> Example -> List ( String, String )
usefulFunctions phoenix example =
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
