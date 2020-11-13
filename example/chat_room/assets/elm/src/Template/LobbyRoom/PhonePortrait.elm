module Template.LobbyRoom.PhonePortrait exposing (view)

import Colors.Opaque as Color
import Element as El exposing (Attribute, Element)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Event
import Types exposing (Room)


type alias Config msg c =
    { c
        | room : Room
        , onClick : Maybe (Room -> msg)
    }


view : Config msg c -> Element msg
view config =
    let
        attrs =
            case config.onClick of
                Nothing ->
                    containerAttrs

                Just onClick ->
                    Event.onClick (onClick config.room)
                        :: containerAttrs
    in
    El.column
        attrs
        [ El.row
            [ El.spacing 10
            , El.width El.fill
            , El.clipX
            ]
            [ El.text "Owner:"
            , El.text config.room.owner.username
            ]
        , El.column
            [ El.width El.fill ]
            (El.text "Members"
                :: List.map
                    (\member ->
                        El.text member.username
                    )
                    config.room.members
            )
        ]


containerAttrs : List (Attribute msg)
containerAttrs =
    [ Background.color Color.aliceblue
    , Border.rounded 10
    , Border.color Color.darkblue
    , Border.width 1
    , El.padding 10
    , El.width El.fill
    ]
