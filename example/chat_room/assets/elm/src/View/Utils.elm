module View.Utils exposing (..)

import Element exposing (Device, DeviceClass, Element, Orientation)
import Extra.List as List


layoutForDevice :
    Device
    ->
        { c
            | layout : Maybe (List Int)
            , layouts : List ( DeviceClass, Orientation, List Int )
        }
    ->
        { c
            | layout : Maybe (List Int)
            , layouts : List ( DeviceClass, Orientation, List Int )
        }
layoutForDevice { class, orientation } config =
    { config
        | layout = List.findByClassAndOrientation class orientation config.layouts
    }


orderElementsForDevice :
    Device
    ->
        { c
            | elements : List (Element msg)
            , order : List ( DeviceClass, Orientation, List Int )
        }
    ->
        { c
            | elements : List (Element msg)
            , order : List ( DeviceClass, Orientation, List Int )
        }
orderElementsForDevice { class, orientation } config =
    { config
        | elements =
            case List.findByClassAndOrientation class orientation config.order of
                Nothing ->
                    config.elements

                Just newIndices ->
                    List.reIndex newIndices config.elements
    }
