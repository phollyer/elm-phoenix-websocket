module Page.JoinAndLeaveChannels exposing
    ( Model
    , Msg
    , init
    , subscriptions
    , toSession
    , update
    , updateSession
    , view
    )

import Element as El exposing (Device, DeviceClass(..), Element, Orientation(..))
import Example exposing (Action(..), Example(..))
import Extra.String as String
import Json.Encode as JE
import Phoenix
import Route
import Session exposing (Session)
import UI
import View.ApplicableFunctions as ApplicableFunctions
import View.Button as Button
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
      , example = SimpleJoinAndLeave Join
      , channelResponses = []
      }
    , Cmd.none
    )


type alias Model =
    { session : Session
    , example : Example
    , channelResponses : List Phoenix.ChannelResponse
    }


type Msg
    = GotHomeBtnClick
    | GotMenuItem (Action -> Example)
    | GotPhoenixMsg Phoenix.Msg
    | GotControlClick Example


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
                    { model | channelResponses = [] }
                |> updateExample example

        GotControlClick example ->
            case example of
                SimpleJoinAndLeave action ->
                    case action of
                        Join ->
                            phoenix
                                |> Phoenix.setJoinConfig
                                    { topic = "example:join_and_leave_channels"
                                    , payload = JE.null
                                    , events = []
                                    , timeout = Nothing
                                    }
                                |> Phoenix.join "example:join_and_leave_channels"
                                |> updatePhoenix model

                        Leave ->
                            Phoenix.leave "example:join_and_leave_channels" phoenix
                                |> updatePhoenix model

                        _ ->
                            ( model, Cmd.none )

                JoinWithGoodParams action ->
                    case action of
                        Join ->
                            phoenix
                                |> Phoenix.setJoinConfig
                                    { topic = "example:join_and_leave_channels"
                                    , payload =
                                        JE.object
                                            [ ( "username", JE.string "username" )
                                            , ( "password", JE.string "password" )
                                            ]
                                    , events = []
                                    , timeout = Nothing
                                    }
                                |> Phoenix.join "example:join_and_leave_channels"
                                |> updatePhoenix model

                        Leave ->
                            Phoenix.leave "example:join_and_leave_channels" phoenix
                                |> updatePhoenix model

                        _ ->
                            ( model, Cmd.none )

                JoinWithBadParams action ->
                    case action of
                        Join ->
                            phoenix
                                |> Phoenix.setJoinConfig
                                    { topic = "example:join_and_leave_channels"
                                    , payload =
                                        JE.object
                                            [ ( "username", JE.string "bad" )
                                            , ( "password", JE.string "wrong" )
                                            ]
                                    , events = []
                                    , timeout = Nothing
                                    }
                                |> Phoenix.join "example:join_and_leave_channels"
                                |> updatePhoenix model

                        _ ->
                            ( model, Cmd.none )

                JoinMultipleChannels action ->
                    case action of
                        Join ->
                            let
                                joins =
                                    List.range 0 3
                                        |> List.map
                                            (\index -> Phoenix.join ("example:join_channel_number_" ++ String.fromInt index))
                            in
                            phoenix
                                |> Phoenix.batch joins
                                |> updatePhoenix model

                        _ ->
                            ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        GotPhoenixMsg subMsg ->
            let
                ( newModel, cmd ) =
                    Phoenix.update subMsg phoenix
                        |> updatePhoenix model

                phx =
                    Session.phoenix newModel.session
            in
            case Phoenix.phoenixMsg phx of
                Phoenix.ChannelResponse response ->
                    case response of
                        Phoenix.JoinError _ _ ->
                            -- Leave the Channel after a JoinError to stop
                            -- PhoenixJS from constantly retrying
                            Phoenix.leave "example:join_and_leave_channels" phx
                                |> updatePhoenix
                                    { newModel
                                        | channelResponses =
                                            response :: newModel.channelResponses
                                    }
                                |> batch [ cmd ]

                        _ ->
                            ( { newModel
                                | channelResponses =
                                    response :: newModel.channelResponses
                              }
                            , cmd
                            )

                _ ->
                    ( newModel, cmd )


batch : List (Cmd Msg) -> ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
batch cmds ( model, cmd ) =
    ( model
    , Cmd.batch (cmd :: cmds)
    )


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
    { title = ""
    , content =
        Layout.init
            |> Layout.homeMsg (Just GotHomeBtnClick)
            |> Layout.title "Join and Leave Channels"
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
        [ El.text "Joining a Channel is taken care of automatically on the first push to a Channel, "
        , El.text "however, if you want to take manual control, here's a few examples."
        ]
    , UI.paragraph
        [ El.text "Clicking on a function will take you to its documentation." ]
    ]



{- Menu -}


menu : Device -> Model -> Element Msg
menu device { example } =
    Menu.init
        |> Menu.options
            [ Example.toString SimpleJoinAndLeave
            , Example.toString JoinWithGoodParams
            , Example.toString JoinWithBadParams
            , Example.toString JoinMultipleChannels
            ]
        |> Menu.selected (Example.toString <| Example.toFunc example)
        |> Menu.view device



{- Description -}


description : Model -> List (Element msg)
description { example } =
    case example of
        SimpleJoinAndLeave _ ->
            [ UI.paragraph
                [ El.text "A simple Join to a Channel without sending any params." ]
            ]

        JoinWithGoodParams _ ->
            [ UI.paragraph
                [ El.text "Join a Channel, providing auth params that are accepted." ]
            ]

        JoinWithBadParams _ ->
            [ UI.paragraph
                [ El.text "Join a Channel, providing auth params that are not accepted." ]
            ]

        JoinMultipleChannels _ ->
            [ UI.paragraph
                [ El.text "Join multiple Channels with a single command." ]
            ]

        _ ->
            []



{- Controls -}


controls : Device -> Phoenix.Model -> Model -> Element Msg
controls device phoenix model =
    ExampleControls.init
        |> ExampleControls.elements (buttons device phoenix model)
        |> ExampleControls.group
            (Group.init
                |> Group.layouts
                    [ ( Phone, Portrait, [ 2 ] ) ]
            )
        |> ExampleControls.view device


buttons : Device -> Phoenix.Model -> Model -> List (Element Msg)
buttons device phoenix { example } =
    case example of
        SimpleJoinAndLeave _ ->
            [ join SimpleJoinAndLeave device (not <| Phoenix.channelJoined "example:join_and_leave_channels" phoenix)
            , leave SimpleJoinAndLeave device (Phoenix.channelJoined "example:join_and_leave_channels" phoenix)
            ]

        JoinWithGoodParams _ ->
            [ join JoinWithGoodParams device (not <| Phoenix.channelJoined "example:join_and_leave_channels" phoenix)
            , leave JoinWithGoodParams device (Phoenix.channelJoined "example:join_and_leave_channels" phoenix)
            ]

        JoinWithBadParams _ ->
            [ join JoinWithBadParams device (not <| Phoenix.channelJoined "example:join_and_leave_channels" phoenix) ]

        JoinMultipleChannels _ ->
            [ join JoinMultipleChannels device (not <| Phoenix.channelJoined "example:join_and_leave_channels" phoenix)
            , leave JoinMultipleChannels device (Phoenix.channelJoined "example:join_and_leave_channels" phoenix)
            ]

        _ ->
            []


join : (Action -> Example) -> Device -> Bool -> Element Msg
join example device enabled =
    Button.init
        |> Button.label "Join"
        |> Button.onPress (Just (GotControlClick (example Join)))
        |> Button.enabled enabled
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
feedback device phoenix { example, channelResponses } =
    Feedback.init
        |> Feedback.elements
            [ FeedbackPanel.init
                |> FeedbackPanel.title "Info"
                |> FeedbackPanel.scrollable (channelResponsesView device channelResponses)
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


channelResponsesView : Device -> List Phoenix.ChannelResponse -> List (Element Msg)
channelResponsesView device responses =
    List.map (channelResponse device) responses


channelResponse : Device -> Phoenix.ChannelResponse -> Element Msg
channelResponse device response =
    case response of
        Phoenix.JoinOk topic payload ->
            FeedbackContent.init
                |> FeedbackContent.title (Just "Channel Response")
                |> FeedbackContent.label "JoinOk"
                |> FeedbackContent.element
                    (El.column
                        [ El.width El.fill ]
                        [ El.text topic
                        , El.text (JE.encode 2 payload)
                        ]
                    )
                |> FeedbackContent.view device

        Phoenix.LeaveOk topic ->
            FeedbackContent.init
                |> FeedbackContent.title (Just "Channel Response")
                |> FeedbackContent.label "LeaveOk"
                |> FeedbackContent.element (El.text topic)
                |> FeedbackContent.view device

        Phoenix.JoinError topic payload ->
            FeedbackContent.init
                |> FeedbackContent.title (Just "Channel Response")
                |> FeedbackContent.label "JoinError"
                |> FeedbackContent.element
                    (El.column
                        [ El.width El.fill ]
                        [ El.text topic
                        , El.text (JE.encode 2 payload)
                        ]
                    )
                |> FeedbackContent.view device

        _ ->
            El.none


applicableFunctions : Device -> Example -> Element Msg
applicableFunctions device example =
    ApplicableFunctions.init
        |> ApplicableFunctions.functions
            (case example of
                SimpleJoinAndLeave _ ->
                    [ "Phoenix.join"
                    , "Phoenix.leave"
                    ]

                JoinWithGoodParams _ ->
                    [ "Phoenix.setJoinConfig"
                    , "Phoenix.join"
                    , "Phoenix.leave"
                    ]

                JoinWithBadParams _ ->
                    [ "Phoenix.setJoinConfig"
                    , "Phoenix.join"
                    , "Phoenix.leave"
                    ]

                JoinMultipleChannels _ ->
                    [ "Phoenix.batch"
                    , "Phoenix.join"
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
                SimpleJoinAndLeave _ ->
                    [ ( "Phoenix.channelJoined", Phoenix.channelJoined "example:join_and_leave_channels" phoenix |> String.printBool )
                    , ( "Phoenix.joinedChannels", Phoenix.joinedChannels phoenix |> String.printList )
                    ]

                JoinWithGoodParams _ ->
                    [ ( "Phoenix.channelJoined", Phoenix.channelJoined "example:join_and_leave_channels" phoenix |> String.printBool )
                    , ( "Phoenix.joinedChannels", Phoenix.joinedChannels phoenix |> String.printList )
                    ]

                JoinWithBadParams _ ->
                    [ ( "Phoenix.channelJoined", Phoenix.channelJoined "example:join_and_leave_channels" phoenix |> String.printBool )
                    , ( "Phoenix.joinedChannels", Phoenix.joinedChannels phoenix |> String.printList )
                    ]

                JoinMultipleChannels _ ->
                    [ ( "Phoenix.joinedChannels", Phoenix.joinedChannels phoenix |> String.printList ) ]

                _ ->
                    []
            )
        |> UsefulFunctions.view device
