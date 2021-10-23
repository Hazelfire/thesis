module HashSet exposing (HashSet, empty, fromList, insert, member, remove, toList, toggle)

import List
import Set


type HashSet a
    = HashSet
        { keys : Set.Set String
        , entries : List a
        , hash : a -> String
        }


fromList : List a -> (a -> String) -> HashSet a
fromList values hash =
    HashSet
        { keys = Set.fromList (List.map hash values)
        , entries = values
        , hash = hash
        }


empty : (a -> String) -> HashSet a
empty hash =
    HashSet
        { keys = Set.empty
        , entries = []
        , hash = hash
        }


member : a -> HashSet a -> Bool
member value (HashSet { keys, hash }) =
    Set.member (hash value) keys


insert : a -> HashSet a -> HashSet a
insert value ((HashSet { keys, hash, entries }) as set) =
    if not (member value set) then
        HashSet
            { keys = Set.insert (hash value) keys
            , entries = value :: entries
            , hash = hash
            }

    else
        set


remove : a -> HashSet a -> HashSet a
remove value ((HashSet { keys, hash, entries }) as set) =
    if member value set then
        HashSet
            { keys = Set.remove (hash value) keys
            , entries = List.filter (\item -> item /= value) entries
            , hash = hash
            }

    else
        set


toList : HashSet a -> List a
toList (HashSet a) =
    a.entries


toggle : a -> HashSet a -> HashSet a
toggle value set =
    if member value set then
        remove value set

    else
        insert value set
