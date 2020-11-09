module Example.MultiRoomChat exposing
    ( Model
    , Msg
    , init
    , update
    , view
    )

import Element as El exposing (Device, Element)
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

        _ ->
            ( model, Cmd.none )



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
