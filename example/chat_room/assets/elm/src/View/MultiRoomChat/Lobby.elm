module View.MultiRoomChat.Lobby exposing
    ( init
    , members
    , onCreateRoom
    , onEnterRoom
    , rooms
    , user
    , view
    )

import Colors.Opaque as Color
import Device exposing (Device)
import Element as El exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Types exposing (Presence, Room, User, initUser)
import View.Button as Button
import View.MultiRoomChat.Lobby.Members as LobbyMembers
import View.MultiRoomChat.Lobby.Rooms as LobbyRooms
import View.MultiRoomChat.User as User



{- Model -}


type Config msg
    = Config
        { user : User
        , members : List Presence
        , onCreateRoom : Maybe msg
        , onEnterRoom : Maybe (Room -> msg)
        , rooms : List Room
        }


init : Config msg
init =
    Config
        { user = initUser
        , members = []
        , onCreateRoom = Nothing
        , onEnterRoom = Nothing
        , rooms = []
        }


members : List Presence -> Config msg -> Config msg
members members_ (Config config) =
    Config { config | members = members_ }


onCreateRoom : msg -> Config msg -> Config msg
onCreateRoom msg (Config config) =
    Config { config | onCreateRoom = Just msg }


onEnterRoom : (Room -> msg) -> Config msg -> Config msg
onEnterRoom msg (Config config) =
    Config { config | onEnterRoom = Just msg }


rooms : List Room -> Config msg -> Config msg
rooms rooms_ (Config config) =
    Config { config | rooms = rooms_ }


user : User -> Config msg -> Config msg
user user_ (Config config) =
    Config { config | user = user_ }



{- View -}


view : Device -> Config msg -> Element msg
view device (Config config) =
    El.column
        [ El.width El.fill
        , El.spacing 15
        ]
        [ El.column
            [ Border.rounded 10
            , Background.color Color.steelblue
            , El.padding 20
            , El.spacing 20
            , El.width El.fill
            , Font.color Color.skyblue
            ]
            [ userView device config.user
            , createRoomBtn device config.onCreateRoom
            ]
        , membersView device config.members
        , roomsView device (Config config)
        ]



{- Lobby User -}


userView : Device -> User -> Element msg
userView device { username, id } =
    User.init
        |> User.username username
        |> User.userId id
        |> User.view device



{- Create Room Button -}


createRoomBtn : Device -> Maybe msg -> Element msg
createRoomBtn device maybeMsg =
    Button.init
        |> Button.label "Create A Room"
        |> Button.onPress maybeMsg
        |> Button.view device



{- Lobby Members -}


membersView : Device -> List Presence -> Element msg
membersView device presences =
    LobbyMembers.init
        |> LobbyMembers.members (toUsers presences)
        |> LobbyMembers.view device


toUsers : List Presence -> List User
toUsers presences =
    List.map .user presences
        |> List.sortBy .username



{- Rooms -}


roomsView : Device -> Config msg -> Element msg
roomsView device (Config config) =
    LobbyRooms.init
        |> LobbyRooms.rooms config.rooms
        |> LobbyRooms.onClick config.onEnterRoom
        |> LobbyRooms.view device
