module Template.StatusReport.PhonePortrait exposing (view)

import Element as El exposing (Element)


type alias Config msg c =
    { c
        | title : String
        , report : Element msg
    }


view : Config msg c -> Element msg
view config =
    El.column
        []
        [ title config.title
        , report config.report
        ]


title : String -> Element msg
title title_ =
    El.text title_


report : Element msg -> Element msg
report report_ =
    report_
