module View.Example.LabelAndValue exposing
    ( Config
    , init
    , label
    , value
    , view
    )

import Colors.Opaque as Color
import Device exposing (Device)
import Element as El exposing (Element)
import Element.Font as Font



{- Model -}


type Config
    = Config
        { label : String
        , value : String
        }


init : Config
init =
    Config
        { label = ""
        , value = ""
        }


label : String -> Config -> Config
label label_ (Config config) =
    Config { config | label = label_ }


value : String -> Config -> Config
value value_ (Config config) =
    Config { config | value = value_ }



{- View -}


view : Device -> Config -> Element msg
view _ (Config config) =
    El.row
        [ El.width El.fill
        , El.spacing 20
        ]
        [ El.el
            [ Font.color Color.darkslateblue ]
            (El.text config.label)
        , El.el
            [ Font.color Color.black ]
            (El.text config.value)
        ]
