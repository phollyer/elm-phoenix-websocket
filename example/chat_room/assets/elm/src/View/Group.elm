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
import List.Extra as List


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
        | layout = findByClassAndOrientation class orientation config.layouts
    }


orderElementsForDevice :
    Device
    -> Config
    -> { c | elements : List (Element msg) }
    -> { c | elements : List (Element msg) }
orderElementsForDevice { class, orientation } (Config config) c =
    { c
        | elements =
            case findByClassAndOrientation class orientation config.order of
                Nothing ->
                    c.elements

                Just newIndices ->
                    reIndex newIndices c.elements
    }


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
