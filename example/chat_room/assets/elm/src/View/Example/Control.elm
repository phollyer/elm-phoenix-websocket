module View.Example.Control exposing
    ( Config
    , enabled
    , init
    , label
    , onPress
    , view
    )

import Element as El exposing (Device, Element)
import Template.Control.PhonePortrait as PhonePortrait


type Config msg
    = Config
        { enabled : Bool
        , label : String
        , onPress : Maybe msg
        }


init : Config msg
init =
    Config
        { enabled = False
        , label = ""
        , onPress = Nothing
        }


view : Device -> Config msg -> Element msg
view _ (Config config) =
    PhonePortrait.view config


enabled : Bool -> Config msg -> Config msg
enabled enabled_ (Config config) =
    Config { config | enabled = enabled_ }


label : String -> Config msg -> Config msg
label label_ (Config config) =
    Config { config | label = label_ }


onPress : Maybe msg -> Config msg -> Config msg
onPress maybeMsg (Config config) =
    Config { config | onPress = maybeMsg }
