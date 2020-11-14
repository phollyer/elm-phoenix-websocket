module View.InputField exposing
    ( init
    , label
    , multiline
    , onChange
    , onFocus
    , onLoseFocus
    , text
    , view
    )

import Device exposing (Device)
import Element exposing (Element)
import Template.InputField.PhonePortrait as PhonePortrait



{- Config -}


type Config msg
    = Config
        { label : String
        , text : String
        , multiline : Bool
        , onChange : Maybe (String -> msg)
        , onFocus : Maybe msg
        , onLoseFocus : Maybe msg
        }



{- Init -}


init : Config msg
init =
    Config
        { label = ""
        , text = ""
        , multiline = False
        , onChange = Nothing
        , onFocus = Nothing
        , onLoseFocus = Nothing
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


text : String -> Config msg -> Config msg
text name (Config config) =
    Config { config | text = name }


onChange : (String -> msg) -> Config msg -> Config msg
onChange toMsg (Config config) =
    Config { config | onChange = Just toMsg }


onFocus : msg -> Config msg -> Config msg
onFocus msg (Config config) =
    Config { config | onFocus = Just msg }


onLoseFocus : msg -> Config msg -> Config msg
onLoseFocus msg (Config config) =
    Config { config | onLoseFocus = Just msg }
