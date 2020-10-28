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
            toRow config.elements

        Just layout ->
            El.column attrs <|
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
    El.row
        [ El.alignTop
        ]
        [ El.el
            [ El.centerX ]
            item
        ]
