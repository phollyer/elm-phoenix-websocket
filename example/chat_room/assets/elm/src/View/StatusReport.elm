module View.StatusReport exposing
    ( Config
    , Value(..)
    , init
    , label
    , title
    , value
    , view
    )

import Element as El exposing (Device, Element)
import Template.StatusReport.PhonePortrait as PhonePortrait


type Config msg
    = Config
        { title : Maybe String
        , label : String
        , value : Value msg
        }


type Value msg
    = String String
    | Element (Element msg)


init : Config msg
init =
    Config
        { title = Nothing
        , label = ""
        , value = String ""
        }


view : Device -> Config msg -> Element msg
view { class, orientation } config =
    PhonePortrait.view (toTemplate config)


title : Maybe String -> Config msg -> Config msg
title title_ (Config config) =
    Config { config | title = title_ }


label : String -> Config msg -> Config msg
label label_ (Config config) =
    Config { config | label = label_ }


value : Value msg -> Config msg -> Config msg
value value_ (Config config) =
    Config { config | value = value_ }


toTemplate : Config msg -> { title : Maybe String, label : String, element : Element msg }
toTemplate (Config config) =
    { title = config.title
    , label = config.label
    , element =
        case config.value of
            String str ->
                El.text str

            Element el ->
                el
    }
