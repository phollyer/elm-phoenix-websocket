module View.Menu exposing
    ( Config
    , group
    , init
    , onClick
    , options
    , selected
    , view
    )

import Colors.Alpha as Alpha
import Colors.Opaque as Color
import Device exposing (Device)
import Element as El exposing (Attribute, DeviceClass(..), Element, Orientation(..))
import Element.Border as Border
import Element.Events as Event
import Element.Font as Font
import List.Extra as List
import View exposing (andMaybeEventWithArg)
import View.Group as Group



{- Model -}


type Config msg
    = Config
        { options : List String
        , selected : String
        , onClick : Maybe (String -> msg)
        , layout : Maybe (List Int)
        , group : Group.Config
        }


init : Config msg
init =
    Config
        { options = []
        , selected = ""
        , onClick = Nothing
        , layout = Nothing
        , group = Group.init
        }


options : List String -> Config msg -> Config msg
options options_ (Config config) =
    Config { config | options = options_ }


selected : String -> Config msg -> Config msg
selected selected_ (Config config) =
    Config { config | selected = selected_ }


onClick : Maybe (String -> msg) -> Config msg -> Config msg
onClick msg (Config config) =
    Config { config | onClick = msg }


group : Group.Config -> Config msg -> Config msg
group group_ (Config config) =
    Config { config | group = group_ }



{- View -}


view : Device -> Config msg -> Element msg
view ({ class, orientation } as device) (Config config) =
    case ( class, orientation ) of
        ( Phone, Portrait ) ->
            El.column (containerAttrs device) <|
                List.map (menuItem config.selected config.onClick) config.options

        _ ->
            case Group.layoutForDevice device config.group of
                Nothing ->
                    El.row
                        [ El.paddingEach
                            { left = 5
                            , top = 0
                            , right = 5
                            , bottom = 0
                            }
                        , spacing device
                        , Border.color Color.aliceblue
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
                    <|
                        List.map (rowItem config.selected config.onClick) config.options

                Just layout ->
                    El.column (containerAttrs device) <|
                        (Group.orderForDevice device config.options config.group
                            |> List.groupsOfVarying layout
                            |> toRows config.selected config.onClick
                        )


toRows : String -> Maybe (String -> msg) -> List (List String) -> List (Element msg)
toRows selected_ maybeOnClick options_ =
    List.map (toRow selected_ maybeOnClick) options_


toRow : String -> Maybe (String -> msg) -> List String -> Element msg
toRow selected_ maybeOnClick options_ =
    El.wrappedRow
        [ El.width El.fill
        , El.spacing 20
        ]
        (List.map (menuItem selected_ maybeOnClick) options_)


menuItem : String -> Maybe (String -> msg) -> String -> Element msg
menuItem selected_ maybeOnClick item =
    let
        ( attrs, highlight ) =
            if selected_ == item then
                ( [ El.centerX
                  , El.centerY
                  , Font.color Color.darkslateblue
                  ]
                , El.el
                    [ Border.color Color.aliceblue
                    , Border.widthEach
                        { left = 0
                        , top = 0
                        , right = 0
                        , bottom = 4
                        }
                    , El.width El.fill
                    ]
                    El.none
                )

            else
                ( [ Border.color (Alpha.darkslateblue 0)
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
                    |> andMaybeEventWithArg maybeOnClick item Event.onClick
                , El.none
                )
    in
    El.column
        attrs
        [ El.text item
        , highlight
        ]


rowItem : String -> Maybe (String -> msg) -> String -> Element msg
rowItem selected_ maybeOnClick item =
    let
        attrs =
            if selected_ == item then
                [ Border.color Color.aliceblue ]

            else
                [ Border.color (Alpha.darkslateblue 0)
                , El.pointer
                , El.mouseOver
                    [ Border.color Color.lavender ]
                ]
                    |> andMaybeEventWithArg maybeOnClick item Event.onClick
    in
    El.el
        (List.append
            attrs
            [ Border.widthEach
                { left = 0
                , top = 4
                , right = 0
                , bottom = 4
                }
            , El.paddingXY 0 5
            , El.centerX
            , Font.color Color.darkslateblue
            ]
        )
        (El.text item)



{- Attributes -}


containerAttrs : Device -> List (Attribute msg)
containerAttrs device =
    [ paddingEach device
    , spacing device
    , Border.color Color.aliceblue
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


selectedItemAttrs : Device -> List (Attribute msg)
selectedItemAttrs { class, orientation } =
    case ( class, orientation ) of
        ( Phone, Portrait ) ->
            [ El.centerX
            , El.centerY
            , Font.color Color.darkslateblue
            ]

        ( Phone, Landscape ) ->
            [ El.centerX
            , El.centerY
            , Font.color Color.darkslateblue
            ]

        _ ->
            [ El.centerX
            , El.centerY
            , Font.color Color.darkslateblue
            ]


paddingEach : Device -> Attribute msg
paddingEach { class, orientation } =
    case ( class, orientation ) of
        ( Phone, _ ) ->
            El.paddingEach
                { left = 5
                , top = 16
                , right = 5
                , bottom = 8
                }

        ( Tablet, Portrait ) ->
            El.paddingEach
                { left = 5
                , top = 16
                , right = 5
                , bottom = 8
                }

        _ ->
            El.paddingEach
                { left = 5
                , top = 10
                , right = 5
                , bottom = 0
                }


spacing : Device -> Attribute msg
spacing { class } =
    case class of
        Phone ->
            El.spacing 10

        Tablet ->
            El.spacing 10

        _ ->
            El.spacing 20
