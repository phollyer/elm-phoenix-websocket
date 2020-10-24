module View.Example.Menu exposing
    ( Config, init
    , view
    , options, selected
    , layouts
    )

{-| This module is intended to enable building up a menu with pipelines and
then passing off the menu config to the relevant template.

@docs Config, init

@docs Template, view

@docs options, selected

-}

import Element as El exposing (Device, DeviceClass(..), Element, Orientation(..))
import Template.Example.Menu.Desktop as Desktop
import Template.Example.Menu.PhoneLandscape as PhoneLandscape
import Template.Example.Menu.PhonePortrait as PhonePortrait
import Template.Example.Menu.TabletLandscape as TabletLandscape


{-| -}
type Config msg
    = Config
        { options : List ( String, msg )
        , selected : String
        , layouts : List ( DeviceClass, Orientation, List Int )
        }


{-| -}
init : Config msg
init =
    Config
        { options = []
        , selected = ""
        , layouts = []
        }


{-| -}
view : Device -> Config msg -> Element msg
view { class, orientation } (Config config) =
    case ( class, orientation ) of
        ( Phone, Portrait ) ->
            PhonePortrait.view config

        ( Phone, Landscape ) ->
            PhoneLandscape.view config

        ( Tablet, Portrait ) ->
            PhoneLandscape.view config

        _ ->
            TabletLandscape.view config


{-| -}
options : List ( String, msg ) -> Config msg -> Config msg
options options_ (Config config) =
    Config { config | options = options_ }


{-| -}
selected : String -> Config msg -> Config msg
selected selected_ (Config config) =
    Config { config | selected = selected_ }


{-| -}
layouts : List ( DeviceClass, Orientation, List Int ) -> Config msg -> Config msg
layouts layouts_ (Config config) =
    Config { config | layouts = layouts_ }
