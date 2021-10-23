module ToggleList exposing (ToggleList, insert, member, new, remove, toggle)

import Set


type ToggleList a
    = ToggleList (Set.Set a)


new : ToggleList a
new =
    ToggleList Set.empty


insert : ToggleList comparable -> comparable -> ToggleList comparable
insert (ToggleList set) element =
    ToggleList (Set.insert element set)


remove : ToggleList comparable -> comparable -> ToggleList comparable
remove (ToggleList set) element =
    ToggleList (Set.remove element set)


toggle : ToggleList comparable -> comparable -> ToggleList comparable
toggle (ToggleList set) element =
    if member (ToggleList set) element then
        remove (ToggleList set) element

    else
        insert (ToggleList set) element


member : ToggleList comparable -> comparable -> Bool
member (ToggleList set) element =
    Set.member element set
