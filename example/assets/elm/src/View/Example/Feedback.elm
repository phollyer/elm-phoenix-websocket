module View.Example.Feedback exposing
    ( Config
    , elements
    , group
    , init
    , view
    )

import Device exposing (Device)
import Element as El exposing (DeviceClass(..), Element, Orientation(..))
import List.Extra as List
import View.Group as Group



{- Model -}


type Config msg
    = Config
        { elements : List (Element msg)
        , group : Group.Config
        , layout : Maybe (List Int)
        }


init : Config msg
init =
    Config
        { elements = []
        , group = Group.init
        , layout = Nothing
        }


elements : List (Element msg) -> Config msg -> Config msg
elements list (Config config) =
    Config { config | elements = list }


group : Group.Config -> Config msg -> Config msg
group group_ (Config config) =
    Config { config | group = group_ }



{- View -}


view : Device -> Config msg -> Element msg
view ({ class, orientation } as device) (Config config) =
    case Group.layoutForDevice device config.group of
        Nothing ->
            case ( class, orientation ) of
                ( Phone, Portrait ) ->
                    column
                        (List.map toElement config.elements)

                _ ->
                    wrappedRow config.elements

        Just layout ->
            column
                (Group.orderForDevice device config.elements config.group
                    |> List.groupsOfVarying layout
                    |> List.map wrappedRow
                )


wrappedRow : List (Element msg) -> Element msg
wrappedRow elements_ =
    El.wrappedRow
        [ El.spacing 10
        , El.width El.fill
        ]
        (List.map toElement elements_)


toElement : Element msg -> Element msg
toElement element =
    El.el
        [ El.alignTop
        , El.width El.fill
        ]
        element


column : List (Element msg) -> Element msg
column =
    El.column
        [ El.paddingXY 0 10
        , El.spacing 10
        , El.width El.fill
        ]
