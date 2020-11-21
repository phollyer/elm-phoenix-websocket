module View.MultiRoomChat.Room.Form exposing
    ( id
    , init
    , onChange
    , onFocus
    , onLoseFocus
    , onSubmit
    , text
    , view
    )

import Device exposing (Device)
import Element as El exposing (DeviceClass(..), Element, Orientation(..))
import Html.Attributes as Attr
import View.Button as Button
import View.InputField as InputField



{- Model -}


type Config msg
    = Config
        { id : String
        , text : String
        , onChange : Maybe (String -> msg)
        , onFocus : Maybe msg
        , onLoseFocus : Maybe msg
        , onSubmit : Maybe msg
        }


init : Config msg
init =
    Config
        { id = ""
        , text = ""
        , onChange = Nothing
        , onFocus = Nothing
        , onLoseFocus = Nothing
        , onSubmit = Nothing
        }


id : String -> Config msg -> Config msg
id id_ (Config config) =
    Config { config | id = id_ }


text : String -> Config msg -> Config msg
text text_ (Config config) =
    Config { config | text = text_ }


onChange : Maybe (String -> msg) -> Config msg -> Config msg
onChange maybeToMsg (Config config) =
    Config { config | onChange = maybeToMsg }


onFocus : Maybe msg -> Config msg -> Config msg
onFocus maybeMsg (Config config) =
    Config { config | onFocus = maybeMsg }


onLoseFocus : Maybe msg -> Config msg -> Config msg
onLoseFocus maybeMsg (Config config) =
    Config { config | onLoseFocus = maybeMsg }


onSubmit : Maybe msg -> Config msg -> Config msg
onSubmit maybeMsg (Config config) =
    Config { config | onSubmit = maybeMsg }



{- View -}


view : Device -> Config msg -> Element msg
view device config =
    container device
        config
        [ inputField device config
        , submitButton device config
        ]


container : Device -> Config msg -> (List (Element msg) -> Element msg)
container { class, orientation } (Config config) =
    let
        container_ =
            case ( class, orientation ) of
                ( Phone, Portrait ) ->
                    El.column

                _ ->
                    El.row
    in
    container_
        [ El.htmlAttribute <|
            Attr.id config.id
        , El.spacing 10
        , El.paddingEach
            { left = 0
            , top = 10
            , right = 0
            , bottom = 0
            }
        , El.width El.fill
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
    El.el
        [ El.alignBottom
        , El.centerX
        ]
        (Button.init
            |> Button.label "Send Message"
            |> Button.onPress config.onSubmit
            |> Button.enabled (String.trim config.text /= "")
            |> Button.view device
        )
