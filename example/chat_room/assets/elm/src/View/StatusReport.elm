module View.StatusReport exposing
    ( Config
    , init
    , report
    , title
    , view
    )

import Element as El exposing (Device, Element)
import Template.StatusReport.PhonePortrait as PhonePortrait


type Config msg
    = Config
        { title : String
        , report : Element msg
        }


init : Config msg
init =
    Config
        { title = ""
        , report = El.none
        }


view : Device -> Config msg -> Element msg
view { class, orientation } (Config config) =
    PhonePortrait.view config


title : String -> Config msg -> Config msg
title title_ (Config config) =
    Config { config | title = title_ }


report : Element msg -> Config msg -> Config msg
report report_ (Config config) =
    Config { config | report = report_ }
