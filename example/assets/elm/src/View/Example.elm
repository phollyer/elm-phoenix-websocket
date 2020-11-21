module View.Example exposing
    ( Config
    , controls
    , description
    , feedback
    , id
    , init
    , view
    )

import Colors.Opaque as Color
import Element as El exposing (Attribute, Device, DeviceClass(..), Element, Orientation(..))
import Element.Font as Font



{- Model -}


type Config msg
    = Config
        { id : Maybe String
        , description : List (List (Element msg))
        , controls : Element msg
        , feedback : Element msg
        }


init : Config msg
init =
    Config
        { id = Nothing
        , description = []
        , controls = El.none
        , feedback = El.none
        }


controls : Element msg -> Config msg -> Config msg
controls cntrls (Config config) =
    Config { config | controls = cntrls }


description : List (List (Element msg)) -> Config msg -> Config msg
description desc (Config config) =
    Config { config | description = desc }


feedback : Element msg -> Config msg -> Config msg
feedback feedback_ (Config config) =
    Config { config | feedback = feedback_ }


id : Maybe String -> Config msg -> Config msg
id maybeId_ (Config config) =
    Config { config | id = maybeId_ }



{- View -}


view : Device -> Config msg -> Element msg
view device (Config config) =
    El.column
        [ fontSize device
        , El.height El.fill
        , El.width El.fill
        , El.spacing 10
        , El.paddingEach
            { left = 0
            , top = 0
            , right = 0
            , bottom = 10
            }
        ]
        [ descriptionView config.description
        , maybeId config.id
        , controlsView config.controls
        , config.feedback
        ]



{- Description -}


descriptionView : List (List (Element msg)) -> Element msg
descriptionView content =
    El.column
        [ El.spacing 12
        , Font.color Color.darkslateblue
        , Font.justify
        , Font.family
            [ Font.typeface "Varela Round" ]
        , El.width El.fill
        ]
    <|
        List.map
            (\paragraph ->
                El.paragraph
                    [ El.width El.fill ]
                    paragraph
            )
            content



{- Example ID -}


maybeId : Maybe String -> Element msg
maybeId maybeId_ =
    case maybeId_ of
        Nothing ->
            El.none

        Just id_ ->
            El.paragraph
                [ Font.center
                , Font.family
                    [ Font.typeface "Varela Round" ]
                ]
                [ El.el [ Font.color Color.lavender ] (El.text "Example ID: ")
                , El.el [ Font.color Color.powderblue ] (El.text id_)
                ]



{- Controls -}


controlsView : Element msg -> Element msg
controlsView controls_ =
    El.el
        [ El.width El.fill ]
        controls_



{- Attributes -}


fontSize : Device -> Attribute msg
fontSize { class } =
    case class of
        Phone ->
            Font.size 14

        _ ->
            Font.size 18
