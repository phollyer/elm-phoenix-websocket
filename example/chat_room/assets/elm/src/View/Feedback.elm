module View.Feedback exposing
    ( Config
    , elements
    , init
    , layouts
    , order
    , view
    )

import Element exposing (Device, DeviceClass(..), Element, Orientation(..))
import Template.Feedback.PhonePortrait as PhonePortrait
import View.Utils as Utils


type Config msg
    = Config
        { elements : List (Element msg)
        , layouts : List ( DeviceClass, Orientation, List Int )
        , order : List ( DeviceClass, Orientation, List Int )
        }


init : Config msg
init =
    Config
        { elements = []
        , layouts = []
        , order = []
        }


view : Device -> Config msg -> Element msg
view ({ class, orientation } as device) (Config config) =
    case ( class, orientation ) of
        ( Phone, Portrait ) ->
            Utils.orderElementsForDevice device config
                |> PhonePortrait.view

        _ ->
            Utils.orderElementsForDevice device config
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
