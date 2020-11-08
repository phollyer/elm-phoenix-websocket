module Page.ChatRooms exposing
    ( Model
    , Msg
    , init
    , subscriptions
    , toSession
    , updateSession
    , view
    )

import Element as El exposing (Element)
import Example.MultiRoomChat as MultiRoomChat
import Phoenix
import Session exposing (Session)



{- Init -}


init : Session -> ( Model, Cmd Msg )
init session =
    ( { session = session
      , example =
            Multiroom <|
                MultiRoomChat.init
                    (Session.phoenix session)
      }
    , Cmd.none
    )



{- Model -}


type alias Model =
    { session : Session
    , example : Example
    }


type Example
    = Multiroom MultiRoomChat.Model



{- Update -}


type Msg
    = PhoenixMsg Phoenix.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.none )



{- Session -}


toSession : Model -> Session
toSession model =
    model.session


updateSession : Session -> Model -> Model
updateSession session model =
    { model | session = session }



{- Subscriptions -}


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.map PhoenixMsg <|
        Phoenix.subscriptions
            (Session.phoenix model.session)



{- View -}


view : Model -> { title : String, content : Element Msg }
view model =
    { title = ""
    , content = El.none
    }
