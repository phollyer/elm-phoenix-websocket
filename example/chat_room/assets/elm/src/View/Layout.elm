module View.Layout exposing
    ( Config, init
    , render
    , homeMsg, title, body
    )

{-| This module is intended to enable building up a page with pipelines and
then passing off the page config to the chosen template.

@docs Config, init

@docs Template, render

@docs homeMsg, title, body

-}

import Element as El exposing (Device, DeviceClass(..), Element, Orientation(..))
import Template.Layout.Desktop as Desktop
import Template.Layout.PhoneLandscape as PhoneLandscape
import Template.Layout.PhonePortrait as PhonePortrait


{-| -}
type Config msg
    = Config
        { homeMsg : Maybe msg
        , title : String
        , body : Element msg
        }


{-| -}
init : Config msg
init =
    Config
        { homeMsg = Nothing
        , title = ""
        , body = El.none
        }


{-| -}
render : Device -> Config msg -> Element msg
render { class, orientation } (Config config) =
    case ( class, orientation ) of
        ( Phone, Portrait ) ->
            PhonePortrait.render config

        ( Phone, Landscape ) ->
            PhoneLandscape.render config

        _ ->
            Desktop.render config


{-| -}
homeMsg : Maybe msg -> Config msg -> Config msg
homeMsg msg (Config config) =
    Config
        { config | homeMsg = msg }


{-| -}
title : String -> Config msg -> Config msg
title text (Config config) =
    Config
        { config | title = text }


{-| -}
body : Element msg -> Config msg -> Config msg
body body_ (Config config) =
    Config
        { config | body = body_ }
