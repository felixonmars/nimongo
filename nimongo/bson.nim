import oids
import sequtils
import tables
import streams
import strutils

# ------------- type: BsonKind -------------------#

type BsonKind* = enum
    BsonKindGeneric         = 0x00.char
    BsonKindDouble          = 0x01.char  ## 8-byte floating-point
    BsonKindStringUTF8      = 0x02.char  ## UTF-8 encoded C string
    BsonKindDocument        = 0x03.char
    BsonKindArray           = 0x04.char  ## Like document with numbers as keys
    BsonKindBinary          = 0x05.char
    BsonKindUndefined       = 0x06.char
    BsonKindOid             = 0x07.char  ## Mongo Object ID
    BsonKindBool            = 0x08.char
    BsonKindTimeUTC         = 0x09.char
    BsonKindNull            = 0x0A.char
    BsonKindRegexp          = 0x0B.char
    BsonKindDBPointer       = 0x0C.char
    BsonKindJSCode          = 0x0D.char
    BsonKindDeprecated      = 0x0E.char
    BsonKindJSCodeWithScope = 0x0F.char
    BsonKindInt32           = 0x10.char
    BsonKindTimestamp       = 0x11.char
    BsonKindInt64           = 0x12.char
    BsonKindMaximumKey      = 0x7F.char
    BsonKindMinimumKey      = 0xFF.char

converter toChar*(bk: BsonKind): char = bk.char  ## Convert BsonKind to char

# ------------- type: Bson -----------------------#

type Bson* = object of RootObj  ## Bson Node
    key: string
    case kind: BsonKind
    of BsonKindGeneric:    discard
    of BsonKindDouble:     valueFloat64:  float64
    of BsonKindStringUTF8: valueString:   string
    of BsonKindDocument:   valueDocument: seq[Bson]
    of BsonKindArray:      valueArray:    seq[Bson]
    of BsonKindBinary:     valueBinary:   cstring
    of BsonKindUndefined:  discard
    of BsonKindOid:        valueOid:      Oid
    of BsonKindBool:       valueBool:     bool
    of BsonKindNull:       discard
    of BsonKindInt64:      valueNull:     int64
    else: discard

converter toBson*(x: float64): Bson =
    ## Convert float64 to Bson object
    return Bson(key: "", kind: BsonKindDouble, valueFloat64: x)

proc bson*(bs: Bson): string =
    ## Serialize Bson object into byte-stream
    case bs.kind
    of BsonKindDouble:
        return bs.kind & bs.key & char(0) & $cast[cstring](bs.valueFloat64) & char(0)
    else:
        raise new(Exception)

proc `$`*(bs: Bson): string =
    ## Serialize Bson document into readable string
    case bs.kind
    of BsonKindDouble:
        return "\"$#\": $#" % [bs.key, $bs.valueFloat64]
    else:
        raise new(Exception)

# ------------- type: BsonDocument ---------------#

type BsonDocument* = object of RootObj  ## Bson top-level document
    size: int32
    data: Bson

proc newBsonDocument*(): BsonDocument =
    ## Create new top-level Bson document
    return BsonDocument(
        size: 5,
        data: Bson(
            key:  "",
            kind: BsonKindDocument,
            valueDocument: newSeq[Bson]()
        )
    )

proc `$`*(bs: BsonDocument): string =
    ## Serialize Bson document into readable string
    result = "{}"

proc bson*(bs: BsonDocument): string =
    ## Serialize Bson document into byte-stream suitable for
    ## sending over the wire to MongoDB server
    return ""

proc `()`*(bs: BsonDocument, key: string, val: Bson): BsonDocument =
    result = bs
    var
        value = val
    value.key = key
    result.data.valueDocument.add(value)

when isMainModule:
    echo "Testing nimongo/bson.nim module..."
    var bdoc: BsonDocument = newBsonDocument()("balance", 0.0)
    echo bdoc