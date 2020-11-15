module View.LobbyForm exposing
    ( init
    , onChange
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
        , onSubmit : Maybe msg
        }


init : Config msg
init =
    Config
        { text = ""
        , onChange = Nothing
        , onSubmit = Nothing
        }


text : String -> Config msg -> Config msg
text text_ (Config config) =
    Config { config | text = text_ }


onChange : Maybe (String -> msg) -> Config msg -> Config msg
onChange maybeMsg (Config config) =
    Config { config | onChange = maybeMsg }


onSubmit : Maybe msg -> Config msg -> Config msg
onSubmit maybeMsg (Config config) =
    Config { config | onSubmit = maybeMsg }



{- View -}


view : Device -> Config msg -> Element msg
view device config =
    El.column
        [ El.width El.fill
        , El.spacing 20
        ]
        [ inputField device config
        , submitButton device config
        ]


inputField : Device -> Config msg -> Element msg
inputField device (Config config) =
    InputField.init
        |> InputField.label "Username"
        |> InputField.text config.text
        |> InputField.onChange config.onChange
        |> InputField.view device


submitButton : Device -> Config msg -> Element msg
submitButton device (Config config) =
    Button.init
        |> Button.label "Join Lobby"
        |> Button.onPress config.onSubmit
        |> Button.enabled (String.trim config.text /= "")
        |> Button.view device
