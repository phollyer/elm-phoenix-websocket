module View.ExampleControls exposing
    ( Config
    , elements
    , group
    , init
    , userId
    , view
    )

import Colors.Opaque as Color
import Device exposing (Device)
import Element as El exposing (DeviceClass(..), Element, Orientation(..))
import Element.Border as Border
import Element.Font as Font
import List.Extra as List
import View.Group as Group



{- Model -}


type Config msg
    = Config
        { userId : Maybe String
        , elements : List (Element msg)
        , layout : Maybe (List Int)
        , group : Group.Config
        }


init : Config msg
init =
    Config
        { userId = Nothing
        , elements = []
        , layout = Nothing
        , group = Group.init
        }


userId : Maybe String -> Config msg -> Config msg
userId maybeUserId (Config config) =
    Config { config | userId = maybeUserId }


elements : List (Element msg) -> Config msg -> Config msg
elements list (Config config) =
    Config { config | elements = list }


group : Group.Config -> Config msg -> Config msg
group group_ (Config config) =
    Config { config | group = group_ }



{- View -}


view : Device -> Config msg -> Element msg
view ({ class, orientation } as device) (Config config) =
    let
        newConfig =
            Group.orderElementsForDevice device config.group config
                |> Group.layoutForDevice device config.group
    in
    case newConfig.layout of
        Nothing ->
            column
                [ maybeId newConfig.userId
                , toRow newConfig.elements
                ]

        Just layout ->
            column
                (maybeId newConfig.userId
                    :: toRows layout newConfig.elements
                )


column : List (Element msg) -> Element msg
column =
    El.column
        [ Border.color Color.aliceblue
        , Border.widthEach
            { left = 0
            , top = 1
            , right = 0
            , bottom = 1
            }
        , El.paddingXY 0 10
        , El.scrollbarY
        , El.spacing 10
        , El.width El.fill
        ]


maybeId : Maybe String -> Element msg
maybeId maybeId_ =
    case maybeId_ of
        Nothing ->
            El.none

        Just id ->
            El.paragraph
                [ Font.family
                    [ Font.typeface "Varela Round" ]
                ]
                [ El.el
                    [ Font.color Color.lavender ]
                    (El.text "User ID: ")
                , El.el
                    [ Font.color Color.powderblue ]
                    (El.text id)
                ]


toRows : List Int -> List (Element msg) -> List (Element msg)
toRows layout elements_ =
    List.groupsOfVarying layout elements_
        |> List.map
            (\elements__ ->
                El.wrappedRow
                    [ El.spacing 10
                    , El.centerX
                    ]
                    [ toRow elements__ ]
            )


toRow : List (Element msg) -> Element msg
toRow elements_ =
    El.row
        [ El.width El.fill
        , El.spacing 10
        ]
        elements_
