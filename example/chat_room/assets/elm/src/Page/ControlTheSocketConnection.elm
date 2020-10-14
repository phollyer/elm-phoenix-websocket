module Page.ControlTheSocketConnection exposing
    ( Model
    , Msg
    , init
    , subscriptions
    , toSession
    , update
    , view
    )

import Element as El exposing (Element)
import Element.Input as Input
import Page
import Phoenix
import Session exposing (Session)


init : Session -> ( Model, Cmd Msg )
init session =
    ( { session = session }
    , Cmd.none
    )


toSession : Model -> Session
toSession model =
    model.session


type alias Model =
    { session : Session }


type Action
    = Connect
    | Disconnect


type Msg
    = GotButtonClick Action
    | GotPhoenixMsg Phoenix.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotButtonClick action ->
            let
                phoenix =
                    Session.phoenix model.session
            in
            case action of
                Connect ->
                    let
                        ( phx, phxCmd ) =
                            Phoenix.connect phoenix
                    in
                    ( { model
                        | session = Session.updatePhoenix phoenix model.session
                      }
                    , Cmd.map GotPhoenixMsg phxCmd
                    )

                Disconnect ->
                    ( model
                    , Cmd.map GotPhoenixMsg (Phoenix.disconnect phoenix)
                    )

        GotPhoenixMsg subMsg ->
            let
                ( phoenix, phoenixCmd ) =
                    Phoenix.update subMsg (Session.phoenix model.session)
            in
            ( { model
                | session = Session.updatePhoenix phoenix model.session
              }
            , Cmd.map GotPhoenixMsg phoenixCmd
            )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.map GotPhoenixMsg <|
        Phoenix.subscriptions (Session.phoenix model.session)


view : Model -> { title : String, content : Element Msg }
view _ =
    { title = "Control The Socket Connection"
    , content =
        Page.container
            [ Page.header "Control The Socket Connection"
            , controlButtons
            ]
    }


controlButtons : Element Msg
controlButtons =
    El.row
        [ El.width El.fill
        , El.spacing 20
        ]
        [ Input.button
            [ El.centerX ]
            { label = El.text "Connect"
            , onPress = Just (GotButtonClick Connect)
            }
        , Input.button
            [ El.centerX ]
            { label = El.text "Disconnect"
            , onPress = Just (GotButtonClick Disconnect)
            }
        ]
