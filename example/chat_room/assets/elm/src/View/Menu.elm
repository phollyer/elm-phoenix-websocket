module View.Menu exposing
    ( Config, init
    , render
    , options, selected
    )

{-| This module is intended to enable building up a menu with pipelines and
then passing off the menu config to the chosen template - currently there is
only one.

@docs Config, init

@docs Template, render

@docs options, selected

-}

import Element as El exposing (Device, DeviceClass(..), Element, Orientation(..))
import Template.Menu.Desktop as Desktop
import Template.Menu.PhoneLandscape as PhoneLandscape
import Template.Menu.PhonePortrait as PhonePortrait


{-| -}
type Config msg
    = Config
        { options : List ( String, msg )
        , selected : String
        }


{-| -}
init : Config msg
init =
    Config
        { options = []
        , selected = ""
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
options : List ( String, msg ) -> Config msg -> Config msg
options options_ (Config config) =
    Config { config | options = options_ }


{-| -}
selected : String -> Config msg -> Config msg
selected selected_ (Config config) =
    Config { config | selected = selected_ }
