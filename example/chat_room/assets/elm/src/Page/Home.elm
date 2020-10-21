module Page.Home exposing
    ( Model
    , Msg
    , init
    , toSession
    , update
    , view
    )

import Colors.Opaque as Color
import Element as El exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Event
import Element.Font as Font
import Phoenix
import Route exposing (Route(..))
import Session exposing (Session)
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


view : Model -> { title : String, content : Element Msg }
view model =
    { title = "Home"
    , content =
        Layout.init
            |> Layout.title "Elm-Phoenix-WebSocket Examples"
            |> Layout.column
                [ socket
                , channels
                , presence
                ]
            |> Layout.render Layout.Home
    }


socket : Element Msg
socket =
    El.column
        [ El.spacing 10
        , El.width El.fill
        ]
        [ El.el
            [ Font.size 30
            , Font.color Color.slateblue
            ]
            (El.text "Socket")
        , socketExamples
        ]


socketExamples : Element Msg
socketExamples =
    El.row
        [ El.width El.fill
        , El.spacing 10
        , El.padding 5
        ]
    <|
        List.map panel <|
            [ { title = "Control the Connection"
              , description =
                    [ "Manually connect and disconnect, receiving feedback on the current state of the Socket." ]
              , route = ControlTheSocketConnection
              }
            , { title = "Handle Socket Messages"
              , description =
                    [ "Manage the heartbeat, Channel and Presence messages that come in from the Socket." ]
              , route = HandleSocketMessages Nothing Nothing
              }
            ]


channels : Element msg
channels =
    El.column
        [ El.width El.fill ]
        [ El.el
            [ Font.size 30
            , Font.color Color.slateblue
            ]
            (El.text "Channels")
        ]


presence : Element msg
presence =
    El.column
        [ El.width El.fill ]
        [ El.el
            [ Font.size 30
            , Font.color Color.slateblue
            ]
            (El.text "Presence")
        ]


panel : { title : String, description : List String, route : Route } -> Element Msg
panel { title, description, route } =
    El.column
        [ Background.color Color.steelblue
        , Border.rounded 20
        , Border.width 1
        , Border.color Color.steelblue
        , El.height <|
            El.maximum 300 El.fill
        , El.width <| El.px 250
        , El.clip
        , El.pointer
        , El.mouseOver
            [ Border.shadow
                { size = 2
                , blur = 3
                , color = Color.steelblue
                , offset = ( 0, 0 )
                }
            ]
        , Event.onClick (NavigateTo route)
        ]
        [ El.el
            [ Background.color Color.steelblue
            , Border.roundEach
                { topLeft = 20
                , topRight = 20
                , bottomRight = 0
                , bottomLeft = 0
                }
            , El.paddingXY 5 10
            , El.width El.fill
            , Font.color Color.aliceblue
            , Font.size 20
            ]
            (El.paragraph
                [ El.width El.fill
                , Font.center
                ]
                [ El.text title ]
            )
        , El.column
            [ Background.color Color.lightskyblue
            , El.height El.fill
            , El.width El.fill
            , El.padding 10
            , El.spacing 10
            ]
            (List.map
                (\para ->
                    El.paragraph
                        [ El.width El.fill
                        , Font.justify
                        , Font.size 16
                        ]
                        [ El.text para ]
                )
                description
            )
        ]
