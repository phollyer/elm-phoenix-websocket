module View.Example.Feedback.Info exposing
    ( Config
    , event
    , init
    , joinRef
    , payload
    , ref
    , topic
    , view
    )

import Colors.Opaque as Color
import Device exposing (Device)
import Element as El exposing (Attribute, DeviceClass(..), Element, Orientation(..))
import Element.Font as Font
import Json.Encode as JE exposing (Value)



{- Model -}


type Config msg
    = Config
        { topic : String
        , event : Maybe String
        , payload : Value
        , joinRef : Maybe String
        , ref : Maybe String
        }


init : Config msg
init =
    Config
        { topic = ""
        , event = Nothing
        , payload = JE.null
        , joinRef = Nothing
        , ref = Nothing
        }


topic : String -> Config msg -> Config msg
topic topic_ (Config config) =
    Config { config | topic = topic_ }


event : String -> Config msg -> Config msg
event event_ (Config config) =
    Config
        { config
            | event =
                if event_ == "" then
                    Nothing

                else
                    Just event_
        }


payload : Value -> Config msg -> Config msg
payload payload_ (Config config) =
    Config { config | payload = payload_ }


joinRef : Maybe String -> Config msg -> Config msg
joinRef joinRef_ (Config config) =
    Config { config | joinRef = joinRef_ }


ref : Maybe String -> Config msg -> Config msg
ref ref_ (Config config) =
    Config { config | ref = ref_ }



{- View -}


view : Device -> Config msg -> Element msg
view device (Config config) =
    El.column
        [ El.width El.fill
        , El.alignLeft
        , El.paddingEach
            { left = 0
            , top = 0
            , right = 0
            , bottom = 10
            }
        , El.spacing 10
        , Font.family [ Font.typeface "Roboto Mono" ]
        ]
        [ field device "Topic: " config.topic
        , maybe (field device) "Event: " config.event
        , field device "Payload: " (JE.encode 2 config.payload)
        , maybe (field device) "Join Ref: " config.joinRef
        , maybe (field device) "Ref: " config.ref
        ]


field : Device -> String -> String -> Element msg
field device label topic_ =
    El.wrappedRow
        [ fontSize device
        , spacing device
        , El.width El.fill
        ]
        [ El.el
            [ El.alignTop
            , Font.color Color.darkslateblue
            ]
            (El.text label)
        , El.el
            [ Font.color Color.black ]
            (El.text topic_)
        ]


maybe : (String -> String -> Element msg) -> String -> Maybe String -> Element msg
maybe toField label maybeValue =
    case maybeValue of
        Just value ->
            toField label value

        Nothing ->
            El.none



{- Attributes -}


fontSize : Device -> Attribute msg
fontSize { class } =
    case class of
        Phone ->
            Font.size 12

        _ ->
            Font.size 14


spacing : Device -> Attribute msg
spacing { class, orientation } =
    case ( class, orientation ) of
        ( Phone, Portrait ) ->
            El.spacing 5

        _ ->
            El.spacing 10
