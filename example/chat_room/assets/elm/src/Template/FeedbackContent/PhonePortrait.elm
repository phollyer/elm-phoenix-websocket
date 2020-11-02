module Template.FeedbackContent.PhonePortrait exposing
    ( Config
    , view
    )

import Colors.Opaque as Color
import Element as El exposing (Element)
import Element.Font as Font


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
        , label config.label
        , element config.element
        ]


title : Maybe String -> Element msg
title maybeTitle =
    case maybeTitle of
        Nothing ->
            El.none

        Just title_ ->
            El.el
                [ Font.color Color.darkslateblue
                , Font.bold
                ]
                (El.text title_)


label : String -> Element msg
label label_ =
    if label_ == "" then
        El.none

    else
        El.el
            [ El.alignTop
            , Font.color Color.darkslateblue
            , Font.bold
            ]
            (El.text label_)


element : Element msg -> Element msg
element value_ =
    El.el
        [ El.width El.fill ]
        value_
