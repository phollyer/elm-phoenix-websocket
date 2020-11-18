module View.MultiRoomChat.Lobby.Rooms exposing
    ( init
    , onClick
    , onDelete
    , rooms
    , user
    , view
    )

import Colors.Opaque as Color
import Device exposing (Device)
import Element as El exposing (Attribute, Element)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Event
import Element.Font as Font
import Room exposing (Room)
import Types exposing (User, initUser)
import View exposing (andMaybeEventWithArg)
import View.Button as Button



{- Model -}


type Config msg
    = Config
        { rooms : List Room
        , user : User
        , onClick : Maybe (Room -> msg)
        , onDelete : Maybe (Room -> msg)
        }


init : Config msg
init =
    Config
        { rooms = []
        , user = initUser
        , onClick = Nothing
        , onDelete = Nothing
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


onDelete : Maybe (Room -> msg) -> Config msg -> Config msg
onDelete toMsg (Config config) =
    Config { config | onDelete = toMsg }



{- View -}


view : Device -> Config msg -> Element msg
view device (Config config) =
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
            (orderRooms config.user config.rooms
                |> List.map (toRoom device (Config config))
            )


orderRooms : User -> List Room -> List Room
orderRooms currentUser roomList =
    let
        ( ownersRooms, others ) =
            List.partition (\room -> currentUser == room.owner) roomList
    in
    List.append ownersRooms <|
        List.sortWith
            (\room1 room2 ->
                case compare room1.owner.username room2.owner.username of
                    LT ->
                        LT

                    EQ ->
                        EQ

                    GT ->
                        GT
            )
            others


toRoom : Device -> Config msg -> Room -> Element msg
toRoom device (Config config) room =
    El.row
        (roomAttrs config.user room)
        [ El.column
            [ El.width El.fill
            , El.clipX
            ]
            [ owner room.owner.username
            , members room.members
            ]
        , El.row
            [ El.spacing 10 ]
            [ maybeEnterBtn device config.onClick config.user room
            , maybeDeleteBtn device config.onDelete config.user room
            ]
        ]


maybeDeleteBtn : Device -> Maybe (Room -> msg) -> User -> Room -> Element msg
maybeDeleteBtn device maybeToOnDelete currentUser room =
    if currentUser == room.owner then
        case maybeToOnDelete of
            Nothing ->
                El.none

            Just onDelete_ ->
                Button.init
                    |> Button.label "Delete"
                    |> Button.onPress (Just (onDelete_ room))
                    |> Button.view device

    else
        El.none


maybeEnterBtn : Device -> Maybe (Room -> msg) -> User -> Room -> Element msg
maybeEnterBtn device maybeToOnClick currentUser room =
    if currentUser == room.owner || List.member room.owner room.members then
        case maybeToOnClick of
            Nothing ->
                El.none

            Just onClick_ ->
                Button.init
                    |> Button.label "Enter"
                    |> Button.onPress (Just (onClick_ room))
                    |> Button.view device

    else
        El.none


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
        [ El.width El.fill
        , Font.alignLeft
        ]
        [ El.text "Members: "
        , List.map .username users
            |> List.intersperse ", "
            |> String.concat
            |> El.text
        ]
