module View.UsefulFunctions exposing
    ( functions
    , init
    , view
    )

import Colors.Opaque as Color
import Device exposing (Device)
import Element as El exposing (Attribute, DeviceClass(..), Element, Orientation(..))
import Element.Font as Font
import Template.UsefulFunctions.Tablet as Tablet
import UI



{- Model -}


type Config
    = Config (List ( String, String ))


init : Config
init =
    Config []


functions : List ( String, String ) -> Config -> Config
functions functions_ (Config _) =
    Config functions_



{- View -}


view : Device -> Config -> Element msg
view device (Config functions_) =
    El.column
        [ El.width El.fill
        , spacing device
        ]
    <|
        El.wrappedRow
            [ El.width El.fill
            , Font.bold
            , Font.color Color.darkslateblue
            ]
            [ El.el
                []
                (El.text "Function")
            , El.el
                [ El.alignRight ]
                (El.text "Current Value")
            ]
            :: toRows device functions_


toRows : Device -> List ( String, String ) -> List (Element msg)
toRows ({ class } as device) rows =
    case class of
        Phone ->
            List.map (toRow device) rows

        _ ->
            [ El.column
                [ El.spacing 16
                , El.width El.fill
                ]
                (List.map (toRow device) rows)
            ]


toRow : Device -> ( String, String ) -> Element msg
toRow device ( function, currentValue ) =
    El.wrappedRow
        [ El.width El.fill
        , El.clipX
        , El.scrollbarX
        , spacing device
        ]
        [ El.el [ El.alignTop ] (UI.functionLink function)
        , El.el [ El.alignRight ] (El.text currentValue)
        ]



{- Attributes -}


spacing : Device -> Attribute msg
spacing { class } =
    case class of
        Phone ->
            El.spacing 5

        _ ->
            El.spacing 10
