module Example exposing
    ( Action(..)
    , Config
    , Example(..)
    , description
    , view
    )

import Colors.Opaque as Color
import Element as El exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Page
import Phoenix



{- Model -}


type alias Config msg =
    { example : Example
    , description : Element msg
    , buttons : Element msg
    , requiredFunctions : Element msg
    , usefulFunctions : Element msg
    }


type Action
    = Anything
    | Connect
    | Disconnect


type Example
    = SimpleConnect Action
    | ConnectWithParams Action



{- View -}


view : Element msg -> Element msg -> Element msg -> Element msg -> Element msg
view desc btns applicableFuncs usefulFuncs =
    El.row
        [ El.height El.shrink
        , El.width El.fill
        , El.spacing 20
        ]
        [ El.column
            [ El.height El.fill
            , El.width <| El.fillPortion 1
            , El.spacing 20
            ]
            [ desc
            , btns
            ]
        , applicableFuncs
        , usefulFuncs
        ]


description : List (Element msg) -> Element msg
description desc =
    El.column
        [ El.spacing 12
        , Font.color Color.steelblue
        , Font.justify
        , Font.size 24
        ]
        desc


applicableFunctions : List (Element msg) -> Element msg
applicableFunctions functions =
    El.column
        [ Background.color Color.white
        , Border.width 1
        , Border.color Color.black
        , El.height El.fill
        , El.width <| El.fillPortion 1
        , El.padding 10
        ]
    <|
        El.el
            [ El.centerX ]
            (El.text "Applicable Functions")
            :: functions


usefulFunctions : List (Element msg) -> Element msg
usefulFunctions usefulFuncs =
    El.column
        [ Background.color Color.white
        , Border.width 1
        , Border.color Color.black
        , El.height El.fill
        , El.width <| El.fillPortion 1
        , El.padding 10
        ]
    <|
        El.el
            [ El.centerX ]
            (El.text "Useful Functions")
            :: usefulFuncs
