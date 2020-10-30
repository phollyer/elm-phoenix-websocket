module Page.SendAndReceive exposing (..)

import Element as El exposing (Element)
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


updateSession : Session -> Model -> Model
updateSession session model =
    { model | session = session }


type alias Model =
    { session : Session }


type Msg
    = GotPhoenixMsg Phoenix.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.map GotPhoenixMsg <|
        Phoenix.subscriptions (Session.phoenix model.session)


view : Model -> { title : String, content : Element Msg }
view model =
    { title = ""
    , content = El.none
    }
