module Example.ManageChannelMessages exposing
    ( Model
    , Msg
    , init
    , subscriptions
    , update
    , view
    )

import Element as El exposing (Device, DeviceClass(..), Element, Orientation(..))
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
import View.LabelAndValue as LabelAndValue
import View.UsefulFunctions as UsefulFunctions



{- Init -}


init : Phoenix.Model -> ( Model, Cmd Msg )
init phoenix =
    ( { phoenix = phoenix
      , messages = []
      , receiveMessages = True
      }
    , Cmd.none
    )



{- Model -}


type alias Model =
    { phoenix : Phoenix.Model
    , messages : List ChannelInfo
    , receiveMessages : Bool
    }


type alias ChannelInfo =
    { topic : Phoenix.Topic
    , event : Phoenix.Event
    , payload : Value
    , joinRef : Maybe String
    , ref : Maybe String
    }


type Action
    = Push
    | On
    | Off


pushConfig : Phoenix.Push
pushConfig =
    { topic = ""
    , event = ""
    , payload = JE.null
    , timeout = Nothing
    , retryStrategy = Phoenix.Drop
    , ref = Nothing
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
                        |> Phoenix.push
                            { pushConfig
                                | topic = "example:manage_channel_messages"
                                , event = "empty_message"
                            }
                        |> updatePhoenix model

                On ->
                    ( { model | receiveMessages = True }
                    , Phoenix.socketChannelMessagesOn model.phoenix
                        |> Cmd.map GotPhoenixMsg
                    )

                Off ->
                    ( { model | receiveMessages = False }
                    , Phoenix.socketChannelMessagesOff model.phoenix
                        |> Cmd.map GotPhoenixMsg
                    )

        GotPhoenixMsg subMsg ->
            let
                ( newModel, cmd ) =
                    Phoenix.update subMsg model.phoenix
                        |> updatePhoenix model
            in
            case Phoenix.phoenixMsg newModel.phoenix of
                Phoenix.SocketMessage (Phoenix.ChannelMessage info) ->
                    ( { newModel
                        | messages = info :: model.messages
                      }
                    , cmd
                    )

                _ ->
                    ( newModel, cmd )


updatePhoenix : Model -> ( Phoenix.Model, Cmd Phoenix.Msg ) -> ( Model, Cmd Msg )
updatePhoenix model ( phoenix, phoenixCmd ) =
    ( { model | phoenix = phoenix }
    , Cmd.map GotPhoenixMsg phoenixCmd
    )



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


description : List (Element msg)
description =
    [ UI.paragraph
        [ El.text "Choose whether to receive Channel messages as an incoming Socket message." ]
    ]



{- Controls -}


controls : Device -> Model -> Element Msg
controls device { receiveMessages } =
    ExampleControls.init
        |> ExampleControls.elements
            [ push device
            , on device receiveMessages
            , off device receiveMessages
            ]
        |> ExampleControls.group
            (Group.init
                |> Group.layouts
                    [ ( Phone, Portrait, [ 2, 2 ] ) ]
                |> Group.order
                    [ ( Phone, Portrait, [ 0, 2, 3, 1 ] ) ]
            )
        |> ExampleControls.view device


push : Device -> Element Msg
push device =
    Button.init
        |> Button.label "Push Message"
        |> Button.onPress (Just (GotControlClick Push))
        |> Button.enabled True
        |> Button.view device


on : Device -> Bool -> Element Msg
on device state =
    Button.init
        |> Button.label "Messages On"
        |> Button.onPress (Just (GotControlClick On))
        |> Button.enabled (not state)
        |> Button.view device


off : Device -> Bool -> Element Msg
off device state =
    Button.init
        |> Button.label "Messages Off"
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


static : Device -> List ChannelInfo -> List (Element Msg)
static device messages =
    [ LabelAndValue.init
        |> LabelAndValue.label "Message Count"
        |> LabelAndValue.value (messages |> List.length |> String.fromInt)
        |> LabelAndValue.view device
    ]


scrollable : Device -> List ChannelInfo -> List (Element Msg)
scrollable device messages =
    List.map
        (\info ->
            FeedbackContent.init
                |> FeedbackContent.title (Just "SocketMessage")
                |> FeedbackContent.label "ChannelMessage"
                |> FeedbackContent.element (channelInfo device info)
                |> FeedbackContent.view device
        )
        messages


channelInfo : Device -> ChannelInfo -> Element Msg
channelInfo device info =
    FeedbackInfo.init
        |> FeedbackInfo.topic info.topic
        |> FeedbackInfo.event info.event
        |> FeedbackInfo.payload info.payload
        |> FeedbackInfo.ref info.ref
        |> FeedbackInfo.joinRef info.joinRef
        |> FeedbackInfo.view device


applicableFunctions : Device -> Element Msg
applicableFunctions device =
    ApplicableFunctions.init
        |> ApplicableFunctions.functions
            [ "Phoenix.push"
            , "Phoenix.socketChannelMessagesOn"
            , "Phoenix.socketChannelMessagesOff"
            ]
        |> ApplicableFunctions.view device


usefulFunctions : Device -> Phoenix.Model -> Element Msg
usefulFunctions device phoenix =
    UsefulFunctions.init
        |> UsefulFunctions.functions
            [ ( "Phoenix.socketState", Phoenix.socketStateToString phoenix )
            , ( "Phoenix.connectionState", Phoenix.connectionState phoenix |> String.printQuoted )
            , ( "Phoenix.isConnected", Phoenix.isConnected phoenix |> String.printBool )
            , ( "Phoenix.channelJoined", Phoenix.channelJoined "example:manage_channel_messages" phoenix |> String.printBool )
            , ( "Phoenix.joinedChannels"
              , Phoenix.joinedChannels phoenix
                    |> List.filter (String.startsWith "example:")
                    |> String.printList
              )
            ]
        |> UsefulFunctions.view device
