module Template.Feedback.PhonePortrait exposing (view)

import Colors.Opaque as Color
import Element as El exposing (Attribute, DeviceClass(..), Element, Orientation(..))
import Element.Border as Border
import Extra.List as List
import List.Extra as List
import Template.Feedback.Common as Common


view : Common.Config msg c -> Element msg
view config =
    case config.layout of
        Nothing ->
            El.column attrs
                (controls config.elements)

        Just layout ->
            El.column attrs <|
                (List.groupsOfVarying layout config.elements
                    |> List.map
                        (\elements ->
                            El.row
                                [ El.spacing 10
                                , El.width El.fill
                                ]
                            <|
                                controls elements
                        )
                )


attrs : List (Attribute msg)
attrs =
    [ El.spacing 10
    , El.paddingXY 0 10
    , El.width El.fill
    ]


controls : List (Element msg) -> List (Element msg)
controls elements =
    List.map control elements


control : Element msg -> Element msg
control item =
    El.el
        [ El.alignTop
        , El.width El.fill
        ]
        item
