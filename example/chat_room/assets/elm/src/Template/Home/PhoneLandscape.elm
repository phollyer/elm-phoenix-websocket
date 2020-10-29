module Template.Home.PhoneLandscape exposing (view)

import Element as El exposing (Element)
import Element.Font as Font
import Template.Home.Common as Common


view : Common.Config msg c -> Element msg
view { channels, presence, socket } =
    El.column
        (El.spacing 20
            :: Common.containerAttrs
        )
        [ socketExamples socket
        , channelExamples channels
        , presenceExamples presence
        ]


socketExamples : List (Element msg) -> Element msg
socketExamples examplePanels =
    El.column
        (El.spacing 10
            :: Common.examplesAttrs
        )
        [ El.el
            (Font.size 22
                :: Common.headingAttrs
            )
            (El.text "Socket Examples")
        , El.wrappedRow
            (El.spacing 10
                :: Common.examplesAttrs
            )
            examplePanels
        ]


channelExamples : List (Element msg) -> Element msg
channelExamples examplePanels =
    El.column
        (El.spacing 10
            :: Common.examplesAttrs
        )
        [ El.el
            (Font.size 22
                :: Common.headingAttrs
            )
            (El.text "Channel Examples")
        , El.column
            (El.spacing 10
                :: Common.examplesAttrs
            )
            examplePanels
        ]


presenceExamples : List (Element msg) -> Element msg
presenceExamples examplePanels =
    El.column
        (El.spacing 10
            :: Common.examplesAttrs
        )
        [ El.el
            (Font.size 22
                :: Common.headingAttrs
            )
            (El.text "Presence Examples")
        , El.column
            (El.spacing 10
                :: Common.examplesAttrs
            )
            examplePanels
        ]
