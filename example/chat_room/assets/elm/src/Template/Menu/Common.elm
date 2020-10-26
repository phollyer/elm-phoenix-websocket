module Template.Menu.Common exposing
    ( Config
    , containerAttrs
    , selectedAttrs
    , selectedHighlightAttrs
    , unselectedAttrs
    )

import Colors.Alpha as Alpha
import Colors.Opaque as Color
import Element as El exposing (Attribute, DeviceClass, Element, Orientation)
import Element.Border as Border
import Element.Events as Event
import Element.Font as Font
import Template.Example.Common as Common


type alias Config msg c =
    { c
        | options : List ( String, msg )
        , selected : String
        , layouts : List ( DeviceClass, Orientation, List Int )
    }


containerAttrs : List (Attribute msg)
containerAttrs =
    [ Border.color Color.aliceblue
    , Border.widthEach
        { left = 0
        , top = 1
        , right = 0
        , bottom = 1
        }
    , El.width El.fill
    , Font.family
        [ Font.typeface "Varela Round" ]
    ]


selectedAttrs : List (Attribute msg)
selectedAttrs =
    [ El.centerX
    , El.centerY
    , El.spacing 5
    , Font.color Color.darkslateblue
    ]


selectedHighlightAttrs : List (Attribute msg)
selectedHighlightAttrs =
    [ Border.color Color.aliceblue
    , Border.width 2
    , El.width El.fill
    ]


unselectedAttrs : msg -> List (Attribute msg)
unselectedAttrs msg =
    [ Border.color (Alpha.darkslateblue 0)
    , Border.widthEach
        { left = 0
        , top = 0
        , right = 0
        , bottom = 4
        }
    , El.centerX
    , El.centerY
    , El.pointer
    , El.mouseOver
        [ Border.color Color.lavender ]
    , El.paddingEach
        { left = 0
        , top = 0
        , right = 0
        , bottom = 5
        }
    , Event.onClick msg
    , Font.color Color.darkslateblue
    ]
