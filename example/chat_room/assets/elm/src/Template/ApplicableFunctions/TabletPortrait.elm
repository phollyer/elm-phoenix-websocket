module Template.ApplicableFunctions.TabletPortrait exposing (..)

import Colors.Opaque as Color
import Element as El exposing (Element)
import Element.Font as Font
import Template.ApplicableFunctions.Common as Common
import UI


view : Common.Config -> Element msg
view { functions } =
    El.column
        Common.containerAttrs
        (List.map UI.functionLink functions)
