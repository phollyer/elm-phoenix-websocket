module View.ApplicableFunctions exposing
    ( functions
    , init
    , view
    )

import Element as El exposing (Device, DeviceClass(..), Element, Orientation(..))
import Template.ApplicableFunctions.PhonePortrait as PhonePortrait


type Config
    = Config { functions : List String }


init : Config
init =
    Config { functions = [] }


view : Device -> Config -> Element msg
view { class, orientation } (Config config) =
    PhonePortrait.view config


functions : List String -> Config -> Config
functions functions_ (Config config) =
    Config { config | functions = functions_ }
