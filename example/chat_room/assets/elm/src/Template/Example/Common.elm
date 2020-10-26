module Template.Example.Common exposing
    ( Config
    , containerAttrs
    , contentAttrs
    , descriptionAttrs
    , functionLink
    , idAttrs
    , idLabelAttrs
    , idValueAttrs
    , introductionAttrs
    , layoutTypeFor
    , toRows
    )

import Colors.Opaque as Color
import Element as El exposing (Attribute, DeviceClass, Element, Orientation)
import Element.Font as Font


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


toRows : (a -> Element msg) -> List a -> (List (Element msg) -> Element msg) -> List Int -> List (Element msg)
toRows toElement elements container rowCount =
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
        |> List.map
            (\row ->
                container <|
                    List.map toElement row
            )


functionLink : String -> Element msg
functionLink function =
    El.newTabLink
        [ Font.family
            [ Font.typeface "Roboto Mono" ]
        ]
        { url = toPackageUrl function
        , label =
            El.paragraph
                []
                (format function)
        }


toPackageUrl : String -> String
toPackageUrl function =
    let
        base =
            "https://package.elm-lang.org/packages/phollyer/elm-phoenix-websocket/latest/Phoenix"
    in
    case String.split "." function of
        _ :: func :: [] ->
            base ++ "#" ++ func

        func :: [] ->
            base ++ "#" ++ func

        _ ->
            base


format : String -> List (Element msg)
format function =
    case String.split "." function of
        phoenix :: func :: [] ->
            [ El.el [ Font.color Color.orange ] (El.text phoenix)
            , El.el [ Font.color Color.darkgrey ] (El.text ("." ++ func))
            ]

        func :: [] ->
            [ El.el [ Font.color Color.darkgrey ] (El.text ("." ++ func))
            ]

        _ ->
            []
