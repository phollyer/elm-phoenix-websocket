module View.LobbyForm exposing
    ( init
    , submitBtn
    , usernameInput
    , view
    )

import Element as El exposing (Device, Element)
import Template.LobbyForm.PhonePortrait as PhonePortrait


type Config msg c
    = Config
        { usernameInput : Element msg
        , submitBtn : Element msg
        }



{- Init -}


init : Config msg c
init =
    Config
        { usernameInput = El.none
        , submitBtn = El.none
        }



{- View -}


view : Device -> Config msg c -> Element msg
view device (Config config) =
    PhonePortrait.view config


usernameInput : Element msg -> Config msg c -> Config msg c
usernameInput inputElement (Config config) =
    Config { config | usernameInput = inputElement }


submitBtn : Element msg -> Config msg c -> Config msg c
submitBtn btnElement (Config config) =
    Config { config | submitBtn = btnElement }
