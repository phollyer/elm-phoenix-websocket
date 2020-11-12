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
import View.Rooms as Rooms
import View.Username as Username



{- Init -}


init : Phoenix.Model -> Model
init phoenix =
    { phoenix = phoenix
    , state = InLobby Unregistered
    , username = ""
    , presences = []
    , rooms = []
    }



{- Model -}


type alias Model =
    { phoenix : Phoenix.Model
    , state : State
    , username : String
    , presences : List Presence
    , rooms : List Room
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


type alias Room =
    { id : String
    , owner : User
    , messages : List Message
    }


type alias Message =
    { id : String
    , text : String
    , owner : User
    }


joinConfig : Phoenix.JoinConfig
joinConfig =
    { topic = ""
    , events = []
    , payload = JE.null
    , timeout = Nothing
    }


pushConfig : Phoenix.Push
pushConfig =
    { topic = ""
    , event = ""
    , payload = JE.null
    , retryStrategy = Phoenix.Drop
    , timeout = Nothing
    , ref = Nothing
    }



{- Update -}


type Msg
    = GotUsernameChange String
    | GotSubmitUsername
    | GotNewRoomBtnClick
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

        GotNewRoomBtnClick ->
            Phoenix.push
                { pushConfig
                    | topic = "example:lobby"
                    , event = "create_room"
                }
                model.phoenix
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
                                    ( userRegisteredOk user newModel, cmd )

                                Err _ ->
                                    ( newModel, cmd )

                        _ ->
                            ( newModel, cmd )

                Phoenix.ChannelEvent topic event payload ->
                    case ( topic, event ) of
                        ( "example:lobby", "room_list" ) ->
                            case decodeRooms payload of
                                Ok rooms ->
                                    ( { newModel | rooms = rooms }, cmd )

                                Err _ ->
                                    ( newModel, cmd )

                        ( "example:lobby", "new_room_created" ) ->
                            case decodeRoom payload of
                                Ok room ->
                                    ( { newModel | rooms = room :: model.rooms }, cmd )

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
                , events =
                    [ "room_list"
                    , "new_room_created"
                    ]
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


decodeMessage : Value -> Result JD.Error Message
decodeMessage payload =
    JD.decodeValue messageDecoder payload


messageDecoder : JD.Decoder Message
messageDecoder =
    JD.succeed
        Message
        |> andMap (JD.field "id" JD.string)
        |> andMap (JD.field "text" JD.string)
        |> andMap (JD.field "owner" userDecoder)


decodeRooms : Value -> Result JD.Error (List Room)
decodeRooms payload =
    JD.decodeValue roomsDecoder payload


roomsDecoder : JD.Decoder (List Room)
roomsDecoder =
    JD.succeed
        identity
        |> andMap (JD.field "rooms" (JD.list roomDecoder))


decodeRoom : Value -> Result JD.Error Room
decodeRoom payload =
    JD.decodeValue roomDecoder payload


roomDecoder : JD.Decoder Room
roomDecoder =
    JD.succeed
        Room
        |> andMap (JD.field "id" JD.string)
        |> andMap (JD.field "owner" userDecoder)
        |> andMap (JD.field "messages" (JD.list messageDecoder))



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
                |> Lobby.newRoomBtn
                    (Button.init
                        |> Button.label "New Room"
                        |> Button.onPress (Just GotNewRoomBtnClick)
                        |> Button.enabled True
                        |> Button.view device
                    )
                |> Lobby.members
                    (LobbyMembers.init
                        |> LobbyMembers.members
                            (toUsers model.presences)
                        |> LobbyMembers.view device
                    )
                |> Lobby.rooms
                    (Rooms.init
                        |> Rooms.list model.rooms
                        |> Rooms.view device
                    )
                |> Lobby.view device


toUsers : List Presence -> List User
toUsers presences =
    List.map .user presences
        |> List.sortBy .username
