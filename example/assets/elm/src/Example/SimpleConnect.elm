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
import Phoenix
import View.Button as Button
import View.Example as Example
import View.Example.ApplicableFunctions as ApplicableFunctions
import View.Example.Controls as Controls
import View.Example.Feedback as Feedback
import View.Example.Feedback.Content as FeedbackContent
import View.Example.Feedback.Panel as FeedbackPanel
import View.Example.UsefulFunctions as UsefulFunctions
import View.Group as Group



{- Init -}


init : Phoenix.Model -> Model
init phoenix =
    { phoenix = phoenix
    , responses = []
    }



{- Model -}


type alias Model =
    { phoenix : Phoenix.Model
    , responses : List Phoenix.SocketState
    }


type Action
    = Connect
    | Disconnect



{- Update -}


type Msg
    = GotControlClick Action
    | PhoenixMsg Phoenix.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotControlClick action ->
            case action of
                Connect ->
                    Phoenix.connect model.phoenix
                        |> updatePhoenixWith PhoenixMsg model

                Disconnect ->
                    Phoenix.disconnect Nothing model.phoenix
                        |> updatePhoenixWith PhoenixMsg model

        PhoenixMsg subMsg ->
            let
                ( newModel, cmd, phoenixMsg ) =
                    Phoenix.update subMsg model.phoenix
                        |> Phoenix.updateWith PhoenixMsg model
            in
            case phoenixMsg of
                Phoenix.SocketMessage (Phoenix.StateChange state) ->
                    ( { newModel | responses = state :: model.responses }, cmd )

                _ ->
                    ( newModel, cmd )



{- Subscriptions -}


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.map PhoenixMsg <|
        Phoenix.subscriptions model.phoenix



{- View -}


view : Device -> Model -> Element Msg
view device model =
    Example.init
        |> Example.description description
        |> Example.controls (controls device model)
        |> Example.feedback (feedback device model)
        |> Example.view device



{- Description -}


description : List (List (Element msg))
description =
    [ [ El.text "A simple connection to the Socket without sending any params or setting any connect options." ] ]



{- Controls -}


controls : Device -> Model -> Element Msg
controls device { phoenix } =
    Controls.init
        |> Controls.elements
            [ connect device phoenix
            , disconnect device phoenix
            ]
        |> Controls.group
            (Group.init
                |> Group.layouts
                    [ ( Phone, Portrait, [ 2 ] ) ]
            )
        |> Controls.view device


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


feedback : Device -> Model -> Element Msg
feedback device { phoenix, responses } =
    Feedback.init
        |> Feedback.elements
            [ FeedbackPanel.init
                |> FeedbackPanel.title "Info"
                |> FeedbackPanel.scrollable (info device responses)
                |> FeedbackPanel.view device
            , FeedbackPanel.init
                |> FeedbackPanel.title "Applicable Functions"
                |> FeedbackPanel.scrollable [ applicableFunctions device ]
                |> FeedbackPanel.view device
            , FeedbackPanel.init
                |> FeedbackPanel.title "Useful Functions"
                |> FeedbackPanel.scrollable [ usefulFunctions device phoenix ]
                |> FeedbackPanel.view device
            ]
        |> Feedback.view device


info : Device -> List Phoenix.SocketState -> List (Element Msg)
info device stateList =
    List.map
        (\state ->
            FeedbackContent.init
                |> FeedbackContent.title (Just "SocketMessage")
                |> FeedbackContent.label "StateChange"
                |> FeedbackContent.element (El.text (socketStateToString state))
                |> FeedbackContent.view device
        )
        stateList


socketStateToString : Phoenix.SocketState -> String
socketStateToString state =
    case state of
        Phoenix.Connecting ->
            "Connecting"

        Phoenix.Connected ->
            "Connected"

        Phoenix.Disconnecting ->
            "Disconnecting"

        Phoenix.Disconnected _ ->
            "Disconnected"


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
