module View.Utils exposing
    ( code
    , layoutForDevice
    , orderElementsForDevice
    , paragraph
    )

import Colors.Opaque as Color
import Element as El exposing (Device, DeviceClass, Element, Orientation)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
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


code : Device -> String -> Element msg
code device text =
    El.el
        [ Font.family [ Font.typeface "Roboto Mono" ]
        , Background.color Color.lightgrey
        , El.padding 2
        , Border.width 1
        , Border.color Color.black
        , Font.size 16
        , Font.color Color.black
        ]
        (El.text text)


paragraph : List (Element msg) -> Element msg
paragraph content =
    El.paragraph
        [ El.spacing 10 ]
        content
