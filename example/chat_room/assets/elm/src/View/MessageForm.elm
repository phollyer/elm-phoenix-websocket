module View.MessageForm exposing
    ( init
    , onChange
    , text
    , view
    )

import Element exposing (Device, Element)
import Template.MessageForm.PhonePortrait as PhonePortrait


type Config msg
    = Config
        { text : String
        , onChange : Maybe (String -> msg)
        }


init : Config msg
init =
    Config
        { text = ""
        , onChange = Nothing
        }


view : Device -> Config msg -> Element msg
view { class, orientation } (Config config) =
    PhonePortrait.view config


onChange : (String -> msg) -> Config msg -> Config msg
onChange toMsg (Config config) =
    Config { config | onChange = Just toMsg }


text : String -> Config msg -> Config msg
text text_ (Config config) =
    Config { config | text = text_ }
