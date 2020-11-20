module Page.ChatRooms exposing
    ( Model
    , Msg
    , init
    , subscriptions
    , toSession
    , update
    , updateSession
    , view
    )

import Device exposing (Device)
import Element as El exposing (Element)
import Example.MultiRoomChat as MultiRoomChat
import Phoenix
import Session exposing (Session)
import View.Example.Page as ExamplePage
import View.Layout as Layout



{- Init -}


init : Session -> ( Model, Cmd Msg )
init session =
    ( { session = session
      , example =
            MultiRoom <|
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
    = MultiRoom MultiRoomChat.Model



{- Update -}


type Msg
    = GotBackBtnClick
    | GotMultiRoomMsg MultiRoomChat.Msg
    | GotPhoenixMsg Phoenix.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        phoenix =
            Session.phoenix model.session
    in
    case ( msg, model.example ) of
        ( GotBackBtnClick, MultiRoom subModel ) ->
            MultiRoomChat.back (Session.navKey model.session) subModel
                |> updateWith MultiRoom GotMultiRoomMsg model

        ( GotPhoenixMsg subMsg, _ ) ->
            Phoenix.update subMsg phoenix
                |> updatePhoenix model

        ( GotMultiRoomMsg subMsg, MultiRoom subModel ) ->
            MultiRoomChat.update subMsg subModel
                |> updateWith MultiRoom GotMultiRoomMsg model


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
    case model.example of
        MultiRoom subModel ->
            Sub.batch
                [ Sub.map GotPhoenixMsg <|
                    Phoenix.subscriptions
                        (Session.phoenix model.session)
                , Sub.map GotMultiRoomMsg <|
                    MultiRoomChat.subscriptions subModel
                ]



{- View -}


view : Model -> { title : String, content : Element Msg }
view model =
    let
        device =
            Session.device model.session
    in
    { title = "Chat Rooms Example"
    , content =
        Layout.init
            |> Layout.homeMsg (Just GotBackBtnClick)
            |> Layout.title "Chat Rooms Example"
            |> Layout.body
                (ExamplePage.init
                    |> ExamplePage.example (viewExample device model)
                    |> ExamplePage.view device
                )
            |> Layout.view device
    }



{- Example -}


viewExample : Device -> Model -> Element Msg
viewExample device { example } =
    case example of
        MultiRoom subModel ->
            MultiRoomChat.view device subModel
                |> El.map GotMultiRoomMsg
