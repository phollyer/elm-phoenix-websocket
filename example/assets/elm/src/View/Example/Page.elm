module View.Example.Page exposing
    ( Config
    , example
    , init
    , introduction
    , menu
    , view
    )

import Colors.Opaque as Color
import Element as El exposing (Attribute, Device, DeviceClass(..), Element, Orientation(..))
import Element.Font as Font



{- Model -}


type Config msg
    = Config
        { introduction : List (List (Element msg))
        , menu : Element msg
        , example : Element msg
        }


init : Config msg
init =
    Config
        { introduction = []
        , menu = El.none
        , example = El.none
        }


introduction : List (List (Element msg)) -> Config msg -> Config msg
introduction intro (Config config) =
    Config { config | introduction = intro }


menu : Element msg -> Config msg -> Config msg
menu menu_ (Config config) =
    Config { config | menu = menu_ }


example : Element msg -> Config msg -> Config msg
example example_ (Config config) =
    Config { config | example = example_ }



{- View -}


view : Device -> Config msg -> Element msg
view device (Config config) =
    El.column
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
        [ introductionView device config.introduction
        , menuView device config.menu
        , exampleView device config.example
        ]



{- Introduction -}


introductionView : Device -> List (List (Element msg)) -> Element msg
introductionView device intro =
    case intro of
        [] ->
            El.none

        _ ->
            El.column
                [ fontSize device
                , spacing device
                , Font.color Color.darkslateblue
                , Font.family
                    [ Font.typeface "Piedra" ]
                , Font.justify
                ]
            <|
                List.map
                    (\paragraph ->
                        El.paragraph
                            [ El.width El.fill
                            , El.spacing 10
                            ]
                            paragraph
                    )
                    intro



{- Menu -}


menuView : Device -> Element msg -> Element msg
menuView device element =
    if element == El.none then
        El.none

    else
        El.el
            [ fontSize device
            , El.width El.fill
            ]
            element



{- Example -}


exampleView : Device -> Element msg -> Element msg
exampleView device content =
    El.el
        [ fontSize device
        , El.spacing 12
        , Font.color Color.darkslateblue
        , Font.justify
        , Font.family
            [ Font.typeface "Varela Round" ]
        , El.height El.fill
        , El.width El.fill
        ]
        content



{- Attributes -}


fontSize : Device -> Attribute msg
fontSize { class } =
    case class of
        Phone ->
            Font.size 14

        _ ->
            Font.size 18


spacing : Device -> Attribute msg
spacing { class } =
    case class of
        Phone ->
            El.spacing 18

        _ ->
            El.spacing 22
