module View.LobbyUser exposing
    ( init
    , userId
    , username
    , view
    )

import Element exposing (Device, Element)
import Template.LobbyUser.PhonePortrait as PhonePortrait


type Config
    = Config
        { userId : String
        , username : String
        }


init : Config
init =
    Config
        { userId = ""
        , username = ""
        }


view : Device -> Config -> Element msg
view { class, orientation } (Config config) =
    PhonePortrait.view config


username : String -> Config -> Config
username name (Config config) =
    Config { config | username = name }


userId : String -> Config -> Config
userId id (Config config) =
    Config { config | userId = id }
