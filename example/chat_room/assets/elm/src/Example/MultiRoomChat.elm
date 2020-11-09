module Example.MultiRoomChat exposing
    ( Model
    , Msg
    , init
    , subscriptions
    , update
    , view
    )

import Element as El exposing (Device, Element)
import Example.Utils exposing (updatePhoenixWith)
import Json.Encode as JE
import Phoenix
import UI
import View.Button as Button
import View.Lobby as Lobby
import View.LobbyForm as LobbyForm
import View.Username as Username



{- Init -}


init : Phoenix.Model -> Model
init phoenix =
    { phoenix = phoenix
    , state = InLobby
    , username = ""
    }



{- Model -}


type alias Model =
    { phoenix : Phoenix.Model
    , state : State
    , username : String
    }


type State
    = InLobby



{- Update -}


type Msg
    = GotUsernameChange String
    | GotSubmitUsername
    | PhoenixMsg Phoenix.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotUsernameChange name ->
            ( { model | username = name }
            , Cmd.none
            )

        GotSubmitUsername ->
            model.phoenix
                |> Phoenix.setJoinConfig
                    { topic = "example:lobby"
                    , payload =
                        JE.object
                            [ ( "username", JE.string model.username ) ]
                    , events = []
                    , timeout = Nothing
                    }
                |> Phoenix.join "example:lobby"
                |> updatePhoenixWith PhoenixMsg model

        PhoenixMsg subMsg ->
            Phoenix.update subMsg model.phoenix
                |> updatePhoenixWith PhoenixMsg model



{- Subscriptions -}


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.map PhoenixMsg <|
        Phoenix.subscriptions model.phoenix



{- View -}


view : Device -> Model -> Element Msg
view device model =
    case model.state of
        InLobby ->
            Lobby.init
                |> Lobby.introduction
                    [ [ El.text "Welcome, to the Lobby." ]
                    , [ El.text "Enter a username in order to join or create a room." ]
                    ]
                |> Lobby.form
                    (LobbyForm.init
                        |> LobbyForm.usernameInput
                            (Username.init
                                |> Username.value model.username
                                |> Username.onChange GotUsernameChange
                                |> Username.view device
                            )
                        |> LobbyForm.submitBtn
                            (Button.init
                                |> Button.label "Submit"
                                |> Button.onPress (Just GotSubmitUsername)
                                |> Button.enabled (String.trim model.username /= "")
                                |> Button.view device
                            )
                        |> LobbyForm.view device
                    )
                |> Lobby.view device
