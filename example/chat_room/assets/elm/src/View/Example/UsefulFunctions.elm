module View.Example.UsefulFunctions exposing
    ( functions
    , init
    , view
    )

import Element as El exposing (Device, DeviceClass(..), Element, Orientation(..))
import Template.UsefulFunctions.PhonePortrait as PhonePortrait


type Config
    = Config { functions : List ( String, String ) }


init : Config
init =
    Config { functions = [] }


view : Device -> Config -> Element msg
view { class, orientation } (Config config) =
    PhonePortrait.view config


functions : List ( String, String ) -> Config -> Config
functions functions_ (Config config) =
    Config { config | functions = functions_ }
