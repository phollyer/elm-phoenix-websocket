module Types exposing
    ( Message
    , Meta
    , Presence
    , User
    , decodeMessage
    , decodeMessages
    , decodeMetas
    , decodeUser
    , initUser
    , messageDecoder
    , userDecoder
    )

import Json.Decode as JD exposing (Value)
import Json.Decode.Extra exposing (andMap)


type alias Message =
    { text : String
    , owner : User
    , createdAt : Int
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


type alias Presence =
    { id : String
    , metas : List Meta
    , user : User
    }


type alias Meta =
    { online_at : String
    , device : String
    }



{- Decoders -}


decodeMetas : List Value -> List Meta
decodeMetas metas =
    List.map
        (\meta ->
            JD.decodeValue metaDecoder meta
                |> Result.toMaybe
                |> Maybe.withDefault (Meta "" "")
        )
        metas


metaDecoder : JD.Decoder Meta
metaDecoder =
    JD.succeed
        Meta
        |> andMap (JD.field "online_at" JD.string)
        |> andMap (JD.field "device" JD.string)



{- Messages -}


decodeMessages : Value -> Result JD.Error (List Message)
decodeMessages payload =
    JD.decodeValue (JD.field "messages" (JD.list messageDecoder)) payload


decodeMessage : Value -> Result JD.Error Message
decodeMessage payload =
    JD.decodeValue messageDecoder payload


messageDecoder : JD.Decoder Message
messageDecoder =
    JD.succeed
        Message
        |> andMap (JD.field "text" JD.string)
        |> andMap (JD.field "owner" userDecoder)
        |> andMap (JD.field "created_at" JD.int)



{- User -}


decodeUser : Value -> Result JD.Error User
decodeUser payload =
    JD.decodeValue userDecoder payload


userDecoder : JD.Decoder User
userDecoder =
    JD.succeed
        User
        |> andMap (JD.field "id" JD.string)
        |> andMap (JD.field "username" JD.string)
