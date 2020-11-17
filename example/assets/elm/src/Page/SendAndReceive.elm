module Page.SendAndReceive exposing
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
import Element as El exposing (DeviceClass(..), Element, Orientation(..))
import Example.PushMultipleEvents as PushMultipleEvents
import Example.PushOneEvent as PushOneEvent
import Example.ReceiveEvents as ReceiveEvents
import Phoenix
import Route
import Session exposing (Session)
import View.Example.Menu as Menu
import View.Example.Page as ExamplePage
import View.Group as Group
import View.Layout as Layout



{- Init -}


init : Session -> ( Model, Cmd Msg )
init session =
    ( { session = session
      , example =
            PushOneEvent <|
                PushOneEvent.init
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
    = PushOneEvent PushOneEvent.Model
    | PushMultipleEvents PushMultipleEvents.Model
    | ReceiveEvents ReceiveEvents.Model



{- Update -}


type Msg
    = GotHomeBtnClick
    | GotMenuItem String
    | GotPhoenixMsg Phoenix.Msg
    | GotPushOneEventMsg PushOneEvent.Msg
    | GotPushMultipleEventsMsg PushMultipleEvents.Msg
    | GotReceiveEventsMsg ReceiveEvents.Msg


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

        ( GotMenuItem example, _ ) ->
            Phoenix.disconnectAndReset Nothing phoenix
                |> updatePhoenix model
                |> updateExample example

        ( GotPhoenixMsg subMsg, _ ) ->
            Phoenix.update subMsg phoenix
                |> updatePhoenix model

        ( GotPushOneEventMsg subMsg, PushOneEvent subModel ) ->
            PushOneEvent.update subMsg subModel
                |> updateWith PushOneEvent GotPushOneEventMsg model

        ( GotPushMultipleEventsMsg subMsg, PushMultipleEvents subModel ) ->
            PushMultipleEvents.update subMsg subModel
                |> updateWith PushMultipleEvents GotPushMultipleEventsMsg model

        ( GotReceiveEventsMsg subMsg, ReceiveEvents subModel ) ->
            ReceiveEvents.update subMsg subModel
                |> updateWith ReceiveEvents GotReceiveEventsMsg model

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
    let
        example_ =
            case selectedExample of
                "Push One Event" ->
                    PushOneEvent <|
                        PushOneEvent.init
                            (Session.phoenix model.session)

                "Push Multiple Events" ->
                    PushMultipleEvents <|
                        PushMultipleEvents.init
                            (Session.phoenix model.session)

                "Receive Events" ->
                    ReceiveEvents <|
                        ReceiveEvents.init
                            (Session.phoenix model.session)

                _ ->
                    PushOneEvent <|
                        PushOneEvent.init
                            (Session.phoenix model.session)
    in
    ( { model
        | example = example_
      }
    , cmd
    )



{- Subscriptions -}


subscriptions : Model -> Sub Msg
subscriptions model =
    let
        exampleSub =
            case model.example of
                PushOneEvent subModel ->
                    Sub.map GotPushOneEventMsg <|
                        PushOneEvent.subscriptions subModel

                PushMultipleEvents subModel ->
                    Sub.map GotPushMultipleEventsMsg <|
                        PushMultipleEvents.subscriptions subModel

                ReceiveEvents subModel ->
                    Sub.map GotReceiveEventsMsg <|
                        ReceiveEvents.subscriptions subModel
    in
    Sub.batch
        [ exampleSub
        , Sub.map GotPhoenixMsg <|
            Phoenix.subscriptions (Session.phoenix model.session)
        ]



{- Session -}


toSession : Model -> Session
toSession model =
    model.session


updateSession : Session -> Model -> Model
updateSession session model =
    { model | session = session }



{- View -}


view : Model -> { title : String, content : Element Msg }
view model =
    let
        device =
            Session.device model.session
    in
    { title = "Send And Receive"
    , content =
        Layout.init
            |> Layout.homeMsg (Just GotHomeBtnClick)
            |> Layout.title "Send And Receive"
            |> Layout.body
                (ExamplePage.init
                    |> ExamplePage.introduction introduction
                    |> ExamplePage.menu (menu device model)
                    |> ExamplePage.example (viewExample device model)
                    |> ExamplePage.view device
                )
            |> Layout.view device
    }



{- Introduction -}


introduction : List (List (Element Msg))
introduction =
    [ [ El.text "You can push to a Channel without needing to connect to the Socket or join "
      , El.text "the Channel. These processes will be taken care of automatically when you send the push."
      ]
    , [ El.text "Clicking on a function will take you to its documentation." ]
    ]



{- Menu -}


menu : Device -> Model -> Element Msg
menu device { example } =
    let
        selected =
            case example of
                PushOneEvent _ ->
                    "Push One Event"

                PushMultipleEvents _ ->
                    "Push Multiple Events"

                ReceiveEvents _ ->
                    "Receive Events"
    in
    Menu.init
        |> Menu.options
            [ "Push One Event"
            , "Push Multiple Events"
            , "Receive Events"
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



{- Example -}


viewExample : Device -> Model -> Element Msg
viewExample device { example } =
    case example of
        PushOneEvent subModel ->
            PushOneEvent.view device subModel
                |> El.map GotPushOneEventMsg

        PushMultipleEvents subModel ->
            PushMultipleEvents.view device subModel
                |> El.map GotPushMultipleEventsMsg

        ReceiveEvents subModel ->
            ReceiveEvents.view device subModel
                |> El.map GotReceiveEventsMsg
