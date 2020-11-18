module Example.MultiRoomChat exposing
    ( Model
    , Msg
    , back
    , init
    , subscriptions
    , update
    , view
    )

import Browser.Dom as Dom
import Browser.Navigation as Nav
import Configs exposing (joinConfig, pushConfig)
import Device exposing (Device)
import Element exposing (Element)
import Example.ManageChannelMessages exposing (Model)
import Example.Utils exposing (updatePhoenixWith)
import Json.Decode as JD
import Json.Encode as JE
import Phoenix
import Room exposing (Room)
import Route
import Task
import Types exposing (Message, Presence, User, decodeMessages, decodeMetas, decodeUser, initUser)
import View.MultiRoomChat.Lobby as Lobby
import View.MultiRoomChat.Lobby.Registration as LobbyRegistration
import View.MultiRoomChat.Room as RoomView



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
                    case Room.decode payload of
                        Ok room ->
                            ( updateRoom room newModel, cmd )

                        Err _ ->
                            ( newModel, cmd )

                Phoenix.ChannelEvent "example:lobby" "room_list" payload ->
                    case Room.decodeRooms payload of
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

                Phoenix.ChannelEvent _ "room_deleted" payload ->
                    case Room.decode payload of
                        Ok room ->
                            ( maybeLeaveRoom room newModel, cmd )

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


leaveLobby : Phoenix.Model -> ( Phoenix.Model, Cmd Phoenix.Msg )
leaveLobby phoenix =
    Phoenix.leave "example:lobby" phoenix


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
                            , "room_deleted"
                            ]
                        , payload =
                            JE.object
                                [ ( "id", JE.string (String.trim user.id) ) ]
                    }
                |> Phoenix.join topic

        _ ->
            ( phoenix, Cmd.none )


leaveRoom : Room -> Phoenix.Model -> ( Phoenix.Model, Cmd Phoenix.Msg )
leaveRoom room phoenix =
    Phoenix.leave ("example:room:" ++ room.id) phoenix


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


maybeLeaveRoom : Room -> Model -> Model
maybeLeaveRoom room model =
    case model.state of
        InRoom room_ user ->
            if room_.id == room.id then
                { model | state = InLobby user }

            else
                model

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
            List.filter (\username_ -> username_ /= username) model.membersTyping
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
            Room.init


toUser : Model -> User
toUser model =
    case model.state of
        Unregistered ->
            initUser

        InLobby user ->
            user

        InRoom _ user ->
            user



{- Navigation -}


back : Nav.Key -> Model -> ( Model, Cmd Msg )
back key model =
    case model.state of
        InRoom room user ->
            leaveRoom room model.phoenix
                |> updatePhoenixWith PhoenixMsg
                    { model | state = InLobby user }

        InLobby _ ->
            leaveLobby model.phoenix
                |> updatePhoenixWith PhoenixMsg
                    { model | state = Unregistered }

        Unregistered ->
            ( model, Route.back key )



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
            RoomView.init
                |> RoomView.user user
                |> RoomView.room room
                |> RoomView.messages model.messages
                |> RoomView.membersTyping model.membersTyping
                |> RoomView.userText model.message
                |> RoomView.onChange GotMessageChange
                |> RoomView.onFocus (GotMemberStartedTyping user room)
                |> RoomView.onLoseFocus (GotMemberStoppedTyping user room)
                |> RoomView.onSubmit GotSendMessage
                |> RoomView.view device
