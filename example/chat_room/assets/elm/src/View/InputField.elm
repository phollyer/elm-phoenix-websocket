module View.InputField exposing
    ( init
    , label
    , multiline
    , onChange
    , text
    , view
    )

import Element exposing (Device, Element)
import Template.InputField.PhonePortrait as PhonePortrait



{- Config -}


type Config msg
    = Config
        { label : String
        , onChange : Maybe (String -> msg)
        , text : String
        , multiline : Bool
        }



{- Init -}


init : Config msg
init =
    Config
        { label = ""
        , onChange = Nothing
        , text = ""
        , multiline = False
        }



{- View -}


view : Device -> Config msg -> Element msg
view device (Config config) =
    PhonePortrait.view config


label : String -> Config msg -> Config msg
label label_ (Config config) =
    Config { config | label = label_ }


multiline : Bool -> Config msg -> Config msg
multiline bool (Config config) =
    Config { config | multiline = bool }


onChange : (String -> msg) -> Config msg -> Config msg
onChange toMsg (Config config) =
    Config { config | onChange = Just toMsg }


text : String -> Config msg -> Config msg
text name (Config config) =
    Config { config | text = name }
