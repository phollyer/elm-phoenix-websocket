module Example.JoinMultipleChannels exposing
    ( Model
    , Msg
    , init
    , subscriptions
    , update
    , view
    )

import Device exposing (Device)
import Element as El exposing (Element)
import Example.Utils exposing (updatePhoenixWith)
import Extra.String as String
import Phoenix
import View.Button as Button
import View.Example as Example
import View.Example.ApplicableFunctions as ApplicableFunctions
import View.Example.Controls as Controls
import View.Example.Feedback as Feedback
import View.Example.Feedback.Content as FeedbackContent
import View.Example.Feedback.Info as FeedbackInfo
import View.Example.Feedback.Panel as FeedbackPanel
import View.Example.UsefulFunctions as UsefulFunctions



{- Init -}


init : Phoenix.Model -> Model
init phoenix =
    { phoenix = phoenix
    , responses = []
    }



{- Model -}


type alias Model =
    { phoenix : Phoenix.Model
    , responses : List Phoenix.ChannelResponse
    }


type Action
    = Join
    | Leave



{- Update -}


type Msg
    = GotControlClick Action
    | PhoenixMsg Phoenix.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotControlClick action ->
            case action of
                Join ->
                    let
                        joins =
                            List.range 0 3
                                |> List.map
                                    (\index -> Phoenix.join ("example:join_channel_number_" ++ String.fromInt index))
                    in
                    Phoenix.batch joins model.phoenix
                        |> updatePhoenixWith PhoenixMsg model

                Leave ->
                    let
                        leaves =
                            List.range 0 3
                                |> List.map
                                    (\index -> Phoenix.leave ("example:join_channel_number_" ++ String.fromInt index))
                    in
                    Phoenix.batch leaves model.phoenix
                        |> updatePhoenixWith PhoenixMsg model

        PhoenixMsg subMsg ->
            let
                ( newModel, cmd ) =
                    Phoenix.update subMsg model.phoenix
                        |> updatePhoenixWith PhoenixMsg model
            in
            case Phoenix.phoenixMsg newModel.phoenix of
                Phoenix.ChannelResponse response ->
                    ( { newModel | responses = response :: newModel.responses }, cmd )

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
    [ [ El.text "Join multiple Channels with a single command." ] ]



{- Controls -}


controls : Device -> Model -> Element Msg
controls device { phoenix } =
    Controls.init
        |> Controls.elements
            [ join device phoenix
            , leave device phoenix
            ]
        |> Controls.view device


join : Device -> Phoenix.Model -> Element Msg
join device phoenix =
    Button.init
        |> Button.label "Join"
        |> Button.onPress (Just (GotControlClick Join))
        |> Button.enabled ((Phoenix.joinedChannels phoenix |> List.length) == 0)
        |> Button.view device


leave : Device -> Phoenix.Model -> Element Msg
leave device phoenix =
    Button.init
        |> Button.label "Leave"
        |> Button.onPress (Just (GotControlClick Leave))
        |> Button.enabled ((Phoenix.joinedChannels phoenix |> List.length) > 0)
        |> Button.view device



{- Feedback -}


feedback : Device -> Model -> Element Msg
feedback device { phoenix, responses } =
    Feedback.init
        |> Feedback.elements
            [ FeedbackPanel.init
                |> FeedbackPanel.title "Info"
                |> FeedbackPanel.scrollable (channelResponses device responses)
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


channelResponses : Device -> List Phoenix.ChannelResponse -> List (Element Msg)
channelResponses device responses =
    List.map (channelResponse device) responses


channelResponse : Device -> Phoenix.ChannelResponse -> Element Msg
channelResponse device response =
    case response of
        Phoenix.JoinOk topic payload ->
            FeedbackContent.init
                |> FeedbackContent.title (Just "ChannelResponse")
                |> FeedbackContent.label "JoinOk"
                |> FeedbackContent.element
                    (FeedbackInfo.init
                        |> FeedbackInfo.topic topic
                        |> FeedbackInfo.payload payload
                        |> FeedbackInfo.view device
                    )
                |> FeedbackContent.view device

        Phoenix.LeaveOk topic ->
            FeedbackContent.init
                |> FeedbackContent.title (Just "ChannelResponse")
                |> FeedbackContent.label "LeaveOk"
                |> FeedbackContent.element
                    (FeedbackInfo.init
                        |> FeedbackInfo.topic topic
                        |> FeedbackInfo.view device
                    )
                |> FeedbackContent.view device

        _ ->
            El.none


applicableFunctions : Device -> Element Msg
applicableFunctions device =
    ApplicableFunctions.init
        |> ApplicableFunctions.functions
            [ "Phoenix.batch"
            , "Phoenix.join"
            , "Phoenix.leave"
            ]
        |> ApplicableFunctions.view device


usefulFunctions : Device -> Phoenix.Model -> Element Msg
usefulFunctions device phoenix =
    UsefulFunctions.init
        |> UsefulFunctions.functions
            [ ( "Phoenix.joinedChannels", Phoenix.joinedChannels phoenix |> String.printList ) ]
        |> UsefulFunctions.view device
