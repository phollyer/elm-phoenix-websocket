module Template.LobbyRoom.PhonePortrait exposing (view)

import Colors.Opaque as Color
import Element as El exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Types exposing (Room)


type alias Config c =
    { c
        | room : Room
    }


view : Config c -> Element msg
view config =
    El.el
        [ Background.color Color.aliceblue
        , Border.rounded 10
        , Border.color Color.darkblue
        , Border.width 1
        , El.padding 10
        , El.width El.fill
        ]
        (El.column
            [ El.width El.fill
            , El.spacing 10
            ]
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
        )
