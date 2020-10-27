module Template.StatusReport.PhonePortrait exposing
    ( Config
    , view
    )

import Element as El exposing (Element)


type alias Config msg c =
    { c
        | title : Maybe String
        , label : String
        , element : Element msg
    }


view : Config msg c -> Element msg
view config =
    El.column
        [ El.width El.fill
        , El.spacing 10
        ]
        [ title config.title
        , El.row
            [ El.spacing 10
            , El.width El.fill
            ]
            [ label config.label
            , element config.element
            ]
        ]


title : Maybe String -> Element msg
title maybeTitle =
    case maybeTitle of
        Nothing ->
            El.none

        Just title_ ->
            El.text title_


label : String -> Element msg
label label_ =
    El.text label_


element : Element msg -> Element msg
element value_ =
    value_
