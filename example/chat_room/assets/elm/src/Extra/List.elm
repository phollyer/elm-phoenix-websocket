module Extra.List exposing (..)

import Element exposing (DeviceClass, Orientation)
import List.Extra as List


findByClassAndOrientation : DeviceClass -> Orientation -> List ( DeviceClass, Orientation, a ) -> Maybe a
findByClassAndOrientation class orientation list =
    case List.find (\( c, o, _ ) -> c == class && o == orientation) list of
        Nothing ->
            Nothing

        Just ( _, _, a ) ->
            Just a
