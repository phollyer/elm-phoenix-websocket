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
    , rows
    , toRows
    )

import Colors.Opaque as Color
import Element as El exposing (Attribute, DeviceClass, Element, Orientation)
import Element.Font as Font


type alias Config msg c =
    { c
        | applicableFunctions : List String
        , controls : Element msg
        , description : List (Element msg)
        , id : Maybe String
        , info : List (Element msg)
        , introduction : List (Element msg)
        , menu : Element msg
        , remoteControls : List ( String, List (Element msg) )
        , usefulFunctions : List ( String, String )
        , userId : Maybe String
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


rows : (a -> Element msg) -> List a -> (List (Element msg) -> Element msg) -> List Int -> List (Element msg)
rows toElement elements container rowCount =
    toRows rowCount elements
        |> List.map
            (\row ->
                container <|
                    List.map toElement row
            )


toRows : List Int -> List a -> List (List a)
toRows rowCount elements =
    List.foldl
        (\num ( elements_, rows_ ) ->
            ( List.drop num elements_
            , List.take num elements_ :: rows_
            )
        )
        ( elements, [] )
        rowCount
        |> Tuple.second
        |> List.reverse
