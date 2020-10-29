module Template.Feedback.PhoneLandscape exposing (view)

import Element as El exposing (Element)
import List.Extra as List
import Template.Feedback.Common as Common


view : Common.Config msg c -> Element msg
view config =
    case config.layout of
        Nothing ->
            toRow config.elements

        Just layout ->
            El.column
                Common.containerAttrs
                (List.groupsOfVarying layout config.elements
                    |> List.map toRow
                )


toRow : List (Element msg) -> Element msg
toRow elements =
    El.wrappedRow
        Common.rowAttrs
        (List.map toElement elements)


toElement : Element msg -> Element msg
toElement element =
    El.el
        Common.elementAttrs
        element
