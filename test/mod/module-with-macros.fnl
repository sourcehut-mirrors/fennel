(import-macros {: inc : inc!} :test.macros)

(macro greet [name] `(.. "Hi, " (tostring ,name)))

{:greeting #(greet $)}
