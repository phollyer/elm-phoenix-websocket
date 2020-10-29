module Template.Button.Phone exposing (view)

import Colors.Opaque as Color
import Element as El exposing (Attribute, Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input


type alias Config msg c =
    { c
        | enabled : Bool
        , label : String
        , onPress : Maybe msg
    }


view : Config msg c -> Element msg
view { enabled, label, onPress } =
    Input.button
        (List.append
            (attrs enabled)
            buttonAttrs
        )
        { label = El.text label
        , onPress = onPress
        }


attrs : Bool -> List (Attribute msg)
attrs enabled =
    if enabled then
        [ Background.color Color.darkseagreen
        , Font.color Color.darkolivegreen
        , El.mouseOver <|
            [ Border.shadow
                { size = 1
                , blur = 2
                , color = Color.seagreen
                , offset = ( 0, 0 )
                }
            ]
        ]

    else
        [ Background.color Color.grey
        , Font.color Color.darkgrey
        ]


buttonAttrs : List (Attribute msg)
buttonAttrs =
    [ Border.rounded 10
    , El.padding 10
    , El.centerY
    , El.centerX
    ]
