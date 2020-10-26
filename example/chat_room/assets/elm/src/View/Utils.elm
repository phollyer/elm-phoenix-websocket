module View.Utils exposing (..)

import Element exposing (Device, DeviceClass, Element, Orientation)
import Extra.List as List


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
