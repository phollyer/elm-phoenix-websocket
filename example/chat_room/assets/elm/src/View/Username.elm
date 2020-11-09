module View.Username exposing
    ( init
    , onChange
    , value
    , view
    )

import Element exposing (Device, Element)
import Template.Username.PhonePortrait as PhonePortrait



{- Config -}


type Config msg
    = Config
        { onChange : Maybe (String -> msg)
        , value : String
        }



{- Init -}


init : Config msg
init =
    Config
        { onChange = Nothing
        , value = ""
        }



{- View -}


view : Device -> Config msg -> Element msg
view device (Config config) =
    PhonePortrait.view config


onChange : (String -> msg) -> Config msg -> Config msg
onChange toMsg (Config config) =
    Config { config | onChange = Just toMsg }


value : String -> Config msg -> Config msg
value name (Config config) =
    Config { config | value = name }
