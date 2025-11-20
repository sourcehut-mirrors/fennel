
(fn greet [] :HI)

(macro fmt-greeting [name] (.. "Hi, " name "!") )

(macros.extern {:fmt-greeting fmt-greeting})
{: greet}

