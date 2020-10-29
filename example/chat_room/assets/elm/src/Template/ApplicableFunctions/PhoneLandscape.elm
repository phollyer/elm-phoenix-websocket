module Template.ApplicableFunctions.PhoneLandscape exposing (view)

import Element as El exposing (Element)
import Template.ApplicableFunctions.Common as Common
import UI


view : Common.Config -> Element msg
view { functions } =
    El.column
        (El.spacing 10
            :: Common.containerAttrs
        )
        (List.map UI.functionLink functions)
