module View.Lobby exposing
    ( createRoomBtn
    , form
    , init
    , introduction
    , members
    , rooms
    , user
    , view
    )

import Element as El exposing (Device, Element)
import Template.Lobby.PhonePortrait as PhonePortrait



{- Config -}


type Config msg
    = Config
        { introduction : List (List (Element msg))
        , form : Element msg
        , user : Maybe (Element msg)
        , members : Element msg
        , createRoomBtn : Element msg
        , rooms : Element msg
        }



{- Init -}


init : Config msg
init =
    Config
        { introduction = []
        , form = El.none
        , user = Nothing
        , members = El.none
        , createRoomBtn = El.none
        , rooms = El.none
        }



{- View -}


view : Device -> Config msg -> Element msg
view device (Config config) =
    PhonePortrait.view config


form : Element msg -> Config msg -> Config msg
form inputElement (Config config) =
    Config { config | form = inputElement }


introduction : List (List (Element msg)) -> Config msg -> Config msg
introduction elements (Config config) =
    Config { config | introduction = elements }


members : Element msg -> Config msg -> Config msg
members element (Config config) =
    Config { config | members = element }


createRoomBtn : Element msg -> Config msg -> Config msg
createRoomBtn btn (Config config) =
    Config { config | createRoomBtn = btn }


rooms : Element msg -> Config msg -> Config msg
rooms element (Config config) =
    Config { config | rooms = element }


user : Element msg -> Config msg -> Config msg
user element (Config config) =
    Config { config | user = Just element }
