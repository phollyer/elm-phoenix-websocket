module Template.Feedback.PhonePortrait exposing (view)

import Colors.Opaque as Color
import Element as El exposing (Attribute, DeviceClass(..), Element, Orientation(..))
import Element.Border as Border
import Template.Example.Common exposing (layoutTypeFor, toRows)
import Template.Feedback.Common as Common


view : Common.Config msg c -> Element msg
view config =
    case layoutTypeFor Phone Portrait config.layouts of
        Nothing ->
            El.column attrs
                (List.map control config.elements)

        Just rows ->
            El.column attrs
                config.elements


attrs : List (Attribute msg)
attrs =
    List.append
        [ El.spacing 10
        , El.paddingXY 0 10
        ]
        Common.containerAttrs


control : Element msg -> Element msg
control item =
    El.el [ El.width El.fill ]
        item
