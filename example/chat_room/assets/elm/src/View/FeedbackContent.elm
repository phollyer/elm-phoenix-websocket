module View.FeedbackContent exposing
    ( Config
    , element
    , init
    , label
    , title
    , view
    )

import Element as El exposing (Device, Element)
import Template.FeedbackContent.PhonePortrait as PhonePortrait


type Config msg
    = Config
        { title : Maybe String
        , label : String
        , element : Element msg
        }


init : Config msg
init =
    Config
        { title = Nothing
        , label = ""
        , element = El.none
        }


view : Device -> Config msg -> Element msg
view _ (Config config) =
    PhonePortrait.view config


title : Maybe String -> Config msg -> Config msg
title title_ (Config config) =
    Config { config | title = title_ }


label : String -> Config msg -> Config msg
label label_ (Config config) =
    Config { config | label = label_ }


element : Element msg -> Config msg -> Config msg
element element_ (Config config) =
    Config { config | element = element_ }
