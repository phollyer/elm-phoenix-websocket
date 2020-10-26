module Template.Example.Feedback.ApplicableFunctions.Common exposing
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
    [ Background.color Color.white
    , Border.color Color.black
    , Border.width 1
    , El.padding 10
    , El.spacing 10
    ]
