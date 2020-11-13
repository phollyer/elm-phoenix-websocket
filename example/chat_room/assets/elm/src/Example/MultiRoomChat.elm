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
import Types exposing (Message, Room, User, decodeMessage, decodeRoom, decodeRooms, decodeUser, initRoom, initUser)
import UI
import View.Button as Button
import View.ChatRoom as ChatRoom
import View.InputField as InputField
import View.Lobby as Lobby
import View.LobbyForm as LobbyForm
import View.LobbyMembers as LobbyMembers
import View.LobbyRoom as LobbyRoom
import View.LobbyRooms as LobbyRooms
import View.LobbyUser as LobbyUser
import View.MessageForm as MessageForm



{- Init -}


init : Phoenix.Model -> Model
init phoenix =
    { phoenix = phoenix
    , state = InLobby Unregistered
    , username = ""
    , message = ""
    , presences = []
    , rooms = []
    , membersTyping = []
    }



{- Model -}


type alias Model =
    { phoenix : Phoenix.Model
    , state : State
    , username : String
    , message : String
    , presences : List Presence
    , rooms : List Room
    , membersTyping : List String
    }


type State
    = InLobby LobbyState
    | InRoom Room User


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
    | GotEnterRoom Room
    | GotMessageChange String
    | GotMemberStartedTyping User Room
    | GotMemberStoppedTyping User Room
    | GotSendMessage
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

        GotEnterRoom room ->
            joinRoom room model.state model.phoenix
                |> updatePhoenixWith PhoenixMsg (gotoRoom room model)

        GotMessageChange message ->
            ( { model | message = message }, Cmd.none )

        GotSendMessage ->
            ( model, Cmd.none )

        GotMemberStartedTyping user room ->
            memberStartedTyping user room model.phoenix
                |> updatePhoenixWith PhoenixMsg model

        GotMemberStoppedTyping user room ->
            memberStoppedTyping user room model.phoenix
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

                Phoenix.ChannelResponse (Phoenix.JoinOk _ payload) ->
                    case decodeRoom payload of
                        Ok room ->
                            ( updateRoom room newModel, cmd )

                        Err _ ->
                            ( newModel, cmd )

                Phoenix.ChannelEvent "example:lobby" "room_list" payload ->
                    case decodeRooms payload of
                        Ok rooms ->
                            ( { newModel | rooms = rooms }, cmd )

                        Err _ ->
                            ( newModel, cmd )

                Phoenix.ChannelEvent _ "member_started_typing" payload ->
                    case JD.decodeValue (JD.field "username" JD.string) payload of
                        Ok username ->
                            ( addMemberTyping username newModel, cmd )

                        Err _ ->
                            ( newModel, cmd )

                Phoenix.ChannelEvent _ "member_stopped_typing" payload ->
                    case JD.decodeValue (JD.field "username" JD.string) payload of
                        Ok username ->
                            ( dropMemberTyping username newModel, cmd )

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


joinRoom : Room -> State -> Phoenix.Model -> ( Phoenix.Model, Cmd Phoenix.Msg )
joinRoom room state phoenix =
    case state of
        InLobby (Registered user) ->
            let
                topic =
                    "example:room:" ++ room.id
            in
            phoenix
                |> Phoenix.setJoinConfig
                    { joinConfig
                        | topic = topic
                        , events =
                            [ "message_list"
                            , "member_started_typing"
                            , "member_stopped_typing"
                            ]
                        , payload =
                            JE.object
                                [ ( "id", JE.string (String.trim user.id) ) ]
                    }
                |> Phoenix.join topic

        _ ->
            ( phoenix, Cmd.none )


memberStartedTyping : User -> Room -> Phoenix.Model -> ( Phoenix.Model, Cmd Phoenix.Msg )
memberStartedTyping user room phoenix =
    Phoenix.push
        { pushConfig
            | topic = "example:room:" ++ room.id
            , event = "member_started_typing"
            , payload =
                JE.object
                    [ ( "username", JE.string user.username ) ]
        }
        phoenix


memberStoppedTyping : User -> Room -> Phoenix.Model -> ( Phoenix.Model, Cmd Phoenix.Msg )
memberStoppedTyping user room phoenix =
    Phoenix.push
        { pushConfig
            | topic = "example:room:" ++ room.id
            , event = "member_stopped_typing"
            , payload =
                JE.object
                    [ ( "username", JE.string user.username ) ]
        }
        phoenix


gotoRoom : Room -> Model -> Model
gotoRoom room model =
    case model.state of
        InLobby (Registered user) ->
            { model | state = InRoom room user }

        _ ->
            model


updateRoom : Room -> Model -> Model
updateRoom room model =
    case model.state of
        InRoom _ user ->
            { model | state = InRoom room user }

        _ ->
            model


addMemberTyping : String -> Model -> Model
addMemberTyping username model =
    let
        user =
            toUser model
    in
    if username /= user.username && (not <| List.member username model.membersTyping) then
        { model | membersTyping = username :: model.membersTyping }

    else
        model


dropMemberTyping : String -> Model -> Model
dropMemberTyping username model =
    { model
        | membersTyping =
            List.filter (\username_ -> username /= username) model.membersTyping
    }


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


toRoom : Model -> Room
toRoom model =
    case model.state of
        InRoom room _ ->
            room

        _ ->
            initRoom


toUser : Model -> User
toUser model =
    case model.state of
        InRoom _ user ->
            user

        InLobby (Registered user) ->
            user

        InLobby Unregistered ->
            initUser



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
                |> Lobby.introduction lobbyIntroduction
                |> Lobby.form (lobbyForm device model.username)
                |> Lobby.view device

        InLobby (Registered user) ->
            Lobby.init
                |> Lobby.user (lobbyUser device user)
                |> Lobby.createRoomBtn (createRoomBtn device)
                |> Lobby.members (lobbyMembers device model.presences)
                |> Lobby.rooms (lobbyRooms device model.rooms)
                |> Lobby.view device

        InRoom room _ ->
            ChatRoom.init
                |> ChatRoom.introduction (chatRoomIntroduction room.owner)
                |> ChatRoom.room room
                |> ChatRoom.membersTyping model.membersTyping
                |> ChatRoom.messageForm (messageForm device model)
                |> ChatRoom.view device



{- Introduction -}


lobbyIntroduction : List (List (Element Msg))
lobbyIntroduction =
    [ [ El.text "Welcome," ]
    , [ El.text "Please enter a username in order to join the Lobby." ]
    ]


chatRoomIntroduction : User -> List (List (Element Msg))
chatRoomIntroduction user =
    [ [ El.text "Welcome to "
      , El.text user.username
      , El.text "'s room."
      ]
    ]



{- Forms -}


lobbyForm : Device -> String -> Element Msg
lobbyForm device username =
    LobbyForm.init
        |> LobbyForm.usernameInput
            (InputField.init
                |> InputField.label "Username"
                |> InputField.text username
                |> InputField.onChange GotUsernameChange
                |> InputField.view device
            )
        |> LobbyForm.submitBtn
            (Button.init
                |> Button.label "Join The Lobby"
                |> Button.onPress (Just GotJoinLobby)
                |> Button.enabled (String.trim username /= "")
                |> Button.view device
            )
        |> LobbyForm.view device


messageForm : Device -> Model -> Element Msg
messageForm device ({ message } as model) =
    MessageForm.init
        |> MessageForm.inputField
            (InputField.init
                |> InputField.label "New Message"
                |> InputField.text message
                |> InputField.multiline True
                |> InputField.onChange GotMessageChange
                |> InputField.onFocus (GotMemberStartedTyping (toUser model) (toRoom model))
                |> InputField.onLoseFocus (GotMemberStoppedTyping (toUser model) (toRoom model))
                |> InputField.view device
            )
        |> MessageForm.submitBtn
            (Button.init
                |> Button.label "Send Message"
                |> Button.onPress (Just GotSendMessage)
                |> Button.enabled (String.trim message /= "")
                |> Button.view device
            )
        |> MessageForm.view device



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
        |> LobbyRoom.onClick GotEnterRoom
        |> LobbyRoom.view device
