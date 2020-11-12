module View.Rooms exposing
    ( init
    , list
    , view
    )

import Element exposing (Device, Element)
import Template.Rooms.PhonePortrait as PhonePortrait


type Config
    = Config { list : List Room }


type alias Room =
    { id : String
    , owner : User
    , members : List User
    , messages : List Message
    }


type alias Message =
    { id : String
    , text : String
    , owner : User
    }


type alias User =
    { id : String
    , username : String
    }


init : Config
init =
    Config
        { list = [] }


view : Device -> Config -> Element msg
view { class, orientation } (Config config) =
    PhonePortrait.view config


list : List Room -> Config -> Config
list rooms (Config config) =
    Config { config | list = rooms }
