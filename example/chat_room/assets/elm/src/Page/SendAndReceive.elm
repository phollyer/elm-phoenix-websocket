module Page.SendAndReceive exposing (..)

import Element as El exposing (Device, DeviceClass(..), Element, Orientation(..))
import Example exposing (Action(..), Example(..))
import Extra.String as String
import Json.Encode as JE exposing (Value)
import Phoenix
import Route
import Session exposing (Session)
import UI
import View.ApplicableFunctions as ApplicableFunctions
import View.Button as Button
import View.ChannelMessage as ChannelMessage
import View.Example as Example
import View.ExampleControls as ExampleControls
import View.Feedback as Feedback
import View.FeedbackContent as FeedbackContent
import View.FeedbackPanel as FeedbackPanel
import View.Group as Group
import View.Layout as Layout
import View.Menu as Menu
import View.UsefulFunctions as UsefulFunctions


init : Session -> ( Model, Cmd Msg )
init session =
    ( { session = session
      , example = PushOneEvent Push
      , info = []
      }
    , Cmd.none
    )


type alias Model =
    { session : Session
    , example : Example
    , info : List Info
    }


type Info
    = Response Phoenix.ChannelResponse
    | Event
        { topic : String
        , event : String
        , payload : Value
        }



{- Update -}


type Msg
    = GotHomeBtnClick
    | GotMenuItem (Action -> Example)
    | GotControlClick Example
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

        GotMenuItem example ->
            Phoenix.disconnectAndReset Nothing phoenix
                |> updatePhoenix
                    { model | info = [] }
                |> updateExample example

        GotControlClick example ->
            case example of
                PushOneEvent action ->
                    case action of
                        Push ->
                            phoenix
                                |> Phoenix.push
                                    { topic = "example:send_and_receive"
                                    , event = "example_push"
                                    , payload = JE.null
                                    , timeout = Nothing
                                    , retryStrategy = Phoenix.Drop
                                    , ref = Just "custom_ref"
                                    }
                                |> updatePhoenix model

                        Leave ->
                            Phoenix.leave "example:send_and_receive" phoenix
                                |> updatePhoenix model

                        _ ->
                            ( model, Cmd.none )

                PushMultipleEvents action ->
                    case action of
                        Push ->
                            phoenix
                                |> Phoenix.pushAll
                                    (List.range 1 3
                                        |> List.map
                                            (\index ->
                                                { topic = "example:send_and_receive"
                                                , event = "example_push"
                                                , payload = JE.null
                                                , timeout = Nothing
                                                , retryStrategy = Phoenix.Drop
                                                , ref = Just (String.fromInt index)
                                                }
                                            )
                                        |> List.reverse
                                    )
                                |> updatePhoenix model

                        Leave ->
                            Phoenix.leave "example:send_and_receive" phoenix
                                |> updatePhoenix model

                        _ ->
                            ( model, Cmd.none )

                ReceiveEvents action ->
                    case action of
                        Push ->
                            phoenix
                                |> Phoenix.setJoinConfig
                                    { topic = "example:send_and_receive"
                                    , events = [ "receive_push", "receive_broadcast" ]
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
                                |> updatePhoenix model

                        Leave ->
                            Phoenix.leave "example:send_and_receive" phoenix
                                |> updatePhoenix model

                        _ ->
                            ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        GotPhoenixMsg phxMsg ->
            let
                ( newModel, cmd ) =
                    Phoenix.update phxMsg phoenix
                        |> updatePhoenix model

                phx =
                    Session.phoenix newModel.session
            in
            case Phoenix.phoenixMsg phx of
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
    , Cmd.map GotPhoenixMsg phoenixCmd
    )


toSession : Model -> Session
toSession model =
    model.session


updateSession : Session -> Model -> Model
updateSession session model =
    { model | session = session }



{- Subscriptions -}


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.map GotPhoenixMsg <|
        Phoenix.subscriptions (Session.phoenix model.session)



{- View -}


view : Model -> { title : String, content : Element Msg }
view model =
    let
        device =
            Session.device model.session

        phoenix =
            Session.phoenix model.session
    in
    { title = "Send and Receive"
    , content =
        Layout.init
            |> Layout.homeMsg (Just GotHomeBtnClick)
            |> Layout.title "Send and Receive"
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



{- Introduction -}


introduction : List (Element Msg)
introduction =
    [ UI.paragraph
        [ El.text "You can push to a Channel without needing to connect to the Socket or join "
        , El.text "the Channel. These processes will be taken care of automatically when you send the push."
        ]
    , UI.paragraph
        [ El.text "Clicking on a function will take you to its documentation." ]
    ]



{- Menu -}


menu : Device -> Model -> Element Msg
menu device { example } =
    Menu.init
        |> Menu.options
            [ ( Example.toString PushOneEvent, GotMenuItem PushOneEvent )
            , ( Example.toString PushMultipleEvents, GotMenuItem PushMultipleEvents )
            , ( Example.toString ReceiveEvents, GotMenuItem ReceiveEvents )
            ]
        |> Menu.selected (Example.toString <| Example.toFunc example)
        |> Menu.view device



{- Description -}


description : Model -> List (Element Msg)
description { example } =
    case example of
        PushOneEvent _ ->
            [ UI.paragraph
                [ El.text "Push an event to the Channel with no need to connect to the socket, or join the channel first." ]
            ]

        PushMultipleEvents _ ->
            [ UI.paragraph
                [ El.text "Push multiple events to the Channel with no need to connect to the socket, or join the channel first. "
                , El.text "This example will make 3 simultaneous pushes."
                ]
            ]

        ReceiveEvents _ ->
            [ UI.paragraph
                [ El.text "Receive multiple events from the Channel after pushing an event to the Channel. "
                , El.text "This example will receive two events in return from a "
                , UI.code "push"
                , El.text ". The first is "
                , UI.code "push"
                , El.text "'ed from the server to the client, the second is "
                , UI.code "broadcast"
                , El.text "ed to all connected clients."
                ]
            ]

        _ ->
            []



{- Controls -}


controls : Device -> Phoenix.Model -> Model -> Element Msg
controls device phoenix model =
    ExampleControls.init
        |> ExampleControls.elements (buttons device phoenix model)
        |> ExampleControls.view device


buttons : Device -> Phoenix.Model -> Model -> List (Element Msg)
buttons device phoenix { example } =
    case example of
        PushOneEvent _ ->
            [ push PushOneEvent device
            , leave PushOneEvent device (Phoenix.channelJoined "example:send_and_receive" phoenix)
            ]

        PushMultipleEvents _ ->
            [ push PushMultipleEvents device
            , leave PushMultipleEvents device (Phoenix.channelJoined "example:send_and_receive" phoenix)
            ]

        ReceiveEvents _ ->
            [ push ReceiveEvents device
            , leave ReceiveEvents device (Phoenix.channelJoined "example:send_and_receive" phoenix)
            ]

        _ ->
            []


push : (Action -> Example) -> Device -> Element Msg
push example device =
    Button.init
        |> Button.label "Push Event"
        |> Button.onPress (Just (GotControlClick (example Push)))
        |> Button.enabled True
        |> Button.view device


leave : (Action -> Example) -> Device -> Bool -> Element Msg
leave example device enabled =
    Button.init
        |> Button.label "Leave"
        |> Button.onPress (Just (GotControlClick (example Leave)))
        |> Button.enabled enabled
        |> Button.view device



{- Feedback -}


feedback : Device -> Phoenix.Model -> Model -> Element Msg
feedback device phoenix { example, info } =
    Feedback.init
        |> Feedback.elements
            [ FeedbackPanel.init
                |> FeedbackPanel.title "Info"
                |> FeedbackPanel.scrollable (infoView device info)
                |> FeedbackPanel.view device
            , FeedbackPanel.init
                |> FeedbackPanel.title "Applicable Functions"
                |> FeedbackPanel.scrollable [ applicableFunctions device example ]
                |> FeedbackPanel.view device
            , FeedbackPanel.init
                |> FeedbackPanel.title "Useful Functions"
                |> FeedbackPanel.scrollable [ usefulFunctions device phoenix example ]
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
                    (ChannelMessage.init
                        |> ChannelMessage.topic topic
                        |> ChannelMessage.payload payload
                        |> ChannelMessage.view device
                    )
                |> FeedbackContent.view device

        Phoenix.LeaveOk topic ->
            FeedbackContent.init
                |> FeedbackContent.title (Just "ChannelResponse")
                |> FeedbackContent.label "LeaveOk"
                |> FeedbackContent.element
                    (ChannelMessage.init
                        |> ChannelMessage.topic topic
                        |> ChannelMessage.view device
                    )
                |> FeedbackContent.view device

        Phoenix.PushOk topic event ref payload ->
            FeedbackContent.init
                |> FeedbackContent.title (Just "ChannelResponse")
                |> FeedbackContent.label "PushOk"
                |> FeedbackContent.element
                    (ChannelMessage.init
                        |> ChannelMessage.topic topic
                        |> ChannelMessage.event event
                        |> ChannelMessage.ref ref
                        |> ChannelMessage.payload payload
                        |> ChannelMessage.view device
                    )
                |> FeedbackContent.view device

        _ ->
            El.none


channelEvent : Device -> { topic : String, event : String, payload : Value } -> Element Msg
channelEvent device { topic, event, payload } =
    FeedbackContent.init
        |> FeedbackContent.title (Just "ChannelEvent")
        |> FeedbackContent.element
            (ChannelMessage.init
                |> ChannelMessage.topic topic
                |> ChannelMessage.event event
                |> ChannelMessage.payload payload
                |> ChannelMessage.view device
            )
        |> FeedbackContent.view device


applicableFunctions : Device -> Example -> Element Msg
applicableFunctions device example =
    ApplicableFunctions.init
        |> ApplicableFunctions.functions
            (case example of
                PushOneEvent _ ->
                    [ "Phoenix.push"
                    , "Phoenix.leave"
                    ]

                PushMultipleEvents _ ->
                    [ "Phoenix.pushAll"
                    , "Phoenix.leave"
                    ]

                ReceiveEvents _ ->
                    [ "Phoenix.setJoinConfig"
                    , "Phoenix.push"
                    , "Phoenix.leave"
                    ]

                _ ->
                    []
            )
        |> ApplicableFunctions.view device


usefulFunctions : Device -> Phoenix.Model -> Example -> Element Msg
usefulFunctions device phoenix example =
    UsefulFunctions.init
        |> UsefulFunctions.functions
            (case example of
                PushOneEvent _ ->
                    [ ( "Phoenix.channelJoined", Phoenix.channelJoined "example:send_and_receive" phoenix |> String.printBool )
                    , ( "Phoenix.joinedChannels", Phoenix.joinedChannels phoenix |> String.printList )
                    ]

                PushMultipleEvents _ ->
                    [ ( "Phoenix.channelJoined", Phoenix.channelJoined "example:send_and_receive" phoenix |> String.printBool )
                    , ( "Phoenix.joinedChannels", Phoenix.joinedChannels phoenix |> String.printList )
                    ]

                ReceiveEvents _ ->
                    [ ( "Phoenix.channelJoined", Phoenix.channelJoined "example:send_and_receive" phoenix |> String.printBool )
                    , ( "Phoenix.joinedChannels", Phoenix.joinedChannels phoenix |> String.printList )
                    ]

                _ ->
                    []
            )
        |> UsefulFunctions.view device
