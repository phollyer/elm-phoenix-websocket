module Template.Layout.Tablet exposing (view)

import Element as El exposing (Element)
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
    El.row
        (Font.size 40
            :: Common.headerAttrs
        )
        [ El.el
            (El.paddingXY 0 10
                :: Common.titleAttrs
            )
            (El.text title)
        ]


homeButton : Maybe msg -> Element msg
homeButton maybeMsg =
    case maybeMsg of
        Nothing ->
            El.none

        Just msg ->
            El.el
                [ El.paddingXY 0 10 ]
            <|
                Input.button
                    (Font.size 40
                        :: Common.homeButtonAttrs
                    )
                    { label = El.text "<="
                    , onPress = Just msg
                    }
