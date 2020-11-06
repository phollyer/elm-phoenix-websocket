module Example.ConnectWithBadParams exposing
    ( Model
    , Msg
    , init
    , subscriptions
    , update
    , view
    )

import Element as El exposing (Device, Element)
import Extra.String as String
import Json.Encode as JE
import Phoenix
import UI
import View.ApplicableFunctions as ApplicableFunctions
import View.Button as Button
import View.Example as Example
import View.ExampleControls as ExampleControls
import View.Feedback as Feedback
import View.FeedbackPanel as FeedbackPanel
import View.UsefulFunctions as UsefulFunctions



{- Init -}


init : Device -> Phoenix.Model -> Model
init device phoenix =
    { device = device
    , phoenix = phoenix
    }



{- Model -}


type alias Model =
    { device : Device
    , phoenix : Phoenix.Model
    }


type Action
    = Connect
    | Disconnect



{- Update -}


type Msg
    = GotControlClick Action
    | GotPhoenixMsg Phoenix.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotControlClick action ->
            case action of
                Connect ->
                    model.phoenix
                        |> Phoenix.setConnectParams
                            (JE.object
                                [ ( "good_params", JE.bool False ) ]
                            )
                        |> Phoenix.connect
                        |> updatePhoenix model

                Disconnect ->
                    model.phoenix
                        |> Phoenix.disconnect Nothing
                        |> updatePhoenix model

        GotPhoenixMsg subMsg ->
            Phoenix.update subMsg model.phoenix
                |> updatePhoenix model


updatePhoenix : Model -> ( Phoenix.Model, Cmd Phoenix.Msg ) -> ( Model, Cmd Msg )
updatePhoenix model ( phoenix, phoenixMsg ) =
    ( { model | phoenix = phoenix }
    , Cmd.map GotPhoenixMsg phoenixMsg
    )



{- Subscriptions -}


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.map GotPhoenixMsg <|
        Phoenix.subscriptions model.phoenix



{- View -}


view : Model -> Element Msg
view model =
    Example.init
        |> Example.description description
        |> Example.controls (controls model)
        |> Example.feedback (feedback model)
        |> Example.view model.device



{- Description -}


description : List (Element msg)
description =
    [ UI.paragraph
        [ El.text "Try to connect to the Socket with authentication params that are not accepted, causing the connection to be denied." ]
    ]



{- Controls -}


controls : Model -> Element Msg
controls { device, phoenix } =
    ExampleControls.init
        |> ExampleControls.elements
            [ connect device phoenix
            , disconnect device phoenix
            ]
        |> ExampleControls.view device


connect : Device -> Phoenix.Model -> Element Msg
connect device phoenix =
    Button.init
        |> Button.label "Connect"
        |> Button.onPress (Just (GotControlClick Connect))
        |> Button.enabled
            (case Phoenix.socketState phoenix of
                Phoenix.Disconnected _ ->
                    True

                _ ->
                    False
            )
        |> Button.view device


disconnect : Device -> Phoenix.Model -> Element Msg
disconnect device phoenix =
    Button.init
        |> Button.label "Disconnect"
        |> Button.onPress (Just (GotControlClick Disconnect))
        |> Button.enabled (Phoenix.socketState phoenix == Phoenix.Connected)
        |> Button.view device



{- Feedback -}


feedback : Model -> Element Msg
feedback { device, phoenix } =
    Feedback.init
        |> Feedback.elements
            [ FeedbackPanel.init
                |> FeedbackPanel.title "Applicable Functions"
                |> FeedbackPanel.scrollable [ applicableFunctions device ]
                |> FeedbackPanel.view device
            , FeedbackPanel.init
                |> FeedbackPanel.title "Useful Functions"
                |> FeedbackPanel.scrollable [ usefulFunctions device phoenix ]
                |> FeedbackPanel.view device
            ]
        |> Feedback.view device


applicableFunctions : Device -> Element Msg
applicableFunctions device =
    ApplicableFunctions.init
        |> ApplicableFunctions.functions
            [ "Phoenix.setConnectParams"
            , "Phoenix.connect"
            , "Phoenix.disconnect"
            ]
        |> ApplicableFunctions.view device


usefulFunctions : Device -> Phoenix.Model -> Element Msg
usefulFunctions device phoenix =
    UsefulFunctions.init
        |> UsefulFunctions.functions
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
        |> UsefulFunctions.view device
