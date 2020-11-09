module Example.ReceiveEvents exposing
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
import Json.Encode as JE exposing (Value)
import Phoenix
import UI
import View.ApplicableFunctions as ApplicableFunctions
import View.Button as Button
import View.Example as Example
import View.ExampleControls as ExampleControls
import View.Feedback as Feedback
import View.FeedbackContent as FeedbackContent
import View.FeedbackInfo as FeedbackInfo
import View.FeedbackPanel as FeedbackPanel
import View.Group as Group
import View.UsefulFunctions as UsefulFunctions



{- Init -}


init : Phoenix.Model -> Model
init phoenix =
    { phoenix = phoenix
    , info = []
    }



{- Model -}


type alias Model =
    { phoenix : Phoenix.Model
    , info : List Info
    }


type Action
    = Push
    | Leave


type Info
    = Response Phoenix.ChannelResponse
    | Event
        { topic : String
        , event : String
        , payload : Value
        }



{- Update -}


type Msg
    = GotControlClick Action
    | GotPhoenixMsg Phoenix.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotControlClick action ->
            case action of
                Push ->
                    model.phoenix
                        |> Phoenix.setJoinConfig
                            { topic = "example:send_and_receive"
                            , events = [ "receive_event_1", "receive_event_2" ]
                            , payload = JE.null
                            , timeout = Nothing
                            }
                        |> Phoenix.push
                            { topic = "example:send_and_receive"
                            , event = "receive_events"
                            , payload = JE.null
                            , timeout = Nothing
                            , retryStrategy = Phoenix.Drop
                            , ref = Just "custom_ref"
                            }
                        |> updatePhoenixWith GotPhoenixMsg model

                Leave ->
                    Phoenix.leave "example:send_and_receive" model.phoenix
                        |> updatePhoenixWith GotPhoenixMsg model

        GotPhoenixMsg phxMsg ->
            let
                ( newModel, cmd ) =
                    Phoenix.update phxMsg model.phoenix
                        |> updatePhoenixWith GotPhoenixMsg model
            in
            case Phoenix.phoenixMsg newModel.phoenix of
                Phoenix.ChannelResponse response ->
                    ( { newModel
                        | info =
                            Response response :: newModel.info
                      }
                    , cmd
                    )

                Phoenix.ChannelEvent topic event payload ->
                    ( { newModel
                        | info =
                            Event
                                { topic = topic
                                , event = event
                                , payload = payload
                                }
                                :: newModel.info
                      }
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
    [ [ El.text "Receive two events from the Channel after a "
      , UI.code "push"
      , El.text "."
      ]
    ]



{- Controls -}


controls : Device -> Model -> Element Msg
controls device { phoenix } =
    ExampleControls.init
        |> ExampleControls.elements (buttons device phoenix)
        |> ExampleControls.view device


buttons : Device -> Phoenix.Model -> List (Element Msg)
buttons device phoenix =
    [ push device
    , leave device (Phoenix.channelJoined "example:send_and_receive" phoenix)
    ]


push : Device -> Element Msg
push device =
    Button.init
        |> Button.label "Push Event"
        |> Button.onPress (Just (GotControlClick Push))
        |> Button.enabled True
        |> Button.view device


leave : Device -> Bool -> Element Msg
leave device enabled =
    Button.init
        |> Button.label "Leave"
        |> Button.onPress (Just (GotControlClick Leave))
        |> Button.enabled enabled
        |> Button.view device



{- Feedback -}


feedback : Device -> Model -> Element Msg
feedback device { phoenix, info } =
    Feedback.init
        |> Feedback.elements
            [ FeedbackPanel.init
                |> FeedbackPanel.title "Info"
                |> FeedbackPanel.scrollable (infoView device info)
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
        |> Feedback.group
            (Group.init
                |> Group.layouts [ ( Tablet, Portrait, [ 1, 2 ] ) ]
            )
        |> Feedback.view device


infoView : Device -> List Info -> List (Element Msg)
infoView device info =
    List.map
        (\item ->
            case item of
                Response response ->
                    channelResponse device response

                Event event ->
                    channelEvent device event
        )
        info


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

        Phoenix.PushOk topic event ref payload ->
            FeedbackContent.init
                |> FeedbackContent.title (Just "ChannelResponse")
                |> FeedbackContent.label "PushOk"
                |> FeedbackContent.element
                    (FeedbackInfo.init
                        |> FeedbackInfo.topic topic
                        |> FeedbackInfo.event event
                        |> FeedbackInfo.ref ref
                        |> FeedbackInfo.payload payload
                        |> FeedbackInfo.view device
                    )
                |> FeedbackContent.view device

        _ ->
            El.none


channelEvent : Device -> { topic : String, event : String, payload : Value } -> Element Msg
channelEvent device { topic, event, payload } =
    FeedbackContent.init
        |> FeedbackContent.title (Just "ChannelEvent")
        |> FeedbackContent.element
            (FeedbackInfo.init
                |> FeedbackInfo.topic topic
                |> FeedbackInfo.event event
                |> FeedbackInfo.payload payload
                |> FeedbackInfo.view device
            )
        |> FeedbackContent.view device


applicableFunctions : Device -> Element Msg
applicableFunctions device =
    ApplicableFunctions.init
        |> ApplicableFunctions.functions
            [ "Phoenix.setJoinConfig"
            , "Phoenix.push"
            , "Phoenix.leave"
            ]
        |> ApplicableFunctions.view device


usefulFunctions : Device -> Phoenix.Model -> Element Msg
usefulFunctions device phoenix =
    UsefulFunctions.init
        |> UsefulFunctions.functions
            [ ( "Phoenix.channelJoined", Phoenix.channelJoined "example:send_and_receive" phoenix |> String.printBool )
            , ( "Phoenix.joinedChannels", Phoenix.joinedChannels phoenix |> String.printList )
            ]
        |> UsefulFunctions.view device
