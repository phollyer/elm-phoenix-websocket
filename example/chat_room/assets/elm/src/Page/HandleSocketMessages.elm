module Page.HandleSocketMessages exposing
    ( Model
    , Msg
    , init
    , subscriptions
    , toSession
    , update
    , updateSession
    , view
    )

import Colors.Opaque as Color
import Element as El exposing (Device, DeviceClass(..), Element, Orientation(..))
import Element.Font as Font
import Example exposing (Action(..), Example(..))
import Example.ManageChannelMessages as ManageChannelMessages
import Example.ManagePresenceMessages as ManagePresenceMessages
import Example.ManageSocketHeartbeat as ManageSocketHeartbeat
import Extra.String as String
import Json.Decode as JD
import Json.Decode.Extra exposing (andMap)
import Json.Encode as JE exposing (Value)
import Json.Encode.Extra exposing (maybe)
import Phoenix
import Phoenix.Socket as Socket
import Route
import Session exposing (Session)
import UI
import View.ApplicableFunctions as ApplicableFunctions
import View.Button as Button
import View.Example as Example
import View.ExampleControls as ExampleControls
import View.ExamplePage as ExamplePage
import View.Feedback as Feedback
import View.FeedbackContent as FeedbackContent
import View.FeedbackInfo as FeedbackInfo
import View.FeedbackPanel as FeedbackPanel
import View.Group as Group
import View.LabelAndValue as LabelAndValue
import View.Layout as Layout
import View.Menu as Menu
import View.UsefulFunctions as UsefulFunctions



{- Init -}


init : Session -> Maybe String -> Maybe ID -> ( Model, Cmd Msg )
init session maybeExample maybeExampleId =
    ( { session = session
      , example = initExample maybeExample maybeExampleId session
      , maybeExampleId = maybeExampleId
      }
    , Cmd.none
    )


initExample : Maybe String -> Maybe ID -> Session -> Example
initExample maybeExample maybeExampleId session =
    case maybeExample of
        Just example ->
            if example == "ManagePresenceMessages" then
                ManagePresenceMessages <|
                    ManagePresenceMessages.init
                        maybeExampleId
                        (Session.device session)
                        (Session.phoenix session)

            else
                ManageSocketHeartbeat <|
                    ManageSocketHeartbeat.init
                        (Session.device session)
                        (Session.phoenix session)

        Nothing ->
            ManageSocketHeartbeat <|
                ManageSocketHeartbeat.init
                    (Session.device session)
                    (Session.phoenix session)



{- Model -}


type alias Model =
    { session : Session
    , example : Example
    , maybeExampleId : Maybe ID
    }


type Example
    = ManageSocketHeartbeat ManageSocketHeartbeat.Model
    | ManageChannelMessages ManageChannelMessages.Model
    | ManagePresenceMessages ManagePresenceMessages.Model


type alias ID =
    String



{- Update -}


type Msg
    = GotHomeBtnClick
    | GotMenuItem String
    | GotPhoenixMsg Phoenix.Msg
    | GotManageSocketHeartbeatMsg ManageSocketHeartbeat.Msg
    | GotManageChannelMessagesMsg ManageChannelMessages.Msg
    | GotManagePresenceMessagesMsg ManagePresenceMessages.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        phoenix =
            Session.phoenix model.session
    in
    case ( msg, model.example ) of
        ( GotHomeBtnClick, _ ) ->
            ( model
            , Route.pushUrl
                (Session.navKey model.session)
                Route.Home
            )

        ( GotMenuItem example_, _ ) ->
            Phoenix.disconnect Nothing phoenix
                |> updatePhoenix model
                |> updateExample example_

        ( GotPhoenixMsg subMsg, _ ) ->
            Phoenix.update subMsg phoenix
                |> updatePhoenix model

        ( GotManageSocketHeartbeatMsg subMsg, ManageSocketHeartbeat subModel ) ->
            ManageSocketHeartbeat.update subMsg subModel
                |> updateWith ManageSocketHeartbeat GotManageSocketHeartbeatMsg model

        ( GotManageChannelMessagesMsg subMsg, ManageChannelMessages subModel ) ->
            ManageChannelMessages.update subMsg subModel
                |> updateWith ManageChannelMessages GotManageChannelMessagesMsg model

        ( GotManagePresenceMessagesMsg subMsg, ManagePresenceMessages subModel ) ->
            ManagePresenceMessages.update subMsg subModel
                |> updateWith ManagePresenceMessages GotManagePresenceMessagesMsg model

        _ ->
            ( model, Cmd.none )


updateWith : (subModel -> Example) -> (subMsg -> Msg) -> Model -> ( subModel, Cmd subMsg ) -> ( Model, Cmd Msg )
updateWith toExample toMsg model ( subModel, cmd ) =
    ( { model | example = toExample subModel }
    , Cmd.map toMsg cmd
    )


updatePhoenix : Model -> ( Phoenix.Model, Cmd Phoenix.Msg ) -> ( Model, Cmd Msg )
updatePhoenix model ( phoenix, phoenixCmd ) =
    ( { model
        | session = Session.updatePhoenix phoenix model.session
      }
    , Cmd.map GotPhoenixMsg phoenixCmd
    )


updateExample : String -> ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
updateExample selectedExample ( model, cmd ) =
    ( { model
        | example =
            case selectedExample of
                "Manage The Socket Heartbeat" ->
                    ManageSocketHeartbeat <|
                        ManageSocketHeartbeat.init
                            (Session.device model.session)
                            (Session.phoenix model.session)

                "Manage Channel Messages" ->
                    ManageChannelMessages <|
                        ManageChannelMessages.init
                            (Session.device model.session)
                            (Session.phoenix model.session)

                "Manage Presence Messages" ->
                    ManagePresenceMessages <|
                        ManagePresenceMessages.init
                            model.maybeExampleId
                            (Session.device model.session)
                            (Session.phoenix model.session)

                _ ->
                    ManageSocketHeartbeat <|
                        ManageSocketHeartbeat.init
                            (Session.device model.session)
                            (Session.phoenix model.session)
      }
    , cmd
    )



{- Subscriptions -}


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.map GotPhoenixMsg <|
        Phoenix.subscriptions (Session.phoenix model.session)



{- Session -}


toSession : Model -> Session
toSession model =
    model.session


updateSession : Session -> Model -> Model
updateSession session model =
    { model | session = session }



{- Device -}


toDevice : Model -> Device
toDevice model =
    Session.device model.session



{- View -}


view : Model -> { title : String, content : Element Msg }
view model =
    let
        phoenix =
            Session.phoenix model.session

        device =
            toDevice model
    in
    { title = "Handle Socket Messages"
    , content =
        Layout.init
            |> Layout.homeMsg (Just GotHomeBtnClick)
            |> Layout.title "Handle Socket Messages"
            |> Layout.body
                (ExamplePage.init
                    |> ExamplePage.introduction introduction
                    |> ExamplePage.menu (menu device model)
                    |> ExamplePage.example (viewExample model)
                    |> ExamplePage.view device
                )
            |> Layout.view device
    }


{-| Introudction
-}
introduction : List (Element msg)
introduction =
    [ UI.paragraph
        [ El.text "By default, the PhoenixJS "
        , UI.code "onMessage"
        , El.text " handler for the Socket is setup to send all Socket messages through the incoming "
        , UI.code "port"
        , El.text ". These examples demonstrate controlling the types of messages that are allowed through."
        ]
    , UI.paragraph
        [ El.text "Clicking on a function will take you to its documentation." ]
    ]


{-| Page Menu
-}
menu : Device -> Model -> Element Msg
menu device { example } =
    let
        selected =
            case example of
                ManageSocketHeartbeat _ ->
                    "Manage The Socket Heartbeat"

                ManageChannelMessages _ ->
                    "Manage Channel Messages"

                ManagePresenceMessages _ ->
                    "Manage Presence Messages"
    in
    Menu.init
        |> Menu.options
            [ "Manage The Socket Heartbeat"
            , "Manage Channel Messages"
            , "Manage Presence Messages"
            ]
        |> Menu.selected selected
        |> Menu.onClick (Just GotMenuItem)
        |> Menu.group
            (Group.init
                |> Group.layouts
                    [ ( Phone, Landscape, [ 1, 2 ] )
                    , ( Tablet, Portrait, [ 1, 2 ] )
                    ]
            )
        |> Menu.view device


{-| Example Description
-}
description : Model -> List (Element msg)
description { example, maybeExampleId } =
    case example of
        ManagePresenceMessages _ ->
            [ UI.paragraph
                [ El.text "Choose whether to receive Presence messages as an incoming Socket message. "
                , El.text "To get the best out of this example, you should open it in mulitple tabs. Click "
                , El.newTabLink
                    [ Font.color Color.dodgerblue
                    , El.mouseOver
                        [ Font.color Color.lavender ]
                    ]
                    { url =
                        case maybeExampleId of
                            Just id ->
                                "/HandleSocketMessages?example=ManagePresenceMessages&id=" ++ id

                            Nothing ->
                                "/HandleSocketMessages?example=ManagePresenceMessages"
                    , label = El.text "here"
                    }
                , El.text " to open a new tab(s). You will then be able to control each tab from whichever tab you are in."
                ]
            ]

        _ ->
            []



{- Example -}


viewExample : Model -> Element Msg
viewExample { example } =
    case example of
        ManageSocketHeartbeat subModel ->
            ManageSocketHeartbeat.view subModel
                |> El.map GotManageSocketHeartbeatMsg

        ManageChannelMessages subModel ->
            ManageChannelMessages.view subModel
                |> El.map GotManageChannelMessagesMsg

        ManagePresenceMessages subModel ->
            ManagePresenceMessages.view subModel
                |> El.map GotManagePresenceMessagesMsg
