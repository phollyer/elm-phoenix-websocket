module View.ChannelMessage exposing
    ( Config
    , event
    , init
    , joinRef
    , payload
    , ref
    , topic
    , view
    )

import Element exposing (Device, DeviceClass(..), Element, Orientation(..))
import Json.Encode as JE exposing (Value)
import Template.ChannelMessage.PhoneLandscape as PhoneLandscape
import Template.ChannelMessage.PhonePortrait as PhonePortrait


type Config msg
    = Config
        { topic : String
        , event : String
        , payload : Value
        , joinRef : Maybe String
        , ref : Maybe String
        }


init : Config msg
init =
    Config
        { topic = ""
        , event = ""
        , payload = JE.null
        , joinRef = Nothing
        , ref = Nothing
        }


view : Device -> Config msg -> Element msg
view { class, orientation } (Config config) =
    case ( class, orientation ) of
        ( Phone, Portrait ) ->
            PhonePortrait.view config

        _ ->
            PhoneLandscape.view config


topic : String -> Config msg -> Config msg
topic topic_ (Config config) =
    Config { config | topic = topic_ }


event : String -> Config msg -> Config msg
event event_ (Config config) =
    Config { config | event = event_ }


payload : Value -> Config msg -> Config msg
payload payload_ (Config config) =
    Config { config | payload = payload_ }


joinRef : Maybe String -> Config msg -> Config msg
joinRef joinRef_ (Config config) =
    Config { config | joinRef = joinRef_ }


ref : Maybe String -> Config msg -> Config msg
ref ref_ (Config config) =
    Config { config | ref = ref_ }
