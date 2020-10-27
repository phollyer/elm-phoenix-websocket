module Template.Group.Common exposing
    ( Config
    , containerAttrs
    )

import Colors.Opaque as Color
import Element as El exposing (Attribute, DeviceClass, Element, Orientation)
import Element.Border as Border


type alias Config msg c =
    { c
        | elements : List (Element msg)
        , layout : Maybe (List Int)
        , layouts : List ( DeviceClass, Orientation, List Int )
    }


containerAttrs : List (Attribute msg)
containerAttrs =
    [ El.width El.fill
    , El.scrollbarY
    ]
