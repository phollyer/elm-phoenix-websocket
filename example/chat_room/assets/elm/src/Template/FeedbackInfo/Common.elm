module Template.FeedbackInfo.Common exposing
    ( Config
    , containerAttrs
    , fieldAttrs
    , labelAttrs
    , maybe
    , valueAttrs
    )

import Colors.Opaque as Color
import Element as El exposing (Attribute, Element)
import Element.Font as Font
import Json.Encode exposing (Value)


type alias Config c =
    { c
        | topic : String
        , event : Maybe String
        , payload : Value
        , joinRef : Maybe String
        , ref : Maybe String
    }


containerAttrs : List (Attribute msg)
containerAttrs =
    [ El.width El.fill
    , El.alignLeft
    , El.paddingEach
        { left = 0
        , top = 0
        , right = 0
        , bottom = 10
        }
    , Font.family [ Font.typeface "Roboto Mono" ]
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
    [ Font.color Color.black ]


maybe : (String -> String -> Element msg) -> String -> Maybe String -> Element msg
maybe field label maybeValue =
    case maybeValue of
        Just value ->
            field label value

        Nothing ->
            El.none
