module Example.MultiRoomChat exposing
    ( Model
    , Msg
    , init
    , subscriptions
    , update
    , view
    )

import Browser.Dom as Dom
import Configs exposing (joinConfig, pushConfig)
import Device exposing (Device)
import Element as El exposing (Element)
import Example.Utils exposing (updatePhoenixWith)
import Json.Decode as JD
import Json.Decode.Extra exposing (andMap)
import Json.Encode as JE exposing (Value)
import Phoenix
import Task
import Types exposing (Message, Presence, Room, User, decodeMessages, decodeMetas, decodeRoom, decodeRooms, decodeUser, initRoom, initUser)
import UI
import View.Button as Button
import View.InputField as InputField
import View.MultiRoomChat.Example as Example
import View.MultiRoomChat.Lobby as Lobby
import View.MultiRoomChat.Lobby.Form as LobbyForm
import View.MultiRoomChat.Lobby.Members as LobbyMembers
import View.MultiRoomChat.Lobby.Registration as LobbyRegistration
import View.MultiRoomChat.Lobby.Rooms as LobbyRooms
import View.MultiRoomChat.Room.Form as MessageForm
import View.MultiRoomChat.Room.Messages as Messages
import View.MultiRoomChat.User as User



{- Init -}


init : Phoenix.Model -> Model
init phoenix =
    { phoenix = phoenix
    , state = Unregistered
    , username = ""
    , message = ""
    , messages = []
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
    , messages : List Message
    , presences : List Presence
    , rooms : List Room
    , membersTyping : List String
    }


type State
    = Unregistered
    | InLobby User
    | InRoom Room User



{- Update -}


type Msg
    = NoOp
    | GotUsernameChange String
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
            sendMessage model.message (toRoom model) model.phoenix
                |> updatePhoenixWith PhoenixMsg { model | message = "" }

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
                            ( { newModel | state = InLobby user }, cmd )

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

                Phoenix.ChannelEvent _ "message_list" payload ->
                    case decodeMessages payload of
                        Ok messages_ ->
                            ( { newModel | messages = messages_ }
                            , Cmd.batch
                                [ cmd
                                , Dom.getViewportOf "message-list"
                                    |> Task.andThen (\{ scene } -> Dom.setViewportOf "message-list" 0 scene.height)
                                    |> Task.attempt (\_ -> NoOp)
                                ]
                            )

                        Err _ ->
                            ( newModel, cmd )

                Phoenix.PresenceEvent (Phoenix.State "example:lobby" state) ->
                    ( { newModel | presences = toPresences state }, cmd )

                _ ->
                    ( newModel, cmd )

        NoOp ->
            ( model, Cmd.none )


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
        InLobby user ->
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


sendMessage : String -> Room -> Phoenix.Model -> ( Phoenix.Model, Cmd Phoenix.Msg )
sendMessage message room phoenix =
    Phoenix.push
        { pushConfig
            | topic = "example:room:" ++ room.id
            , event = "new_message"
            , payload =
                JE.object
                    [ ( "message", JE.string message ) ]
        }
        phoenix


gotoRoom : Room -> Model -> Model
gotoRoom room model =
    case model.state of
        InLobby user ->
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
        Unregistered ->
            initUser

        InLobby user ->
            user

        InRoom _ user ->
            user



{- Subscriptions -}


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.map PhoenixMsg <|
        Phoenix.subscriptions model.phoenix



{- View -}


view : Device -> Model -> Element Msg
view device model =
    case model.state of
        Unregistered ->
            LobbyRegistration.init
                |> LobbyRegistration.username model.username
                |> LobbyRegistration.onChange GotUsernameChange
                |> LobbyRegistration.onSubmit GotJoinLobby
                |> LobbyRegistration.view device

        InLobby user ->
            Lobby.init
                |> Lobby.user user
                |> Lobby.onCreateRoom GotCreateRoom
                |> Lobby.onEnterRoom GotEnterRoom
                |> Lobby.members model.presences
                |> Lobby.rooms model.rooms
                |> Lobby.view device

        InRoom room user ->
            Example.init
                |> Example.user user
                |> Example.room room
                |> Example.messages model.messages
                |> Example.membersTyping model.membersTyping
                |> Example.userText model.message
                |> Example.onChange GotMessageChange
                |> Example.onFocus (GotMemberStartedTyping user room)
                |> Example.onLoseFocus (GotMemberStoppedTyping user room)
                |> Example.onSubmit GotSendMessage
                |> Example.view device
