module View.Menu exposing
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
import Template.Menu.Desktop as Desktop
import Template.Menu.PhoneLandscape as PhoneLandscape
import Template.Menu.PhonePortrait as PhonePortrait
import Template.Menu.TabletLandscape as TabletLandscape
import View.Utils as Utils


{-| -}
type Config msg
    = Config
        { options : List ( String, msg )
        , selected : String
        , layout : Maybe (List Int)
        , layouts : List ( DeviceClass, Orientation, List Int )
        }


{-| -}
init : Config msg
init =
    Config
        { options = []
        , selected = ""
        , layout = Nothing
        , layouts = []
        }


{-| -}
view : Device -> Config msg -> Element msg
view ({ class, orientation } as device) (Config config) =
    case ( class, orientation ) of
        ( Phone, Portrait ) ->
            PhonePortrait.view config

        ( Phone, Landscape ) ->
            Utils.layoutForDevice device config
                |> PhoneLandscape.view

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
