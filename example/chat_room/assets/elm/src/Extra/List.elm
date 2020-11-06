module Extra.List exposing
    ( findByClassAndOrientation
    , reIndex
    )

import Element exposing (DeviceClass, Orientation)
import List.Extra as List


findByClassAndOrientation : DeviceClass -> Orientation -> List ( DeviceClass, Orientation, a ) -> Maybe a
findByClassAndOrientation class orientation list =
    List.find (\( c, o, _ ) -> c == class && o == orientation) list
        |> Maybe.map (\( _, _, a ) -> a)


reIndex : List Int -> List a -> List a
reIndex sortOrder elements_ =
    List.indexedMap Tuple.pair elements_
        |> List.map2
            (\newIndex ( _, element ) -> ( newIndex, element ))
            sortOrder
        |> List.sortBy Tuple.first
        |> List.unzip
        |> Tuple.second
