module Template.Lobby.PhonePortrait exposing (view)

import Colors.Opaque as Color
import Element as El exposing (Element, paragraph)
import Element.Background as Background
import Element.Border as Border


type alias Config msg c =
    { c
        | introduction : List (List (Element msg))
        , form : Element msg
    }


view : Config msg c -> Element msg
view config =
    El.column
        [ El.height El.fill
        , El.width El.fill
        ]
        [ El.column
            [ El.width El.fill ]
          <|
            List.map
                (\paragraph ->
                    El.paragraph
                        [ El.width El.fill ]
                        paragraph
                )
                config.introduction
        , El.el
            [ Border.rounded 10
            , Background.color Color.steelblue
            , El.padding 20
            , El.width El.fill
            ]
            config.form
        ]
