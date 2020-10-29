module Template.ExampleControls.PhoneLandscape exposing (..)

import Colors.Opaque as Color
import Element as El exposing (Attribute, DeviceClass, Element, Orientation)
import Element.Border as Border
import Extra.List as List
import List.Extra as List
import Template.ExampleControls.Common as Common


view : Common.Config msg c -> Element msg
view config =
    case config.layout of
        Nothing ->
            El.column Common.containerAttrs
                (userId config.userId
                    :: [ toRow config.elements ]
                )

        Just layout ->
            El.column Common.containerAttrs
                (userId config.userId
                    :: (List.groupsOfVarying layout config.elements
                            |> List.map
                                (\elements ->
                                    El.wrappedRow
                                        [ El.spacing 10
                                        , El.centerX
                                        ]
                                    <|
                                        [ toRow elements ]
                                )
                       )
                )


userId : Maybe String -> Element msg
userId maybeId =
    El.el [] (Common.maybeId "User" maybeId)


toRow : List (Element msg) -> Element msg
toRow elements =
    El.row
        [ El.width El.fill
        , El.spacing 10
        ]
    <|
        List.map element elements


element : Element msg -> Element msg
element item =
    El.el [ El.centerX ] item
