module View.LobbyMembers exposing
    ( init
    , members
    , view
    )

import Device exposing (Device)
import Element exposing (Element)
import Template.LobbyMembers.PhonePortrait as PhonePortrait


type Config
    = Config { members : List User }


type alias User =
    { id : String
    , username : String
    }


init : Config
init =
    Config
        { members = [] }


view : Device -> Config -> Element msg
view { class, orientation } (Config config) =
    PhonePortrait.view config


members : List User -> Config -> Config
members users (Config config) =
    Config { config | members = users }
