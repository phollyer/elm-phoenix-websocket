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
import Element as El exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Event
import Element.Font as Font
import Phoenix
import Route exposing (Route(..))
import Session exposing (Session)
import View.Home as Home
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


updateSession : Session -> Model -> Model
updateSession session model =
    { model | session = session }


view : Model -> { title : String, content : Element Msg }
view model =
    { title = "Home"
    , content =
        Layout.init
            |> Layout.title "Elm-Phoenix-WebSocket Examples"
            |> Layout.body
                (Home.init
                    |> Home.socket socketExamples
                    |> Home.channels channelsExamples
                    |> Home.presence presenceExamples
                    |> Home.render Home.Default
                )
            |> Layout.render Layout.Home
    }


socketExamples : List (Element Msg)
socketExamples =
    List.map panel <|
        [ { title = "Control the Connection"
          , description =
                [ "Manually connect and disconnect, receiving feedback on the current state of the Socket." ]
          , onClick = NavigateTo ControlTheSocketConnection
          }
        , { title = "Handle Socket Messages"
          , description =
                [ "Manage the heartbeat, Channel and Presence messages that come in from the Socket." ]
          , onClick = NavigateTo (HandleSocketMessages Nothing Nothing)
          }
        ]


channelsExamples : List (Element msg)
channelsExamples =
    []


presenceExamples : List (Element msg)
presenceExamples =
    []


panel : { title : String, description : List String, onClick : Msg } -> Element Msg
panel { title, description, onClick } =
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
        , Event.onClick onClick
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
