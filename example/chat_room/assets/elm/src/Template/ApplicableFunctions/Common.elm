module Template.ApplicableFunctions.Common exposing
    ( Config
    , containerAttrs
    )

import Element as El exposing (Attribute)


type alias Config =
    List String


containerAttrs : List (Attribute msg)
containerAttrs =
    [ El.width El.fill ]
