module Template.StatusReports.PhoneLandscape exposing (view)

import Colors.Opaque as Color
import Element as El exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font


type alias Config msg c =
    { c
        | title : String
        , static : List (Element msg)
        , scrollable : List (Element msg)
    }


view : Config msg c -> Element msg
view config =
    El.column
        [ Background.color Color.white
        , Border.color Color.black
        , Border.width 1
        , El.centerX
        , El.padding 10
        , El.spacing 15
        , El.height <|
            El.maximum 350 El.fill
        , El.width El.fill
        , El.clip
        ]
        [ title config.title
        , static config.static
        , scrollable config.scrollable
        ]


title : String -> Element msg
title title_ =
    El.el
        [ El.centerX
        , Font.bold
        , Font.color Color.darkslateblue
        , Font.size 18
        , Font.underline
        ]
        (El.text title_)


scrollable : List (Element msg) -> Element msg
scrollable reports =
    case reports of
        [] ->
            El.none

        _ ->
            El.column
                [ El.height El.fill
                , El.spacing 15
                , Font.size 16
                , El.width El.fill
                , El.explain Debug.todo
                ]
                reports


static : List (Element msg) -> Element msg
static reports =
    case reports of
        [] ->
            El.none

        _ ->
            El.column
                [ El.spacing 15
                , Font.size 16
                ]
                reports
