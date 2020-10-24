module View.Menu exposing
    ( Config, init
    , view
    , options, selected
    )

{-| This module is intended to enable building up a menu with pipelines and
then passing off the menu config to the relevant template.

@docs Config, init

@docs Template, view

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
view : Device -> Config msg -> Element msg
view { class, orientation } (Config config) =
    case ( class, orientation ) of
        ( Phone, Portrait ) ->
            PhonePortrait.view config

        ( Phone, Landscape ) ->
            PhoneLandscape.view config

        _ ->
            Desktop.view config


{-| -}
options : List ( String, msg ) -> Config msg -> Config msg
options options_ (Config config) =
    Config { config | options = options_ }


{-| -}
selected : String -> Config msg -> Config msg
selected selected_ (Config config) =
    Config { config | selected = selected_ }
