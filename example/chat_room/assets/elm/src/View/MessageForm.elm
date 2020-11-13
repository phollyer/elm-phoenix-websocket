module View.MessageForm exposing
    ( init
    , onChange
    , value
    , view
    )

import Element exposing (Device, Element)
import Template.MessageForm.PhonePortrait as PhonePortrait


type Config msg
    = Config
        { value : String
        , onChange : Maybe (String -> msg)
        }


init : Config msg
init =
    Config
        { value = ""
        , onChange = Nothing
        }


view : Device -> Config msg -> Element msg
view { class, orientation } (Config config) =
    PhonePortrait.view config


onChange : (String -> msg) -> Config msg -> Config msg
onChange toMsg (Config config) =
    Config { config | onChange = Just toMsg }


value : String -> Config msg -> Config msg
value val (Config config) =
    Config { config | value = val }
