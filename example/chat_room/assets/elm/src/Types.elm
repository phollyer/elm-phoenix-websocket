module Types exposing
    ( Message
    , Room
    , User
    , decodeMessage
    , decodeRooms
    , decodeUser
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


type alias User =
    { id : String
    , username : String
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


decodeRooms : Value -> Result JD.Error (List Room)
decodeRooms payload =
    JD.decodeValue roomsDecoder payload


roomsDecoder : JD.Decoder (List Room)
roomsDecoder =
    JD.succeed
        identity
        |> andMap (JD.field "rooms" (JD.list roomDecoder))


roomDecoder : JD.Decoder Room
roomDecoder =
    JD.succeed
        Room
        |> andMap (JD.field "id" JD.string)
        |> andMap (JD.field "owner" userDecoder)
        |> andMap (JD.field "members" (JD.list userDecoder))
        |> andMap (JD.field "messages" (JD.list messageDecoder))


decodeUser : Value -> Result JD.Error User
decodeUser payload =
    JD.decodeValue userDecoder payload


userDecoder : JD.Decoder User
userDecoder =
    JD.succeed
        User
        |> andMap (JD.field "id" JD.string)
        |> andMap (JD.field "username" JD.string)
