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
            orderElements device config
                |> PhonePortrait.view

        _ ->
            orderElements device config
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


orderElements :
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
orderElements { class, orientation } config =
    { config
        | elements =
            List.foldl
                (\( class_, orientation_, order_ ) elements_ ->
                    if class == class_ && orientation == orientation_ then
                        sortElements order_ elements_

                    else
                        elements_
                )
                config.elements
                config.order
    }


sortElements : List Int -> List (Element msg) -> List (Element msg)
sortElements sortOrder elements_ =
    List.indexedMap Tuple.pair elements_
        |> List.map2
            (\newIndex ( _, element ) -> ( newIndex, element ))
            sortOrder
        |> List.sortBy Tuple.first
        |> List.unzip
        |> Tuple.second