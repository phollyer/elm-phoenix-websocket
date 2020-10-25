module Template.Example.Controls.Common exposing
    ( Config
    , containerAttrs
    , maybeId
    )

import Colors.Opaque as Color
import Element as El exposing (Attribute, DeviceClass(..), Element, Orientation(..))
import Element.Border as Border
import Element.Font as Font
import Template.Example.Common as Common


type alias Config msg c =
    { c
        | userId : Maybe String
        , elements : List (Element msg)
        , layouts : List ( DeviceClass, Orientation, List Int )
    }


containerAttrs : List (Attribute msg)
containerAttrs =
    [ El.width El.fill
    , El.scrollbarY
    , Border.color Color.aliceblue
    ]



{- User ID -}


maybeId : String -> Maybe String -> Element msg
maybeId type_ maybeId_ =
    case maybeId_ of
        Nothing ->
            El.none

        Just id ->
            El.paragraph
                (Font.size 20
                    :: Common.idAttrs
                )
                [ El.el Common.idLabelAttrs (El.text (type_ ++ " ID: "))
                , El.el Common.idValueAttrs (El.text id)
                ]
