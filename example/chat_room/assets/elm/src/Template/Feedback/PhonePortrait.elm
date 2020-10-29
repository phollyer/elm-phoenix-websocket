module Template.Feedback.PhonePortrait exposing (view)

import Element as El exposing (Element)
import List.Extra as List
import Template.Feedback.Common as Common


view : Common.Config msg c -> Element msg
view config =
    case config.layout of
        Nothing ->
            El.column
                Common.containerAttrs
                (List.map toElement config.elements)

        Just layout ->
            El.column
                Common.containerAttrs
                (List.groupsOfVarying layout config.elements
                    |> List.map toRow
                )


toRow : List (Element msg) -> Element msg
toRow elements =
    El.row
        Common.rowAttrs
        (List.map toElement elements)


toElement : Element msg -> Element msg
toElement element =
    El.el
        Common.elementAttrs
        element
