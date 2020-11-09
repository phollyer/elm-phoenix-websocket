module Example.ConnectWithBadParams exposing
    ( Model
    , Msg
    , init
    , subscriptions
    , update
    , view
    )

import Element as El exposing (Device, Element)
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
import View.FeedbackContent as FeedbackContent
import View.FeedbackPanel as FeedbackPanel
import View.UsefulFunctions as UsefulFunctions



{- Init -}


init : Phoenix.Model -> Model
init phoenix =
    { phoenix = phoenix
    , errors = []
    }



{- Model -}


type alias Model =
    { phoenix : Phoenix.Model
    , errors : List String
    }


type Action
    = Connect



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
                        |> updatePhoenixWith GotPhoenixMsg model

        GotPhoenixMsg subMsg ->
            let
                ( newModel, cmd ) =
                    Phoenix.update subMsg model.phoenix
                        |> updatePhoenixWith GotPhoenixMsg model
            in
            case Phoenix.phoenixMsg newModel.phoenix of
                Phoenix.Error (Phoenix.Socket error) ->
                    ( { newModel | errors = error :: newModel.errors }
                    , cmd
                    )

                _ ->
                    ( newModel, cmd )



{- Subscriptions -}


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.map GotPhoenixMsg <|
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
    [ [ El.text "Try to connect to the Socket with authentication params that are not accepted, causing the connection to be denied." ]
    ]



{- Controls -}


controls : Device -> Model -> Element Msg
controls device { phoenix } =
    ExampleControls.init
        |> ExampleControls.elements
            [ connect device phoenix ]
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



{- Feedback -}


feedback : Device -> Model -> Element Msg
feedback device { phoenix, errors } =
    Feedback.init
        |> Feedback.elements
            [ FeedbackPanel.init
                |> FeedbackPanel.title "Info"
                |> FeedbackPanel.scrollable (info device errors)
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


info : Device -> List String -> List (Element Msg)
info device errors =
    List.filterMap
        (\error ->
            if error == "" then
                Nothing

            else
                FeedbackContent.init
                    |> FeedbackContent.title (Just "Error")
                    |> FeedbackContent.label "Socket"
                    |> FeedbackContent.element (El.text error)
                    |> FeedbackContent.view device
                    |> Just
        )
        errors


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
