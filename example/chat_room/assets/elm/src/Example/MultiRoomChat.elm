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
import View.LobbyMembers as LobbyMembers
import View.LobbyUser as LobbyUser
import View.Username as Username



{- Init -}


init : Phoenix.Model -> Model
init phoenix =
    { phoenix = phoenix
    , state = InLobby Unregistered
    , username = ""
    , presences = []
    }



{- Model -}


type alias Model =
    { phoenix : Phoenix.Model
    , state : State
    , username : String
    , presences : List Presence
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


type alias Presence =
    { id : String
    , metas : List Meta
    , user : User
    }


type alias Meta =
    { online_at : String
    , device : String
    }


type alias RoomID =
    String


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
                                    , Cmd.batch
                                        [ cmd
                                        , retrieveRoomList newModel.phoenix
                                        ]
                                    )

                                Err _ ->
                                    ( newModel, cmd )

                        _ ->
                            ( newModel, cmd )

                Phoenix.PresenceEvent (Phoenix.State topic state) ->
                    case topic of
                        "example:lobby" ->
                            ( { newModel | presences = toPresences state }, cmd )

                        _ ->
                            ( newModel, cmd )

                _ ->
                    ( newModel, cmd )


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


userRegisteredOk : User -> Model -> Model
userRegisteredOk user model =
    { model | state = InLobby (Registered user) }


toPresences : List Phoenix.Presence -> List Presence
toPresences presences =
    List.map
        (\presence ->
            { id = presence.id
            , metas = decodeMetas presence.metas
            , user =
                decodeUser presence.user
                    |> Result.toMaybe
                    |> Maybe.withDefault
                        (User "" "")
            }
        )
        presences


retrieveRoomList : Phoenix.Model -> Cmd Msg
retrieveRoomList phoenix =
    Cmd.none



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


decodeMetas : List Value -> List Meta
decodeMetas metas =
    List.map
        (\meta ->
            JD.decodeValue metaDecoder meta
                |> Result.toMaybe
                |> Maybe.withDefault (Meta "" "")
        )
        metas


metaDecoder : JD.Decoder Meta
metaDecoder =
    JD.succeed
        Meta
        |> andMap (JD.field "online_at" JD.string)
        |> andMap (JD.field "device" JD.string)



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

        InLobby (Registered user) ->
            Lobby.init
                |> Lobby.user
                    (LobbyUser.init
                        |> LobbyUser.username user.username
                        |> LobbyUser.userId user.id
                        |> LobbyUser.view device
                    )
                |> Lobby.members
                    (LobbyMembers.init
                        |> LobbyMembers.members
                            (toUsers model.presences)
                        |> LobbyMembers.view device
                    )
                |> Lobby.view device


toUsers : List Presence -> List User
toUsers presences =
    List.map .user presences
        |> List.sortBy .username
