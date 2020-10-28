module Template.Feedback.PhoneLandscape exposing (view)

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
            toRow config.elements

        Just layout ->
            El.column
                [ El.spacing 10
                , El.paddingXY 0 10
                , El.width El.fill
                ]
            <|
                (List.groupsOfVarying layout config.elements
                    |> toRows
                )


toRows : List (List (Element msg)) -> List (Element msg)
toRows rows =
    List.map toRow rows


toRow : List (Element msg) -> Element msg
toRow elements =
    El.wrappedRow
        [ El.spacing 10
        , El.width El.fill
        ]
    <|
        List.map
            (\element ->
                El.el
                    [ El.alignTop
                    , El.width El.fill
                    ]
                    element
            )
            elements
