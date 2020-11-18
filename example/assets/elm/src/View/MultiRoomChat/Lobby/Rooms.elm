module View.MultiRoomChat.Lobby.Rooms exposing
    ( init
    , onClick
    , rooms
    , user
    , view
    )

import Colors.Opaque as Color
import Element as El exposing (Attribute, Element)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Event
import Element.Font as Font
import Room exposing (Room)
import Types exposing (User, initUser)
import View exposing (andMaybeEventWithArg)



{- Model -}


type Config msg
    = Config
        { rooms : List Room
        , user : User
        , onClick : Maybe (Room -> msg)
        }


init : Config msg
init =
    Config
        { rooms = []
        , user = initUser
        , onClick = Nothing
        }


rooms : List Room -> Config msg -> Config msg
rooms rooms_ (Config config) =
    Config { config | rooms = rooms_ }


user : User -> Config msg -> Config msg
user user_ (Config config) =
    Config { config | user = user_ }


onClick : Maybe (Room -> msg) -> Config msg -> Config msg
onClick toMsg (Config config) =
    Config { config | onClick = toMsg }



{- View -}


view : Config msg -> Element msg
view (Config config) =
    El.column
        [ Border.rounded 10
        , Background.color Color.steelblue
        , El.padding 10
        , El.spacing 10
        , El.width El.fill
        , Font.color Color.skyblue
        ]
    <|
        List.append
            [ El.el
                [ El.centerX ]
                (El.text "Rooms")
            , El.paragraph
                [ El.spacing 5
                , El.width El.fill
                ]
                [ El.text "A Room can only be joined after it has been opened. "
                , El.text "A Room is opened when the owner of the Room enters it."
                ]
            ]
            (List.map (toRoom config.onClick config.user) config.rooms)


toRoom : Maybe (Room -> msg) -> User -> Room -> Element msg
toRoom maybeToMsg currentUser room =
    let
        attrs =
            roomAttrs currentUser room
                |> andMaybeEventWithArg maybeToMsg room Event.onClick
    in
    El.column
        attrs
        [ owner room.owner.username
        , members room.members
        ]


roomAttrs : User -> Room -> List (Attribute msg)
roomAttrs currentUser room =
    if currentUser == room.owner || List.member room.owner room.members then
        [ Background.color Color.mediumseagreen
        , Border.rounded 10
        , Border.color Color.seagreen
        , Border.width 1
        , El.padding 10
        , El.spacing 10
        , El.width El.fill
        , Font.color Color.lightgreen
        , El.pointer
        , El.mouseOver
            [ Border.color Color.lawngreen ]
        ]

    else
        [ Background.color Color.lightcoral
        , Border.rounded 10
        , Border.color Color.firebrick
        , Border.width 1
        , El.padding 10
        , El.spacing 10
        , El.width El.fill
        , Font.color Color.firebrick
        ]


owner : String -> Element msg
owner username =
    El.row
        [ El.spacing 10
        , El.width El.fill
        , El.clipX
        ]
        [ El.text "Owner:"
        , El.text username
        ]


members : List User -> Element msg
members users =
    El.paragraph
        [ El.width El.fill ]
        [ El.text "Members: "
        , List.map .username users
            |> List.intersperse ", "
            |> String.concat
            |> El.text
        ]
