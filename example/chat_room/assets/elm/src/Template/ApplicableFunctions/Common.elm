module Template.ApplicableFunctions.Common exposing
    ( Config
    , containerAttrs
    )

import Colors.Opaque as Color
import Element as El exposing (Attribute)
import Element.Background as Background
import Element.Border as Border


type alias Config =
    { functions : List String }


containerAttrs : List (Attribute msg)
containerAttrs =
    [ El.spacing 5
    , El.width El.fill
    ]
