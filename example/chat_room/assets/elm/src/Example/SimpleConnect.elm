module Example.SimpleConnect exposing
    ( Model
    , Msg
    , init
    , subscriptions
    , update
    , view
    )

import Element as El exposing (Device, DeviceClass(..), Element, Orientation(..))
import Example.Utils exposing (updatePhoenixWith)
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
import View.Group as Group
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
                    Phoenix.connect model.phoenix
                        |> updatePhoenixWith GotPhoenixMsg model

                Disconnect ->
                    Phoenix.disconnect Nothing model.phoenix
                        |> updatePhoenixWith GotPhoenixMsg model

        GotPhoenixMsg subMsg ->
            Phoenix.update subMsg model.phoenix
                |> updatePhoenixWith GotPhoenixMsg model



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
        [ El.text "A simple connection to the Socket without sending any params or setting any connect options." ]
    ]



{- Controls -}


controls : Model -> Element Msg
controls { device, phoenix } =
    ExampleControls.init
        |> ExampleControls.elements
            [ connect device phoenix
            , disconnect device phoenix
            ]
        |> ExampleControls.group
            (Group.init
                |> Group.layouts
                    [ ( Phone, Portrait, [ 2 ] ) ]
            )
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
            [ "Phoenix.connect"
            , "Phoenix.disconnect"
            ]
        |> ApplicableFunctions.view device


usefulFunctions : Device -> Phoenix.Model -> Element Msg
usefulFunctions device phoenix =
    UsefulFunctions.init
        |> UsefulFunctions.functions
            [ ( "Phoenix.socketState", Phoenix.socketStateToString phoenix )
            , ( "Phoenix.connectionState", Phoenix.connectionState phoenix |> String.printQuoted )
            , ( "Phoenix.isConnected", Phoenix.isConnected phoenix |> String.printBool )
            ]
        |> UsefulFunctions.view device
