module Template.Lobby.PhonePortrait exposing (view)

import Colors.Opaque as Color
import Element as El exposing (Element)
import Element.Background as Background
import Element.Border as Border


type alias Config msg c =
    { c
        | introduction : List (Element msg)
        , form : Element msg
    }


view : Config msg c -> Element msg
view config =
    El.el
        [ El.height El.fill
        , El.width El.fill
        ]
    <|
        El.column
            [ Border.rounded 10
            , Background.color Color.steelblue
            , El.padding 20
            , El.width El.fill
            ]
            [ El.column
                [ El.width El.fill ]
                config.introduction
            , config.form
            ]
