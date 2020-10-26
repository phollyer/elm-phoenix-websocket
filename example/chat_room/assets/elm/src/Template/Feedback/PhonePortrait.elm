module Template.Feedback.PhonePortrait exposing (view)

import Colors.Opaque as Color
import Element as El exposing (Attribute, DeviceClass(..), Element, Orientation(..))
import Element.Border as Border
import Extra.List as List
import List.Extra as List
import Template.Feedback.Common as Common


view : Common.Config msg c -> Element msg
view config =
    case List.findByClassAndOrientation Phone Portrait config.layouts of
        Nothing ->
            El.column attrs
                (controls config.elements)

        Just groups ->
            El.column attrs <|
                (List.groupsOfVarying groups config.elements
                    |> List.map
                        (\elements ->
                            El.row
                                [ El.width El.fill ]
                            <|
                                controls elements
                        )
                )


attrs : List (Attribute msg)
attrs =
    List.append
        [ El.spacing 10
        , El.paddingXY 0 10
        ]
        Common.containerAttrs


controls : List (Element msg) -> List (Element msg)
controls elements =
    List.map control elements


control : Element msg -> Element msg
control item =
    El.el [ El.width El.fill ]
        item
