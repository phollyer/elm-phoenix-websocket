module Template.ExampleControls.PhonePortrait exposing (view)

import Element as El exposing (Element)
import List.Extra as List
import Template.ExampleControls.Common as Common


view : Common.Config msg c -> Element msg
view config =
    case config.layout of
        Nothing ->
            El.column Common.containerAttrs
                (Common.maybeId config.userId
                    :: config.elements
                )

        Just layout ->
            El.column Common.containerAttrs
                (Common.maybeId config.userId
                    :: (List.groupsOfVarying layout config.elements
                            |> List.map
                                (\elements ->
                                    El.wrappedRow
                                        [ El.spacing 10
                                        , El.centerX
                                        ]
                                        elements
                                )
                       )
                )
