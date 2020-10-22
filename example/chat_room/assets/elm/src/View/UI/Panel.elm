module View.UI.Panel exposing
    ( Config
    , description
    , init
    , onClick
    , render
    , title
    )

import Element as El exposing (Device, DeviceClass(..), Element, Orientation(..))
import Template.UI.Panel.PhonePortrait as PhonePortrait


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


render : Device -> Config msg -> Element msg
render { class, orientation } (Config config) =
    case ( class, orientation ) of
        ( Phone, Portrait ) ->
            PhonePortrait.render config

        _ ->
            El.none


title : String -> Config msg -> Config msg
title text (Config config) =
    Config { config | title = text }


description : List String -> Config msg -> Config msg
description desc (Config config) =
    Config { config | description = desc }


onClick : Maybe msg -> Config msg -> Config msg
onClick maybeMsg (Config config) =
    Config { config | onClick = maybeMsg }
