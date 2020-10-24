module Page.Home exposing
    ( Model
    , Msg
    , init
    , toSession
    , update
    , updateSession
    , view
    )

import Colors.Opaque as Color
import Element as El exposing (Device, Element)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Event
import Element.Font as Font
import Phoenix
import Route exposing (Route(..))
import Session exposing (Session)
import View.Home as Home
import View.Home.Panel as Panel
import View.Layout as Layout


init : Session -> ( Model, Cmd Msg )
init session =
    ( { session = session }
    , Cmd.none
    )


type alias Model =
    { session : Session }


type Msg
    = PhoenixMsg Phoenix.Msg
    | NavigateTo Route


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        PhoenixMsg phoenixMsg ->
            ( model, Cmd.none )

        NavigateTo route ->
            ( model
            , Route.pushUrl (Session.navKey model.session) route
            )


toSession : Model -> Session
toSession model =
    model.session


toDevice : Model -> Device
toDevice model =
    Session.device model.session


updateSession : Session -> Model -> Model
updateSession session model =
    { model | session = session }


view : Model -> { title : String, content : Element Msg }
view model =
    let
        device =
            toDevice model
    in
    { title = "Home"
    , content =
        Layout.init
            |> Layout.title "Elm-Phoenix-WebSocket Examples"
            |> Layout.body
                (Home.init
                    |> Home.socket (socketExamples device)
                    |> Home.channels channelsExamples
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
        |> Panel.onClick (Just (NavigateTo (HandleSocketMessages Nothing Nothing)))
        |> Panel.view device
    ]


channelsExamples : List (Element msg)
channelsExamples =
    []


presenceExamples : List (Element msg)
presenceExamples =
    []
