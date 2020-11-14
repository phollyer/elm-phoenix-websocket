module View.Group exposing
    ( Config
    , init
    , layoutForDevice
    , layouts
    , order
    , orderElementsForDevice
    )

import Device exposing (Device)
import Element exposing (DeviceClass, Element, Orientation)
import Extra.List as List


type Config
    = Config
        { layouts : List ( DeviceClass, Orientation, List Int )
        , order : List ( DeviceClass, Orientation, List Int )
        }


init : Config
init =
    Config
        { layouts = []
        , order = []
        }


layouts : List ( DeviceClass, Orientation, List Int ) -> Config -> Config
layouts list (Config config) =
    Config { config | layouts = list }


order : List ( DeviceClass, Orientation, List Int ) -> Config -> Config
order list (Config config) =
    Config { config | order = list }


layoutForDevice :
    Device
    -> Config
    -> { c | layout : Maybe (List Int) }
    -> { c | layout : Maybe (List Int) }
layoutForDevice { class, orientation } (Config config) c =
    { c
        | layout = List.findByClassAndOrientation class orientation config.layouts
    }


orderElementsForDevice :
    Device
    -> Config
    -> { c | elements : List (Element msg) }
    -> { c | elements : List (Element msg) }
orderElementsForDevice { class, orientation } (Config config) c =
    { c
        | elements =
            case List.findByClassAndOrientation class orientation config.order of
                Nothing ->
                    c.elements

                Just newIndices ->
                    List.reIndex newIndices c.elements
    }
