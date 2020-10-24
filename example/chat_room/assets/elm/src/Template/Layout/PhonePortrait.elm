module Template.Layout.PhonePortrait exposing (view)

import Colors.Opaque as Color
import Element as El exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Template.Layout.Common as Common


view : Common.Config msg c -> Element msg
view { homeMsg, title, body } =
    El.column
        (El.inFront (homeButton homeMsg)
            :: Common.containerAttrs
        )
        [ header title
        , body
        ]


header : String -> Element msg
header title =
    El.paragraph
        (Font.size 20
            :: Common.headerAttrs
        )
        [ El.text title ]


homeButton : Maybe msg -> Element msg
homeButton maybeMsg =
    case maybeMsg of
        Nothing ->
            El.none

        Just msg ->
            El.el
                [ El.paddingXY 0 5 ]
            <|
                Input.button
                    (Font.size 20
                        :: Common.homeButtonAttrs
                    )
                    { label = El.text "<="
                    , onPress = Just msg
                    }
