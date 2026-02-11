
(fn greet [] :HI)

(macro fmt-greeting [name] (.. "Hi, " name "!") )

(macros.export {:fmt-greeting fmt-greeting
                :child {:identity #$}})
{: greet}

