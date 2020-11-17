module View.Group exposing
    ( Config
    , init
    , layoutForDevice
    , layouts
    , order
    , orderForDevice
    )

import Device exposing (Device)
import Element exposing (DeviceClass, Orientation)
import List.Extra as List



{- Model -}


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



{- Helpers -}


layoutForDevice : Device -> Config -> Maybe (List Int)
layoutForDevice device (Config config) =
    findForDevice device config.layouts


orderForDevice : Device -> List item -> Config -> List item
orderForDevice device items (Config config) =
    case findForDevice device config.order of
        Nothing ->
            items

        Just sortOrder ->
            List.indexedMap Tuple.pair items
                |> List.map2 (\newIndex ( _, item ) -> ( newIndex, item )) sortOrder
                |> List.sortBy Tuple.first
                |> List.unzip
                |> Tuple.second



{- Private -}


findForDevice : Device -> List ( DeviceClass, Orientation, a ) -> Maybe a
findForDevice { class, orientation } list =
    List.find (\( class_, orientation_, _ ) -> class_ == class && orientation_ == orientation) list
        |> Maybe.map (\( _, _, a ) -> a)
