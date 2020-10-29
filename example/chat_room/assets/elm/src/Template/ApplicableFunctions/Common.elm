module Template.ApplicableFunctions.Common exposing
    ( Config
    , containerAttrs
    )

import Element as El exposing (Attribute)


type alias Config =
    { functions : List String }


containerAttrs : List (Attribute msg)
containerAttrs =
    [ El.width El.fill ]
