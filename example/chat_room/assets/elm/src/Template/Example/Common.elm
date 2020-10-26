module Template.Example.Common exposing
    ( Config
    , containerAttrs
    , contentAttrs
    , descriptionAttrs
    , idAttrs
    , idLabelAttrs
    , idValueAttrs
    , introductionAttrs
    , layoutTypeFor
    )

import Colors.Opaque as Color
import Element as El exposing (Attribute, DeviceClass, Element, Orientation)
import Element.Font as Font
import List.Extra as List


type alias Config msg c =
    { c
        | id : Maybe String
        , introduction : List (Element msg)
        , menu : Element msg
        , description : List (Element msg)
        , controls : Element msg
        , remoteControls : List (Element msg)
        , feedback : Element msg
        , info : List (Element msg)
    }


containerAttrs : List (Attribute msg)
containerAttrs =
    [ El.height El.fill
    , El.width El.fill
    , El.spacing 10
    , El.paddingEach
        { left = 0
        , top = 0
        , right = 0
        , bottom = 10
        }
    ]


contentAttrs : List (Attribute msg)
contentAttrs =
    [ El.width El.fill
    , El.spacing 20
    ]


introductionAttrs : List (Attribute msg)
introductionAttrs =
    [ Font.color Color.darkslateblue
    , Font.justify
    , Font.family
        [ Font.typeface "Piedra" ]
    ]


descriptionAttrs : List (Attribute msg)
descriptionAttrs =
    [ El.spacing 12
    , Font.color Color.darkslateblue
    , Font.justify
    , Font.family
        [ Font.typeface "Varela Round" ]
    ]


idAttrs : List (Attribute msg)
idAttrs =
    [ Font.center
    , Font.family
        [ Font.typeface "Varela Round" ]
    ]


idLabelAttrs : List (Attribute msg)
idLabelAttrs =
    [ Font.color Color.lavender ]


idValueAttrs : List (Attribute msg)
idValueAttrs =
    [ Font.color Color.powderblue ]


layoutTypeFor : DeviceClass -> Orientation -> List ( DeviceClass, Orientation, List Int ) -> Maybe (List Int)
layoutTypeFor class orientation layouts =
    List.filterMap
        (\( class_, orientation_, rows_ ) ->
            if class == class_ && orientation == orientation_ then
                Just rows_

            else
                Nothing
        )
        layouts
        |> List.head
