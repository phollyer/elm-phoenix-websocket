module Template.Menu.Common exposing
    ( Config
    , containerAttrs
    , selectedAttrs
    , selectedHighlightAttrs
    , unselectedAttrs
    )

import Colors.Alpha as Alpha
import Colors.Opaque as Color
import Element as El exposing (Attribute)
import Element.Border as Border
import Element.Events as Event
import Element.Font as Font


type alias Config msg c =
    { c
        | options : List String
        , selected : String
        , onClick : Maybe (String -> msg)
        , layout : Maybe (List Int)
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
    , Font.color Color.darkslateblue
    ]


selectedHighlightAttrs : List (Attribute msg)
selectedHighlightAttrs =
    [ Border.color Color.aliceblue
    , Border.widthEach
        { left = 0
        , top = 0
        , right = 0
        , bottom = 4
        }
    , El.width El.fill
    ]


unselectedAttrs : Maybe (String -> msg) -> String -> List (Attribute msg)
unselectedAttrs maybeMsg item =
    let
        attrs =
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
            , Font.color Color.darkslateblue
            ]
    in
    case maybeMsg of
        Just msg ->
            Event.onClick (msg item)
                :: attrs

        Nothing ->
            attrs
