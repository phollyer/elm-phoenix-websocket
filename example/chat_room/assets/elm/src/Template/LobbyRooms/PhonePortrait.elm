module Template.LobbyRooms.PhonePortrait exposing (view)

import Colors.Opaque as Color
import Element as El exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font


type alias Config msg c =
    { c
        | elements : List (Element msg)
    }


view : Config msg c -> Element msg
view config =
    El.column
        [ Border.rounded 10
        , Background.color Color.steelblue
        , El.paddingEach
            { left = 10
            , top = 10
            , right = 10
            , bottom = 0
            }
        , El.spacing 10
        , El.width El.fill
        , Font.color Color.skyblue
        ]
        (El.el
            [ El.centerX ]
            (El.text "Rooms")
            :: config.elements
        )
