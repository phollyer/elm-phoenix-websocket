module View.Utils exposing
    ( code
    , paragraph
    )

import Colors.Opaque as Color
import Element as El exposing (Device, DeviceClass, Element, Orientation)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font


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
