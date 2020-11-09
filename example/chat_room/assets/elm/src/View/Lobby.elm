module View.Lobby exposing
    ( form
    , init
    , introduction
    , userId
    , username
    , view
    )

import Element as El exposing (Device, Element)
import Template.Lobby.PhonePortrait as PhonePortrait



{- Config -}


type Config msg
    = Config
        { introduction : List (List (Element msg))
        , form : Element msg
        , username : String
        , userId : Maybe String
        }



{- Init -}


init : Config msg
init =
    Config
        { introduction = []
        , form = El.none
        , username = ""
        , userId = Nothing
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


username : String -> Config msg -> Config msg
username name (Config config) =
    Config { config | username = name }


userId : String -> Config msg -> Config msg
userId id (Config config) =
    Config { config | userId = Just id }
