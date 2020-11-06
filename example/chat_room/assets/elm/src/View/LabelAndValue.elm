module View.LabelAndValue exposing
    ( Config
    , init
    , label
    , value
    , view
    )

import Element exposing (Device, Element)
import Template.LabelAndValue.PhonePortrait as PhonePortrait


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


view : Device -> Config -> Element msg
view _ (Config config) =
    PhonePortrait.view config


label : String -> Config -> Config
label label_ (Config config) =
    Config { config | label = label_ }


value : String -> Config -> Config
value value_ (Config config) =
    Config { config | value = value_ }
