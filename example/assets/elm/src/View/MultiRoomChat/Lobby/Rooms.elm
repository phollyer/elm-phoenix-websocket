module View.MultiRoomChat.Lobby.Rooms exposing
    ( init
    , onClick
    , rooms
    , view
    )

import Colors.Opaque as Color
import Element as El exposing (Attribute, Element)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Event
import Element.Font as Font
import Types exposing (Room, User)
import View exposing (andMaybeEventWithArg)



{- Model -}


type Config msg
    = Config
        { rooms : List Room
        , onClick : Maybe (Room -> msg)
        }


init : Config msg
init =
    Config
        { rooms = []
        , onClick = Nothing
        }


rooms : List Room -> Config msg -> Config msg
rooms rooms_ (Config config) =
    Config { config | rooms = rooms_ }


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
        (El.el
            [ El.centerX ]
            (El.text "Rooms")
            :: List.map (toRoom config.onClick) config.rooms
        )


toRoom : Maybe (Room -> msg) -> Room -> Element msg
toRoom maybeToMsg room =
    let
        attrs =
            roomAttrs
                |> andMaybeEventWithArg maybeToMsg room Event.onClick
    in
    El.column
        attrs
        [ owner room.owner.username
        , members room.members
        ]


roomAttrs : List (Attribute msg)
roomAttrs =
    [ Background.color Color.aliceblue
    , Border.rounded 10
    , Border.color Color.darkblue
    , Border.width 1
    , El.padding 10
    , El.spacing 10
    , El.width El.fill
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
    El.column
        [ El.width El.fill ]
        (El.text "Members"
            :: List.map member users
        )


member : User -> Element msg
member user =
    El.text user.username
