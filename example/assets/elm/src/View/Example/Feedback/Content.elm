module View.Example.Feedback.Content exposing
    ( Config
    , element
    , init
    , label
    , title
    , view
    )

import Colors.Opaque as Color
import Element as El exposing (Device, Element)
import Element.Font as Font



{- Model -}


type Config msg
    = Config
        { title : Maybe String
        , label : String
        , element : Element msg
        }


init : Config msg
init =
    Config
        { title = Nothing
        , label = ""
        , element = El.none
        }


title : Maybe String -> Config msg -> Config msg
title title_ (Config config) =
    Config { config | title = title_ }


label : String -> Config msg -> Config msg
label label_ (Config config) =
    Config { config | label = label_ }


element : Element msg -> Config msg -> Config msg
element element_ (Config config) =
    Config { config | element = element_ }



{- View -}


view : Device -> Config msg -> Element msg
view _ (Config config) =
    El.column
        [ El.width El.fill
        , El.spacing 10
        , Font.family [ Font.typeface "Oswald" ]
        ]
        [ titleView config.title
        , labelView config.label
        , El.el
            [ El.width El.fill ]
            config.element
        ]


titleView : Maybe String -> Element msg
titleView maybeTitle =
    case maybeTitle of
        Nothing ->
            El.none

        Just title_ ->
            El.el
                [ Font.color Color.darkslateblue
                , Font.bold
                ]
                (El.text title_)


labelView : String -> Element msg
labelView label_ =
    if label_ == "" then
        El.none

    else
        El.el
            [ El.alignTop
            , Font.color Color.darkslateblue
            , Font.bold
            ]
            (El.text label_)
