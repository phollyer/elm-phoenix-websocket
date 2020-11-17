module Device exposing
    ( Device
    , classify
    )

import Element exposing (DeviceClass, Orientation, classifyDevice)


type alias Device =
    { class : DeviceClass
    , orientation : Orientation
    , height : Int
    , width : Int
    }


classify : { height : Int, width : Int } -> Device
classify ({ height, width } as dimensions) =
    let
        { class, orientation } =
            classifyDevice dimensions
    in
    { class = class
    , orientation = orientation
    , height = height
    , width = width
    }
