module Template.ApplicableFunctions.PhonePortrait exposing (..)

import Colors.Opaque as Color
import Element as El exposing (Element)
import Element.Font as Font
import Template.ApplicableFunctions.Common as Common
import UI


view : Common.Config -> Element msg
view { functions } =
    El.column
        [ Font.size 16
        , El.spacing 5
        ]
        (List.map UI.functionLink functions)
