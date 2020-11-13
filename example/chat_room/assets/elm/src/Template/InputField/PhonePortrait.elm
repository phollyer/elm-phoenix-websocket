module Template.InputField.PhonePortrait exposing (view)

import Element as El exposing (Element)
import Element.Border as Border
import Element.Input as Input


type alias Config msg c =
    { c
        | label : String
        , onChange : Maybe (String -> msg)
        , text : String
    }


view : Config msg c -> Element msg
view config =
    case config.onChange of
        Just onChange ->
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
