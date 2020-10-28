module Template.Feedback.PhoneLandscape exposing (view)

import Colors.Opaque as Color
import Element as El exposing (Attribute, DeviceClass(..), Element, Orientation(..))
import Element.Border as Border
import Extra.List as List
import List.Extra as List
import Template.Feedback.Common as Common


view : Common.Config msg c -> Element msg
view config =
    let
        _ =
            Debug.log "" config.layout
    in
    case config.layout of
        Nothing ->
            El.wrappedRow attrs
                (controls config.elements)

        Just layout ->
            El.column attrs <|
                (List.groupsOfVarying layout config.elements
                    |> List.map
                        (\elements ->
                            El.row
                                [ El.spacing 10
                                , El.centerX
                                ]
                            <|
                                controls elements
                        )
                )


attrs : List (Attribute msg)
attrs =
    [ El.spacing 10
    , El.paddingXY 0 10
    , El.centerX
    ]


controls : List (Element msg) -> List (Element msg)
controls elements =
    List.map control elements


control : Element msg -> Element msg
control item =
    El.row
        [ El.width El.fill ]
        [ El.el
            [ El.alignTop
            , El.centerX
            ]
            item
        ]
