module View.InputField exposing
    ( init
    , label
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
        }



{- Init -}


init : Config msg
init =
    Config
        { label = ""
        , onChange = Nothing
        , text = ""
        }



{- View -}


view : Device -> Config msg -> Element msg
view device (Config config) =
    PhonePortrait.view config


label : String -> Config msg -> Config msg
label label_ (Config config) =
    Config { config | label = label_ }


onChange : (String -> msg) -> Config msg -> Config msg
onChange toMsg (Config config) =
    Config { config | onChange = Just toMsg }


text : String -> Config msg -> Config msg
text name (Config config) =
    Config { config | text = name }
