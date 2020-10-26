module View.Panel exposing
    ( Config
    , description
    , init
    , onClick
    , title
    , view
    )

import Element as El exposing (Device, DeviceClass(..), Element, Orientation(..))
import Template.Panel.PhoneLandscape as PhoneLandscape
import Template.Panel.PhonePortrait as PhonePortrait
import Template.Panel.Tablet as Tablet


type Config msg
    = Config
        { title : String
        , description : List String
        , onClick : Maybe msg
        }


init : Config msg
init =
    Config
        { title = ""
        , description = []
        , onClick = Nothing
        }


view : Device -> Config msg -> Element msg
view { class, orientation } (Config config) =
    case ( class, orientation ) of
        ( Phone, Portrait ) ->
            PhonePortrait.view config

        ( Phone, Landscape ) ->
            PhoneLandscape.view config

        _ ->
            Tablet.view config


title : String -> Config msg -> Config msg
title text (Config config) =
    Config { config | title = text }


description : List String -> Config msg -> Config msg
description desc (Config config) =
    Config { config | description = desc }


onClick : Maybe msg -> Config msg -> Config msg
onClick maybeMsg (Config config) =
    Config { config | onClick = maybeMsg }
