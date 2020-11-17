module Example.ManageSocketHeartbeat exposing
    ( Model
    , Msg
    , init
    , subscriptions
    , update
    , view
    )

import Device exposing (Device)
import Element as El exposing (DeviceClass(..), Element, Orientation(..))
import Example.Utils exposing (updatePhoenixWith)
import Extra.String as String
import Json.Encode exposing (Value)
import Phoenix
import Phoenix.Socket exposing (ConnectOption(..))
import UI
import View.ApplicableFunctions as ApplicableFunctions
import View.Button as Button
import View.Example.Controls as Controls
import View.Example.Example as Example
import View.Feedback as Feedback
import View.FeedbackContent as FeedbackContent
import View.FeedbackInfo as FeedbackInfo
import View.FeedbackPanel as FeedbackPanel
import View.Group as Group
import View.LabelAndValue as LabelAndValue
import View.UsefulFunctions as UsefulFunctions



{- Init -}


init : Phoenix.Model -> ( Model, Cmd Msg )
init phoenix =
    let
        ( phx, phxCmd ) =
            phoenix
                |> Phoenix.setConnectOptions
                    [ HeartbeatIntervalMillis 1000 ]
                |> Phoenix.connect
    in
    ( { phoenix = phx
      , messages = []
      , receiveMessages = True
      }
    , Cmd.map PhoenixMsg phxCmd
    )



{- Model -}


type alias Model =
    { phoenix : Phoenix.Model
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
    | PhoenixMsg Phoenix.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotControlClick action ->
            case action of
                On ->
                    ( { model | receiveMessages = True }
                    , Phoenix.heartbeatOn model.phoenix
                        |> Cmd.map PhoenixMsg
                    )

                Off ->
                    ( { model | receiveMessages = False }
                    , Phoenix.heartbeatOff model.phoenix
                        |> Cmd.map PhoenixMsg
                    )

        PhoenixMsg subMsg ->
            let
                ( newModel, cmd ) =
                    Phoenix.update subMsg model.phoenix
                        |> updatePhoenixWith PhoenixMsg model
            in
            case Phoenix.phoenixMsg newModel.phoenix of
                Phoenix.SocketMessage (Phoenix.Heartbeat message) ->
                    ( { newModel | messages = message :: model.messages }, cmd )

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
    [ [ El.text "Choose whether to receive the heartbeat as an incoming Socket message. For this example, the heartbeat interval is set at 1 second." ] ]



{- Controls -}


controls : Device -> Model -> Element Msg
controls device { receiveMessages } =
    Controls.init
        |> Controls.elements
            [ on device receiveMessages
            , off device receiveMessages
            ]
        |> Controls.view device


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


feedback : Device -> Model -> Element Msg
feedback device { phoenix, messages } =
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
