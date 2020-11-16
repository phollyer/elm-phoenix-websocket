module View.Home exposing
    ( Config
    , channels
    , init
    , presence
    , socket
    , view
    )

import Colors.Opaque as Color
import Device exposing (Device)
import Element as El exposing (Attribute, DeviceClass(..), Element, Orientation(..))
import Element.Font as Font



{- Model -}


type Config msg
    = Config
        { channels : List (Element msg)
        , presence : List (Element msg)
        , socket : List (Element msg)
        }


init : Config msg
init =
    Config
        { channels = []
        , presence = []
        , socket = []
        }


channels : List (Element msg) -> Config msg -> Config msg
channels channels_ (Config config) =
    Config { config | channels = channels_ }


presence : List (Element msg) -> Config msg -> Config msg
presence presence_ (Config config) =
    Config { config | presence = presence_ }


socket : List (Element msg) -> Config msg -> Config msg
socket socket_ (Config config) =
    Config { config | socket = socket_ }



{- View -}


view : Device -> Config msg -> Element msg
view device (Config config) =
    El.column
        [ El.spacing 20
        , El.width El.fill
        ]
        [ container device "Socket Examples" config.socket
        , container device "Channels Examples" config.channels
        , container device "Presence Examples" config.presence
        ]


container : Device -> String -> List (Element msg) -> Element msg
container device title panels =
    El.column
        [ El.spacing 10
        , El.width El.fill
        ]
        [ El.el
            [ fontSize device
            , Font.color Color.slateblue
            , El.centerX
            ]
            (El.text title)
        , panelsContainer device panels
        ]


panelsContainer : Device -> List (Element msg) -> Element msg
panelsContainer { class, orientation } =
    case ( class, orientation ) of
        ( Phone, Portrait ) ->
            El.column
                [ El.spacing 10
                , El.width El.fill
                ]

        _ ->
            El.wrappedRow
                [ El.spacing 10
                , El.width El.fill
                ]



{- Attributes -}


fontSize : Device -> Attribute msg
fontSize { class } =
    case class of
        Phone ->
            Font.size 18

        _ ->
            Font.size 30
