module Types exposing
    ( Message
    , Room
    , User
    , decodeMessage
    , decodeRoom
    , decodeRooms
    , decodeUser
    , initRoom
    , initUser
    )

import Json.Decode as JD exposing (Value)
import Json.Decode.Extra exposing (andMap)


type alias Message =
    { id : String
    , text : String
    , owner : User
    }


type alias Room =
    { id : String
    , owner : User
    , members : List User
    , messages : List Message
    }


initRoom : Room
initRoom =
    { id = ""
    , owner = initUser
    , members = []
    , messages = []
    }


type alias User =
    { id : String
    , username : String
    }


initUser : User
initUser =
    { id = ""
    , username = ""
    }



{- Decoders -}


decodeMessage : Value -> Result JD.Error Message
decodeMessage payload =
    JD.decodeValue messageDecoder payload


messageDecoder : JD.Decoder Message
messageDecoder =
    JD.succeed
        Message
        |> andMap (JD.field "id" JD.string)
        |> andMap (JD.field "text" JD.string)
        |> andMap (JD.field "owner" userDecoder)


decodeRoom : Value -> Result JD.Error Room
decodeRoom payload =
    JD.decodeValue roomDecoder payload


roomDecoder : JD.Decoder Room
roomDecoder =
    JD.succeed
        Room
        |> andMap (JD.field "id" JD.string)
        |> andMap (JD.field "owner" userDecoder)
        |> andMap (JD.field "members" (JD.list userDecoder))
        |> andMap (JD.field "messages" (JD.list messageDecoder))


decodeRooms : Value -> Result JD.Error (List Room)
decodeRooms payload =
    JD.decodeValue roomsDecoder payload


roomsDecoder : JD.Decoder (List Room)
roomsDecoder =
    JD.succeed
        identity
        |> andMap (JD.field "rooms" (JD.list roomDecoder))


decodeUser : Value -> Result JD.Error User
decodeUser payload =
    JD.decodeValue userDecoder payload


userDecoder : JD.Decoder User
userDecoder =
    JD.succeed
        User
        |> andMap (JD.field "id" JD.string)
        |> andMap (JD.field "username" JD.string)
