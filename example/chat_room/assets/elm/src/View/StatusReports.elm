module View.StatusReports exposing
    ( Config
    , init
    , reports
    , title
    , view
    )

import Element as El exposing (Device, Element)
import Template.StatusReports.PhonePortrait as PhonePortrait


type Config msg
    = Config
        { title : String
        , reports : List (Element msg)
        }


init : Config msg
init =
    Config
        { title = ""
        , reports = []
        }


view : Device -> Config msg -> Element msg
view { class, orientation } (Config config) =
    PhonePortrait.view config


title : String -> Config msg -> Config msg
title title_ (Config config) =
    Config { config | title = title_ }


reports : List (Element msg) -> Config msg -> Config msg
reports reports_ (Config config) =
    Config { config | reports = reports_ }
