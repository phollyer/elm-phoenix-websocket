module View.Feedback exposing
    ( Config
    , elements
    , init
    , layouts
    , order
    , view
    )

import Element exposing (Device, DeviceClass, Element, Orientation)
import Template.Feedback.PhonePortrait as PhonePortrait
import View.Utils as Utils


type Config msg
    = Config
        { elements : List (Element msg)
        , layouts : List ( DeviceClass, Orientation, List Int )
        , order : List ( DeviceClass, Orientation, List Int )
        , layout : Maybe (List Int)
        }


init : Config msg
init =
    Config
        { elements = []
        , layouts = []
        , layout = Nothing
        , order = []
        }


view : Device -> Config msg -> Element msg
view device (Config config) =
    Utils.orderElementsForDevice device config
        |> Utils.layoutForDevice device
        |> PhonePortrait.view


elements : List (Element msg) -> Config msg -> Config msg
elements list (Config config) =
    Config { config | elements = list }


layouts : List ( DeviceClass, Orientation, List Int ) -> Config msg -> Config msg
layouts list (Config config) =
    Config { config | layouts = list }


order : List ( DeviceClass, Orientation, List Int ) -> Config msg -> Config msg
order list (Config config) =
    Config { config | order = list }
