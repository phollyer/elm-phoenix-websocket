module Template.UsefulFunctions.PhonePortrait exposing (view)

import Element as El exposing (Element)
import Template.UsefulFunctions.Common as Common
import UI


view : Common.Config -> Element msg
view { functions } =
    El.column
        (El.spacing 5
            :: Common.containerAttrs
        )
        (List.map
            (\( func, _ ) -> UI.functionLink func)
            functions
        )
