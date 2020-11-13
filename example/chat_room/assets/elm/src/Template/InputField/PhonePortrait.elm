module Template.InputField.PhonePortrait exposing (view)

import Element as El exposing (Attribute, Element)
import Element.Border as Border
import Element.Events as Event
import Element.Input as Input


type alias Config msg c =
    { c
        | label : String
        , text : String
        , multiline : Bool
        , onChange : Maybe (String -> msg)
        , onFocus : Maybe msg
        , onLoseFocus : Maybe msg
    }


view : Config msg c -> Element msg
view config =
    case config.onChange of
        Just onChange ->
            case config.multiline of
                True ->
                    Input.multiline
                        (multilineAttrs
                            |> maybeEventWith config.onFocus Event.onFocus
                            |> maybeEventWith config.onLoseFocus Event.onLoseFocus
                        )
                        { onChange = onChange
                        , text = config.text
                        , placeholder = Just (Input.placeholder [] (El.text config.label))
                        , label = Input.labelHidden config.label
                        , spellcheck = True
                        }

                False ->
                    Input.text
                        (singleLineAttrs
                            |> maybeEventWith config.onFocus Event.onFocus
                            |> maybeEventWith config.onLoseFocus Event.onLoseFocus
                        )
                        { onChange = onChange
                        , text = config.text
                        , placeholder = Just (Input.placeholder [] (El.text config.label))
                        , label = Input.labelHidden config.label
                        }

        Nothing ->
            El.text config.text


multilineAttrs : List (Attribute msg)
multilineAttrs =
    [ Border.rounded 5
    , El.height <|
        El.maximum 200 El.fill
    , El.width El.fill
    ]


singleLineAttrs : List (Attribute msg)
singleLineAttrs =
    [ Border.rounded 5
    , El.width El.fill
    ]


maybeEventWith : Maybe msg -> (msg -> Attribute msg) -> List (Attribute msg) -> List (Attribute msg)
maybeEventWith maybeMsg toEvent attrs =
    case maybeMsg of
        Nothing ->
            attrs

        Just msg ->
            toEvent msg :: attrs
