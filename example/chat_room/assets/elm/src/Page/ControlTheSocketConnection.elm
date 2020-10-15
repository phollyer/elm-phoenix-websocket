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
import Element.Font as Font
import Element.Input as Input
import Example exposing (Action(..), Example(..))
import Page
import Phoenix
import Session exposing (Session)



{- Init -}


init : Session -> ( Model, Cmd Msg )
init session =
    ( { session = session
      , example = SimpleConnect Connect
      }
    , Cmd.none
    )



{- Model -}


type alias Model =
    { session : Session
    , example : Example
    }



{- Update -}


type Msg
    = GotButtonClick Example
    | GotButtonEnter Example
    | GotPhoenixMsg Phoenix.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        phoenix =
            Session.phoenix model.session
    in
    case msg of
        GotButtonClick example ->
            case example of
                SimpleConnect action ->
                    case action of
                        Connect ->
                            Phoenix.connect phoenix
                                |> updatePhoenix model

                        Disconnect ->
                            Phoenix.disconnect phoenix
                                |> updatePhoenix model

                        _ ->
                            ( model, Cmd.none )

                ConnectWithParams action ->
                    case action of
                        Connect ->
                            Phoenix.connect phoenix
                                |> updatePhoenix model

                        Disconnect ->
                            Phoenix.disconnect phoenix
                                |> updatePhoenix model

                        _ ->
                            ( model, Cmd.none )

        GotButtonEnter example ->
            ( model, Cmd.none )

        GotPhoenixMsg subMsg ->
            Phoenix.update subMsg phoenix
                |> updatePhoenix model


updatePhoenix : Model -> ( Phoenix.Model, Cmd Phoenix.Msg ) -> ( Model, Cmd Msg )
updatePhoenix model ( phoenix, phoenixCmd ) =
    ( { model
        | session = Session.updatePhoenix phoenix model.session
      }
    , Cmd.map GotPhoenixMsg phoenixCmd
    )



{- View -}


view : Model -> { title : String, content : Element Msg }
view model =
    let
        phoenix =
            Session.phoenix model.session
    in
    { title = "Control The Socket Connection"
    , content =
        Page.container
            [ Page.header "Control The Socket Connection"
            , Example.view
                (Example.description <| description SimpleConnect)
                (buttons model.example phoenix)
                El.none
                El.none
            ]
    }


description : (Action -> Example) -> List (Element msg)
description example =
    case example Anything of
        SimpleConnect _ ->
            [ Page.paragraph
                [ El.text "It is not neccessary to manually connect to the Socket because this is taken care of automatically when a request to join a Channel is made, or when a Channel is pushed to." ]
            , Page.paragraph
                [ El.text "If you want to take manual control, this is how." ]
            ]

        ConnectWithParams _ ->
            [ Page.paragraph
                [ El.text "If you want to take manual control, this is how." ]
            ]


buttons : Example -> Phoenix.Model -> Element Msg
buttons example phoenix =
    case example of
        SimpleConnect _ ->
            simpleConnectButtons example phoenix

        ConnectWithParams _ ->
            connectWithParamsButtons example phoenix


simpleConnectButtons : Example -> Phoenix.Model -> Element Msg
simpleConnectButtons example phoenix =
    El.row
        [ El.width El.fill
        , El.height <| El.px 60
        , El.spacing 20
        ]
        [ El.el
            [ El.width El.fill
            , El.centerY
            ]
            (El.el
                [ El.alignRight ]
                (connectButton example SimpleConnect phoenix)
            )
        , El.el
            [ El.width El.fill
            , El.centerY
            ]
            (El.el
                [ El.alignLeft ]
                (disconnectButton example SimpleConnect phoenix)
            )
        ]


connectWithParamsButtons : Example -> Phoenix.Model -> Element Msg
connectWithParamsButtons current phoenix =
    El.row
        [ El.width El.fill
        , El.height <| El.px 60
        , El.spacing 20
        ]
        [ El.el
            [ El.width El.fill
            , El.centerY
            ]
            (El.el
                [ El.alignRight ]
                (connectButton current ConnectWithParams phoenix)
            )
        , El.el
            [ El.width El.fill
            , El.centerY
            ]
            (El.el
                [ El.alignLeft ]
                (disconnectButton current ConnectWithParams phoenix)
            )
        ]


connectButton : Example -> (Action -> Example) -> Phoenix.Model -> Element Msg
connectButton example exampleFunc phoenix =
    Page.button
        { label = "Connect"
        , example = exampleFunc Connect
        , onPress = GotButtonEnter
        , onEnter = GotButtonClick
        , enabled =
            case Phoenix.socketState phoenix of
                Phoenix.Disconnected _ ->
                    example == exampleFunc Connect

                _ ->
                    False
        }


disconnectButton : Example -> (Action -> Example) -> Phoenix.Model -> Element Msg
disconnectButton current exampleFunc phoenix =
    Page.button
        { label = "Disconnect"
        , example = exampleFunc Disconnect
        , onPress = GotButtonEnter
        , onEnter = GotButtonClick
        , enabled = Phoenix.socketState phoenix == Phoenix.Connected && current == exampleFunc Connect
        }



{- Subscriptions -}


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.map GotPhoenixMsg <|
        Phoenix.subscriptions (Session.phoenix model.session)



{- Session -}


toSession : Model -> Session
toSession model =
    model.session
