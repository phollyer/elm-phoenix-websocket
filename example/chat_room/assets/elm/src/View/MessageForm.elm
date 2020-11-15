module View.MessageForm exposing
    ( init
    , onChange
    , onFocus
    , onLoseFocus
    , onSubmit
    , text
    , view
    )

import Device exposing (Device)
import Element as El exposing (Element)
import View.Button as Button
import View.InputField as InputField



{- Model -}


type Config msg
    = Config
        { text : String
        , onChange : Maybe (String -> msg)
        , onFocus : Maybe msg
        , onLoseFocus : Maybe msg
        , onSubmit : Maybe msg
        }


init : Config msg
init =
    Config
        { text = ""
        , onChange = Nothing
        , onFocus = Nothing
        , onLoseFocus = Nothing
        , onSubmit = Nothing
        }


text : String -> Config msg -> Config msg
text text_ (Config config) =
    Config { config | text = text_ }


onChange : (String -> msg) -> Config msg -> Config msg
onChange msg (Config config) =
    Config { config | onChange = Just msg }


onFocus : msg -> Config msg -> Config msg
onFocus msg (Config config) =
    Config { config | onFocus = Just msg }


onLoseFocus : msg -> Config msg -> Config msg
onLoseFocus msg (Config config) =
    Config { config | onLoseFocus = Just msg }


onSubmit : msg -> Config msg -> Config msg
onSubmit msg (Config config) =
    Config { config | onSubmit = Just msg }



{- View -}


view : Device -> Config msg -> Element msg
view device config =
    El.column
        [ El.spacing 10
        , El.width El.fill
        ]
        [ inputField device config
        , submitButton device config
        ]


inputField : Device -> Config msg -> Element msg
inputField device (Config config) =
    InputField.init
        |> InputField.label "New Message"
        |> InputField.text config.text
        |> InputField.multiline True
        |> InputField.onChange config.onChange
        |> InputField.onFocus config.onFocus
        |> InputField.onLoseFocus config.onLoseFocus
        |> InputField.view device


submitButton : Device -> Config msg -> Element msg
submitButton device (Config config) =
    Button.init
        |> Button.label "Send Message"
        |> Button.onPress config.onSubmit
        |> Button.enabled (String.trim config.text /= "")
        |> Button.view device
