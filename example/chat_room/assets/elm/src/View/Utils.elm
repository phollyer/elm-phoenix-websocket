module View.Utils exposing (..)

import Element exposing (Device, DeviceClass, Element, Orientation)
import Extra.List as List


orderElementsForDevice : Device -> List ( DeviceClass, Orientation, List Int ) -> List (Element msg) -> List (Element msg)
orderElementsForDevice { class, orientation } order elements =
    case List.findByClassAndOrientation class orientation order of
        Nothing ->
            elements

        Just newIndices ->
            List.reIndex newIndices elements
