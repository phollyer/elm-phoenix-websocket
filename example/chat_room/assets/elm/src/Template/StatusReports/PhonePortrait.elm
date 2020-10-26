module Template.StatusReports.PhonePortrait exposing (view)

import Colors.Opaque as Color
import Element as El exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font


type alias Config msg c =
    { c
        | title : String
        , reports : List (Element msg)
    }


view : Config msg c -> Element msg
view config =
    El.column
        [ Background.color Color.white
        , Border.color Color.black
        , Border.width 1
        , El.padding 10
        , El.width El.fill
        ]
        [ title config.title
        , reports config.reports
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


reports : List (Element msg) -> Element msg
reports reports_ =
    El.column
        []
        reports_
