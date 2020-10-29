module Template.ExampleControls.PhoneLandscape exposing (view)

import Element as El exposing (Element)
import List.Extra as List
import Template.ExampleControls.Common as Common


view : Common.Config msg c -> Element msg
view config =
    case config.layout of
        Nothing ->
            El.column Common.containerAttrs
                (Common.maybeId config.userId
                    :: [ toRow config.elements ]
                )

        Just layout ->
            El.column Common.containerAttrs
                (Common.maybeId config.userId
                    :: (List.groupsOfVarying layout config.elements
                            |> List.map
                                (\elements ->
                                    El.wrappedRow
                                        Common.rowAttrs
                                        [ toRow elements ]
                                )
                       )
                )


toRow : List (Element msg) -> Element msg
toRow elements =
    El.row
        [ El.width El.fill
        , El.spacing 10
        ]
        elements
