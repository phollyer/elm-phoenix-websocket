module View.Menu exposing
    ( Config, init
    , view
    , options, selected, group
    )

{-| This module is intended to enable building up a menu with pipelines and
then passing off the menu config to the relevant template.

@docs Config, init

@docs Template, view

@docs options, selected, group

-}

import Element as El exposing (Device, DeviceClass(..), Element, Orientation(..))
import Template.Menu.Desktop as Desktop
import Template.Menu.PhoneLandscape as PhoneLandscape
import Template.Menu.PhonePortrait as PhonePortrait
import Template.Menu.TabletLandscape as TabletLandscape
import View.Group as Group


{-| -}
type Config msg
    = Config
        { options : List ( String, msg )
        , selected : String
        , layout : Maybe (List Int)
        , group : Group.Config
        }


{-| -}
init : Config msg
init =
    Config
        { options = []
        , selected = ""
        , layout = Nothing
        , group = Group.init
        }


{-| -}
view : Device -> Config msg -> Element msg
view ({ class, orientation } as device) (Config config) =
    case ( class, orientation ) of
        ( Phone, Portrait ) ->
            PhonePortrait.view config

        ( Phone, Landscape ) ->
            Group.layoutForDevice device config.group config
                |> PhoneLandscape.view

        ( Tablet, Portrait ) ->
            PhoneLandscape.view config

        ( Tablet, Landscape ) ->
            TabletLandscape.view config

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


{-| -}
group : Group.Config -> Config msg -> Config msg
group group_ (Config config) =
    Config { config | group = group_ }
