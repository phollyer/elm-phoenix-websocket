module View.MessageForm exposing
    ( init
    , inputField
    , submitBtn
    , view
    )

import Device exposing (Device)
import Element as El exposing (Element)
import Template.MessageForm.PhonePortrait as PhonePortrait


type Config msg
    = Config
        { inputField : Element msg
        , submitBtn : Element msg
        }


init : Config msg
init =
    Config
        { inputField = El.none
        , submitBtn = El.none
        }


view : Device -> Config msg -> Element msg
view { class, orientation } (Config config) =
    PhonePortrait.view config


inputField : Element msg -> Config msg -> Config msg
inputField element (Config config) =
    Config { config | inputField = element }


submitBtn : Element msg -> Config msg -> Config msg
submitBtn element (Config config) =
    Config { config | submitBtn = element }
