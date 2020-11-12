module Example.MultiRoomChat exposing
    ( Model
    , Msg
    , init
    , subscriptions
    , update
    , view
    )

import Configs exposing (joinConfig, pushConfig)
import Element as El exposing (Device, Element)
import Example.Utils exposing (updatePhoenixWith)
import Json.Decode as JD
import Json.Decode.Extra exposing (andMap)
import Json.Encode as JE exposing (Value)
import Phoenix
import Types exposing (Message, Room, User, decodeMessage, decodeRooms, decodeUser)
import UI
import View.Button as Button
import View.Lobby as Lobby
import View.LobbyForm as LobbyForm
import View.LobbyMembers as LobbyMembers
import View.LobbyRoom as LobbyRoom
import View.LobbyRooms as LobbyRooms
import View.LobbyUser as LobbyUser
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


type alias Presence =
    { id : String
    , metas : List Meta
    , user : User
    }


type alias Meta =
    { online_at : String
    , device : String
    }



{- Update -}


type Msg
    = GotUsernameChange String
    | GotJoinLobby
    | GotCreateRoom
    | PhoenixMsg Phoenix.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotUsernameChange name ->
            ( { model | username = name }, Cmd.none )

        GotJoinLobby ->
            joinLobby model.username model.phoenix
                |> updatePhoenixWith PhoenixMsg model

        GotCreateRoom ->
            createRoom model.phoenix
                |> updatePhoenixWith PhoenixMsg model

        PhoenixMsg subMsg ->
            let
                ( newModel, cmd ) =
                    Phoenix.update subMsg model.phoenix
                        |> updatePhoenixWith PhoenixMsg model
            in
            case Phoenix.phoenixMsg newModel.phoenix of
                Phoenix.ChannelResponse (Phoenix.JoinOk "example:lobby" payload) ->
                    case decodeUser payload of
                        Ok user ->
                            ( { newModel | state = InLobby (Registered user) }, cmd )

                        Err _ ->
                            ( newModel, cmd )

                Phoenix.ChannelEvent "example:lobby" "room_list" payload ->
                    case decodeRooms payload of
                        Ok rooms ->
                            ( { newModel | rooms = rooms }, cmd )

                        Err _ ->
                            ( newModel, cmd )

                Phoenix.PresenceEvent (Phoenix.State "example:lobby" state) ->
                    ( { newModel | presences = toPresences state }, cmd )

                _ ->
                    ( newModel, cmd )


joinLobby : String -> Phoenix.Model -> ( Phoenix.Model, Cmd Phoenix.Msg )
joinLobby username phoenix =
    phoenix
        |> Phoenix.setJoinConfig
            { joinConfig
                | topic = "example:lobby"
                , events = [ "room_list" ]
                , payload =
                    JE.object
                        [ ( "username", JE.string (String.trim username) ) ]
            }
        |> Phoenix.join "example:lobby"


createRoom : Phoenix.Model -> ( Phoenix.Model, Cmd Phoenix.Msg )
createRoom phoenix =
    Phoenix.push
        { pushConfig
            | topic = "example:lobby"
            , event = "create_room"
        }
        phoenix


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
                |> Lobby.introduction introduction
                |> Lobby.form (lobbyForm device model.username)
                |> Lobby.view device

        InLobby (Registered user) ->
            Lobby.init
                |> Lobby.user (lobbyUser device user)
                |> Lobby.createRoomBtn (createRoomBtn device)
                |> Lobby.members (lobbyMembers device model.presences)
                |> Lobby.rooms (lobbyRooms device model.rooms)
                |> Lobby.view device



{- Introduction -}


introduction : List (List (Element Msg))
introduction =
    [ [ El.text "Welcome," ]
    , [ El.text "Please enter a username in order to join the Lobby." ]
    ]



{- Lobby Form -}


lobbyForm : Device -> String -> Element Msg
lobbyForm device username =
    LobbyForm.init
        |> LobbyForm.usernameInput
            (Username.init
                |> Username.value username
                |> Username.onChange GotUsernameChange
                |> Username.view device
            )
        |> LobbyForm.submitBtn
            (Button.init
                |> Button.label "Join The Lobby"
                |> Button.onPress (Just GotJoinLobby)
                |> Button.enabled (String.trim username /= "")
                |> Button.view device
            )
        |> LobbyForm.view device



{- Lobby User -}


lobbyUser : Device -> User -> Element Msg
lobbyUser device user =
    LobbyUser.init
        |> LobbyUser.username user.username
        |> LobbyUser.userId user.id
        |> LobbyUser.view device



{- Create Room Button -}


createRoomBtn : Device -> Element Msg
createRoomBtn device =
    Button.init
        |> Button.label "Create A Room"
        |> Button.onPress (Just GotCreateRoom)
        |> Button.enabled True
        |> Button.view device



{- Lobby Members -}


lobbyMembers : Device -> List Presence -> Element Msg
lobbyMembers device presences =
    LobbyMembers.init
        |> LobbyMembers.members (toUsers presences)
        |> LobbyMembers.view device


toUsers : List Presence -> List User
toUsers presences =
    List.map .user presences
        |> List.sortBy .username



{- Lobby Rooms -}


lobbyRooms : Device -> List Room -> Element Msg
lobbyRooms device rooms =
    LobbyRooms.init
        |> LobbyRooms.elements (List.map (lobbyRoom device) rooms)
        |> LobbyRooms.view device


lobbyRoom : Device -> Room -> Element Msg
lobbyRoom device room =
    LobbyRoom.init
        |> LobbyRoom.room room
        |> LobbyRoom.view device
