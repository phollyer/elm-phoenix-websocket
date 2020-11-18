module Room exposing
    ( Room
    , decode
    , decodeRooms
    , init
    )

import Json.Decode as JD exposing (Value)
import Json.Decode.Extra exposing (andMap)
import Types exposing (Message, User, initUser, messageDecoder, userDecoder)


type alias Room =
    { id : String
    , owner : User
    , members : List User
    , messages : List Message
    }


init : Room
init =
    { id = ""
    , owner = initUser
    , members = []
    , messages = []
    }



{- Decoders -}


decodeRooms : Value -> Result JD.Error (List Room)
decodeRooms payload =
    JD.decodeValue (JD.field "rooms" (JD.list decoder)) payload


decode : Value -> Result JD.Error Room
decode payload =
    JD.decodeValue decoder payload


decoder : JD.Decoder Room
decoder =
    JD.succeed
        Room
        |> andMap (JD.field "id" JD.string)
        |> andMap (JD.field "owner" userDecoder)
        |> andMap (JD.field "members" (JD.list userDecoder))
        |> andMap (JD.field "messages" (JD.list messageDecoder))
