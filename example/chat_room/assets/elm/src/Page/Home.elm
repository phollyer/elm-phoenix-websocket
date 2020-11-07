module Page.Home exposing
    ( Model
    , Msg
    , init
    , subscriptions
    , toSession
    , update
    , updateSession
    , view
    )

import Element exposing (Device, Element)
import Phoenix
import Route exposing (Route(..))
import Session exposing (Session)
import View.Home as Home
import View.Layout as Layout
import View.Panel as Panel


init : Session -> ( Model, Cmd Msg )
init session =
    let
        ( phx, phxCmd ) =
            Phoenix.disconnectAndReset Nothing <|
                Session.phoenix session
    in
    ( Session.updatePhoenix phx session
    , Cmd.map PhoenixMsg phxCmd
    )


type alias Model =
    Session


type Msg
    = PhoenixMsg Phoenix.Msg
    | NavigateTo Route


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        PhoenixMsg phoenixMsg ->
            let
                ( phx, phxCmd ) =
                    Phoenix.update phoenixMsg <|
                        Session.phoenix model
            in
            ( Session.updatePhoenix phx model
            , Cmd.map PhoenixMsg phxCmd
            )

        NavigateTo route ->
            ( model
            , Route.pushUrl (Session.navKey model) route
            )


toSession : Model -> Session
toSession model =
    model


updateSession : Session -> Model
updateSession session =
    session


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.map PhoenixMsg <|
        Phoenix.subscriptions
            (Session.phoenix model)


view : Device -> { title : String, content : Element Msg }
view device =
    { title = "Home"
    , content =
        Layout.init
            |> Layout.title "Elm-Phoenix-WebSocket Examples"
            |> Layout.body
                (Home.init
                    |> Home.socket (socketExamples device)
                    |> Home.channels (channelsExamples device)
                    |> Home.presence presenceExamples
                    |> Home.view device
                )
            |> Layout.view device
    }


socketExamples : Device -> List (Element Msg)
socketExamples device =
    [ Panel.init
        |> Panel.title "Control the Connection"
        |> Panel.description
            [ "Manually connect and disconnect, receiving feedback on the current state of the Socket." ]
        |> Panel.onClick (Just (NavigateTo ControlTheSocketConnection))
        |> Panel.view device
    , Panel.init
        |> Panel.title "Handle Socket Messages"
        |> Panel.description
            [ "Manage the heartbeat, Channel and Presence messages that come in from the Socket." ]
        |> Panel.onClick (Just (NavigateTo HandleSocketMessages))
        |> Panel.view device
    ]


channelsExamples : Device -> List (Element Msg)
channelsExamples device =
    [ Panel.init
        |> Panel.title "Joining and Leaving"
        |> Panel.description
            [ "Manually join and leave one or more Channels." ]
        |> Panel.onClick (Just (NavigateTo JoinAndLeaveChannels))
        |> Panel.view device
    , Panel.init
        |> Panel.title "Sending and Receiving"
        |> Panel.description
            [ "Send and receive events to and from one or more Channels." ]
        |> Panel.onClick (Just (NavigateTo SendAndReceive))
        |> Panel.view device
    ]


presenceExamples : List (Element msg)
presenceExamples =
    []
