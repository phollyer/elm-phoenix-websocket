module View.Button exposing
    ( Config
    , enabled
    , init
    , label
    , onPress
    , view
    )

import Colors.Opaque as Color
import Device exposing (Device)
import Element as El exposing (Attribute, Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input



{- Model -}


type Config msg
    = Config
        { enabled : Bool
        , label : String
        , onPress : Maybe msg
        }


init : Config msg
init =
    Config
        { enabled = True
        , label = ""
        , onPress = Nothing
        }


enabled : Bool -> Config msg -> Config msg
enabled enabled_ (Config config) =
    Config { config | enabled = enabled_ }


label : String -> Config msg -> Config msg
label label_ (Config config) =
    Config { config | label = label_ }


onPress : Maybe msg -> Config msg -> Config msg
onPress maybe (Config config) =
    Config { config | onPress = maybe }



{- View -}


view : Device -> Config msg -> Element msg
view _ (Config config) =
    Input.button
        (List.append
            defaultAttrs
            (attrs config.enabled)
        )
        { label = El.text config.label
        , onPress =
            if config.enabled then
                config.onPress

            else
                Nothing
        }


attrs : Bool -> List (Attribute msg)
attrs enabled_ =
    if enabled_ then
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


defaultAttrs : List (Attribute msg)
defaultAttrs =
    [ Border.rounded 10
    , El.padding 10
    , El.centerY
    , El.centerX
    ]
