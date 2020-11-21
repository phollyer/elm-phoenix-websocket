module View.InputField exposing
    ( init
    , label
    , multiline
    , onChange
    , onFocus
    , onLoseFocus
    , text
    , view
    )

import Device exposing (Device)
import Element as El exposing (Attribute, Element)
import Element.Border as Border
import Element.Events as Event
import Element.Input as Input
import View exposing (andMaybeEventWith)



{- Model -}


type Config msg
    = Config
        { label : String
        , text : String
        , multiline : Bool
        , onChange : Maybe (String -> msg)
        , onFocus : Maybe msg
        , onLoseFocus : Maybe msg
        }


init : Config msg
init =
    Config
        { label = ""
        , text = ""
        , multiline = False
        , onChange = Nothing
        , onFocus = Nothing
        , onLoseFocus = Nothing
        }


label : String -> Config msg -> Config msg
label label_ (Config config) =
    Config { config | label = label_ }


multiline : Bool -> Config msg -> Config msg
multiline bool (Config config) =
    Config { config | multiline = bool }


text : String -> Config msg -> Config msg
text name (Config config) =
    Config { config | text = name }


onChange : Maybe (String -> msg) -> Config msg -> Config msg
onChange maybeToMsg (Config config) =
    Config { config | onChange = maybeToMsg }


onFocus : Maybe msg -> Config msg -> Config msg
onFocus maybeMsg (Config config) =
    Config { config | onFocus = maybeMsg }


onLoseFocus : Maybe msg -> Config msg -> Config msg
onLoseFocus maybeMsg (Config config) =
    Config { config | onLoseFocus = maybeMsg }



{- View -}


view : Device -> Config msg -> Element msg
view _ (Config config) =
    case config.onChange of
        Nothing ->
            El.text config.text

        Just onChange_ ->
            if config.multiline then
                multi onChange_ (Config config)

            else
                single onChange_ (Config config)



{- Multiline -}


multi : (String -> msg) -> Config msg -> Element msg
multi onChange_ (Config config) =
    Input.multiline
        (multilineAttrs
            |> andMaybeEventWith config.onFocus Event.onFocus
            |> andMaybeEventWith config.onLoseFocus Event.onLoseFocus
        )
        { onChange = onChange_
        , text = config.text
        , placeholder = placeholder config.label
        , label = Input.labelHidden config.label
        , spellcheck = True
        }


multilineAttrs : List (Attribute msg)
multilineAttrs =
    [ Border.rounded 5
    , El.height <|
        El.maximum 150 El.fill
    , El.width El.fill
    ]



{- Single Line -}


single : (String -> msg) -> Config msg -> Element msg
single onChange_ (Config config) =
    Input.text
        (singleLineAttrs
            |> andMaybeEventWith config.onFocus Event.onFocus
            |> andMaybeEventWith config.onLoseFocus Event.onLoseFocus
        )
        { onChange = onChange_
        , text = config.text
        , placeholder = placeholder config.label
        , label = Input.labelHidden config.label
        }


singleLineAttrs : List (Attribute msg)
singleLineAttrs =
    [ Border.rounded 5
    , El.width El.fill
    ]



{- Common -}


placeholder : String -> Maybe (Input.Placeholder msg)
placeholder text_ =
    Just (Input.placeholder [] (El.text text_))
