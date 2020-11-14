module View.Layout exposing
    ( Config, init
    , view
    , homeMsg, title, body
    )

{-| This module is intended to enable building up a page with pipelines and
then passing off the page config to the chosen template.

@docs Config, init

@docs Template, view

@docs homeMsg, title, body

-}

import Device exposing (Device)
import Element as El exposing (DeviceClass(..), Element, Orientation(..))
import Template.Layout.PhoneLandscape as PhoneLandscape
import Template.Layout.PhonePortrait as PhonePortrait
import Template.Layout.Tablet as Tablet


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
view : Device -> Config msg -> Element msg
view { class, orientation } (Config config) =
    case ( class, orientation ) of
        ( Phone, Portrait ) ->
            PhonePortrait.view config

        ( Phone, Landscape ) ->
            PhoneLandscape.view config

        _ ->
            Tablet.view config


{-| -}
homeMsg : Maybe msg -> Config msg -> Config msg
homeMsg msg (Config config) =
    Config { config | homeMsg = msg }


{-| -}
title : String -> Config msg -> Config msg
title text (Config config) =
    Config { config | title = text }


{-| -}
body : Element msg -> Config msg -> Config msg
body body_ (Config config) =
    Config { config | body = body_ }
