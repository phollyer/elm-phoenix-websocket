module Template.UsefulFunctions.PhoneLandscape exposing (view)

import Element as El exposing (Element)
import Template.UsefulFunctions.Common as Common
import UI


view : Common.Config -> Element msg
view { functions } =
    El.column
        (El.spacing 5
            :: Common.containerAttrs
        )
    <|
        El.row
            Common.headingAttrs
            [ El.el
                []
                (El.text "Function")
            , El.el
                [ El.alignRight ]
                (El.text "Current Value")
            ]
            :: toRows functions


toRows : List ( String, String ) -> List (Element msg)
toRows rows =
    List.map toRow rows


toRow : ( String, String ) -> Element msg
toRow ( function, currentValue ) =
    El.wrappedRow
        (El.spacing 10
            :: Common.rowAttrs
        )
        [ UI.functionLink function
        , El.el [ El.alignRight ] (El.text currentValue)
        ]
