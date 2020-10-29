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
import View.FeedbackPanel as FeedbackPanel
import View.Group as Group
import View.Layout as Layout
import View.Menu as Menu
import View.UsefulFunctions as UsefulFunctions


init : Session -> ( Model, Cmd Msg )
init session =
    ( { session = session
      , example = SimpleJoinAndLeave Join
      }
    , Cmd.none
    )


type alias Model =
    { session : Session
    , example : Example
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
            Phoenix.disconnect Nothing phoenix
                |> updatePhoenix model
                |> updateExample example

        GotPhoenixMsg subMsg ->
            Phoenix.update subMsg phoenix
                |> updatePhoenix model

        GotControlClick example ->
            case example of
                SimpleJoinAndLeave action ->
                    case action of
                        Join ->
                            Phoenix.join "example:join_and_leave_channels" phoenix
                                |> updatePhoenix model

                        Leave ->
                            Phoenix.leave "example:join_and_leave_channels" phoenix
                                |> updatePhoenix model

                        _ ->
                            ( model, Cmd.none )

                JoinWithGoodParams action ->
                    case action of
                        Join ->
                            Phoenix.setJoinConfig
                                { topic = "example:join_and_leave_channels"
                                , payload =
                                    JE.object
                                        [ ( "username", JE.string "username" )
                                        , ( "password", JE.string "password" )
                                        ]
                                , events = []
                                , timeout = Nothing
                                }
                                phoenix
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
                            Phoenix.setJoinConfig
                                { topic = "example:join_and_leave_channels"
                                , payload =
                                    JE.object
                                        [ ( "username", JE.string "bad" )
                                        , ( "password", JE.string "wrong" )
                                        ]
                                , events = []
                                , timeout = Nothing
                                }
                                phoenix
                                |> Phoenix.join "example:join_and_leave_channels"
                                |> updatePhoenix model

                        _ ->
                            ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )


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
    , Cmd.batch
        [ Cmd.map GotPhoenixMsg phoenixCmd
        , Cmd.map GotPhoenixMsg (Phoenix.heartbeatMessagesOff phoenix)
        ]
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
            [ ( Example.toString SimpleJoinAndLeave, GotMenuItem SimpleJoinAndLeave )
            , ( Example.toString JoinWithGoodParams, GotMenuItem JoinWithGoodParams )
            , ( Example.toString JoinWithBadParams, GotMenuItem JoinWithBadParams )
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
feedback device phoenix { example } =
    Feedback.init
        |> Feedback.elements
            [ FeedbackPanel.init
                |> FeedbackPanel.title "Applicable Functions"
                |> FeedbackPanel.scrollable [ applicableFunctions device example ]
                |> FeedbackPanel.view device
            , FeedbackPanel.init
                |> FeedbackPanel.title "Useful Functions"
                |> FeedbackPanel.scrollable [ usefulFunctions device phoenix example ]
                |> FeedbackPanel.view device
            ]
        |> Feedback.view device


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

                _ ->
                    []
            )
        |> UsefulFunctions.view device
