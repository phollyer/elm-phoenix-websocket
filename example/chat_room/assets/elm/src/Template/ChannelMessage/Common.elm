module Template.ChannelMessage.Common exposing
    ( Config
    , containerAttrs
    , fieldAttrs
    , labelAttrs
    , valueAttrs
    )

import Colors.Opaque as Color
import Element as El exposing (Attribute)
import Element.Border as Border
import Element.Font as Font
import Json.Encode exposing (Value)


type alias Config c =
    { c
        | topic : String
        , event : String
        , payload : Value
        , joinRef : Maybe String
        , ref : Maybe String
    }


containerAttrs : List (Attribute msg)
containerAttrs =
    [ El.width El.fill
    , El.alignLeft
    , Border.widthEach
        { left = 0
        , top = 0
        , right = 0
        , bottom = 1
        }
    , Border.color Color.skyblue
    , El.paddingEach
        { left = 0
        , top = 0
        , right = 0
        , bottom = 10
        }
    ]


fieldAttrs : List (Attribute msg)
fieldAttrs =
    [ El.width El.fill ]


labelAttrs : List (Attribute msg)
labelAttrs =
    [ El.alignTop
    , Font.color Color.darkslateblue
    ]


valueAttrs : List (Attribute msg)
valueAttrs =
    [ El.width El.fill ]
