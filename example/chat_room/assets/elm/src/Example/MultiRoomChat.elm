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
import Json.Decode as JD
import Json.Decode.Extra exposing (andMap)
import Json.Encode as JE exposing (Value)
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
    , state = InLobby Unregistered
    , username = ""
    }



{- Model -}


type alias Model =
    { phoenix : Phoenix.Model
    , state : State
    , username : String
    }


type State
    = InLobby LobbyState


type LobbyState
    = Unregistered
    | Registered User


type alias User =
    { id : String
    , username : String
    }


joinConfig : Phoenix.JoinConfig
joinConfig =
    { topic = ""
    , events = []
    , payload = JE.null
    , timeout = Nothing
    }



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
            joinLobby model
                |> updatePhoenixWith PhoenixMsg model

        PhoenixMsg subMsg ->
            let
                ( newModel, cmd ) =
                    Phoenix.update subMsg model.phoenix
                        |> updatePhoenixWith PhoenixMsg model
            in
            case Phoenix.phoenixMsg newModel.phoenix of
                Phoenix.ChannelResponse (Phoenix.JoinOk topic payload) ->
                    case topic of
                        "example:lobby" ->
                            case decodeUser payload of
                                Ok user ->
                                    ( userRegisteredOk user newModel
                                    , cmd
                                    )

                                Err _ ->
                                    ( newModel, cmd )

                        _ ->
                            ( newModel, cmd )

                _ ->
                    ( newModel, cmd )


userRegisteredOk : User -> Model -> Model
userRegisteredOk user model =
    { model | state = InLobby (Registered user) }


joinLobby : Model -> ( Phoenix.Model, Cmd Phoenix.Msg )
joinLobby model =
    model.phoenix
        |> Phoenix.setJoinConfig
            { joinConfig
                | topic = "example:lobby"
                , payload =
                    JE.object
                        [ ( "username", JE.string (String.trim model.username) ) ]
            }
        |> Phoenix.join "example:lobby"



{- Decoders -}


decodeUser : Value -> Result JD.Error User
decodeUser payload =
    JD.decodeValue userDecoder payload


userDecoder : JD.Decoder User
userDecoder =
    JD.succeed
        User
        |> andMap (JD.field "id" JD.string)
        |> andMap (JD.field "username" JD.string)



{- Subscriptions -}


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.map PhoenixMsg <|
        Phoenix.subscriptions model.phoenix



{- View -}


view : Device -> Model -> Element Msg
view device model =
    case model.state of
        InLobby Unregistered ->
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

        _ ->
            El.none
