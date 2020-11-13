module Template.InputField.PhonePortrait exposing (view)

import Element as El exposing (Element)
import Element.Border as Border
import Element.Input as Input


type alias Config msg c =
    { c
        | label : String
        , multiline : Bool
        , onChange : Maybe (String -> msg)
        , text : String
    }


view : Config msg c -> Element msg
view config =
    case config.onChange of
        Just onChange ->
            case config.multiline of
                True ->
                    Input.multiline
                        [ Border.rounded 5
                        , El.height <|
                            El.maximum 200 El.fill
                        , El.width El.fill
                        ]
                        { onChange = onChange
                        , text = config.text
                        , placeholder = Just (Input.placeholder [] (El.text config.label))
                        , label = Input.labelHidden config.label
                        , spellcheck = True
                        }

                False ->
                    Input.text
                        [ Border.rounded 5
                        , El.width El.fill
                        ]
                        { onChange = onChange
                        , text = config.text
                        , placeholder = Just (Input.placeholder [] (El.text config.label))
                        , label = Input.labelHidden config.label
                        }

        Nothing ->
            El.none
