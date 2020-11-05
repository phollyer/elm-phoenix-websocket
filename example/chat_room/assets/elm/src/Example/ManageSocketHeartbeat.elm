module Example.ManageSocketHeartbeat exposing
    ( Model
    , Msg
    , init
    , subscriptions
    , update
    , view
    )

import Element as El exposing (Device, DeviceClass(..), Element, Orientation(..))
import Extra.String as String
import Json.Encode exposing (Value)
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
import View.LabelAndValue as LabelAndValue
import View.UsefulFunctions as UsefulFunctions



{- Init -}


init : Device -> Phoenix.Model -> Model
init device phoenix =
    { device = device
    , phoenix = phoenix
    , messages = []
    , receiveMessages = True
    }



{- Model -}


type alias Model =
    { device : Device
    , phoenix : Phoenix.Model
    , messages : List HeartbeatInfo
    , receiveMessages : Bool
    }


type alias HeartbeatInfo =
    { topic : String
    , event : String
    , payload : Value
    , ref : String
    }


type Action
    = On
    | Off



{- Update -}


type Msg
    = GotControlClick Action
    | GotPhoenixMsg Phoenix.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotControlClick action ->
            case action of
                On ->
                    ( { model | receiveMessages = True }
                    , Phoenix.heartbeatOn model.phoenix
                        |> Cmd.map GotPhoenixMsg
                    )

                Off ->
                    ( { model | receiveMessages = False }
                    , Phoenix.heartbeatOff model.phoenix
                        |> Cmd.map GotPhoenixMsg
                    )

        GotPhoenixMsg subMsg ->
            let
                ( phoenix, phoenixCmd ) =
                    Phoenix.update subMsg model.phoenix
            in
            case Phoenix.phoenixMsg phoenix of
                Phoenix.SocketMessage (Phoenix.Heartbeat info) ->
                    ( { model
                        | phoenix = phoenix
                        , messages = info :: model.messages
                      }
                    , Cmd.map GotPhoenixMsg phoenixCmd
                    )

                _ ->
                    ( model, Cmd.none )



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
        [ El.text "Choose whether to receive the heartbeat as an incoming Socket message. For this example, the heartbeat interval is set at 1 second." ]
    ]



{- Controls -}


controls : Model -> Element Msg
controls { device, receiveMessages } =
    ExampleControls.init
        |> ExampleControls.elements
            [ on device receiveMessages
            , off device receiveMessages
            ]
        |> ExampleControls.view device


on : Device -> Bool -> Element Msg
on device state =
    Button.init
        |> Button.label "Heartbeat On"
        |> Button.onPress (Just (GotControlClick On))
        |> Button.enabled (not state)
        |> Button.view device


off : Device -> Bool -> Element Msg
off device state =
    Button.init
        |> Button.label "Heartbeat Off"
        |> Button.onPress (Just (GotControlClick Off))
        |> Button.enabled state
        |> Button.view device



{- Feedback -}


feedback : Model -> Element Msg
feedback { device, phoenix, messages } =
    Feedback.init
        |> Feedback.elements
            [ FeedbackPanel.init
                |> FeedbackPanel.title "Info"
                |> FeedbackPanel.static (static device messages)
                |> FeedbackPanel.scrollable (scrollable device messages)
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
                |> Group.layouts
                    [ ( Phone, Landscape, [ 1, 2 ] )
                    , ( Tablet, Portrait, [ 1, 2 ] )
                    , ( Tablet, Landscape, [ 1, 2 ] )
                    , ( Desktop, Portrait, [ 1, 2 ] )
                    ]
            )
        |> Feedback.view device


static : Device -> List HeartbeatInfo -> List (Element Msg)
static device messages =
    [ LabelAndValue.init
        |> LabelAndValue.label "Heartbeat Count"
        |> LabelAndValue.value (messages |> List.length |> String.fromInt)
        |> LabelAndValue.view device
    ]


scrollable : Device -> List HeartbeatInfo -> List (Element Msg)
scrollable device messages =
    List.map
        (\info ->
            FeedbackContent.init
                |> FeedbackContent.title (Just "SocketMessage")
                |> FeedbackContent.label "Heartbeat"
                |> FeedbackContent.element (heartbeatInfo device info)
                |> FeedbackContent.view device
        )
        messages


heartbeatInfo : Device -> HeartbeatInfo -> Element Msg
heartbeatInfo device info =
    FeedbackInfo.init
        |> FeedbackInfo.topic info.topic
        |> FeedbackInfo.event info.event
        |> FeedbackInfo.payload info.payload
        |> FeedbackInfo.ref (Just info.ref)
        |> FeedbackInfo.view device


applicableFunctions : Device -> Element Msg
applicableFunctions device =
    ApplicableFunctions.init
        |> ApplicableFunctions.functions
            [ "Phoenix.setConnectOptions"
            , "Phoenix.heartbeatOn"
            , "Phoenix.heartbeatOff"
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
