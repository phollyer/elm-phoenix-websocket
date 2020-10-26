module Template.Feedback.PhonePortrait exposing (view)

import Colors.Opaque as Color
import Element as El exposing (Attribute, DeviceClass(..), Element, Orientation(..))
import Element.Border as Border
import List.Extra as List
import Template.Feedback.Common as Common


view : Common.Config msg c -> Element msg
view config =
    case List.find (\( class, orientation, _ ) -> class == Phone && orientation == Portrait) config.layouts of
        Nothing ->
            El.column attrs
                (List.map control config.elements)

        Just ( _, _, groups ) ->
            El.column attrs <|
                (List.groupsOfVarying groups config.elements
                    |> List.map
                        (\group ->
                            El.row
                                [ El.width El.fill ]
                            <|
                                List.map control group
                        )
                )


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
