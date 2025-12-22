
(fn greet [] :HI)

(macro fmt-greeting [name] (.. "Hi, " name "!") )

(macros.expose {:fmt-greeting fmt-greeting
                :child {:identity #$}})
{: greet}

