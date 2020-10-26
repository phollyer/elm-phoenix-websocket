module Template.Control.PhonePortrait exposing (view)

import Colors.Opaque as Color
import Element as El exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input


view :
    { b
        | enabled : Bool
        , label : String
        , onPress : Maybe msg
    }
    -> Element msg
view config =
    let
        attrs =
            if config.enabled then
                [ Background.color Color.darkseagreen
                , El.mouseOver <|
                    [ Border.shadow
                        { size = 1
                        , blur = 2
                        , color = Color.seagreen
                        , offset = ( 0, 0 )
                        }
                    , Font.size 22
                    ]
                , Font.color Color.darkolivegreen
                ]

            else
                [ Background.color Color.grey
                , Font.color Color.darkgrey
                ]
    in
    Input.button
        (List.append
            attrs
            [ Border.rounded 10
            , El.padding 10
            , Font.size 20
            , El.centerY
            , El.centerX
            ]
        )
        { label = El.text config.label
        , onPress = config.onPress
        }
