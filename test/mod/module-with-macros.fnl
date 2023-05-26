(import-macros {: inc : inc!} :test.mod.macros)

(macro greet [name] `(.. "Hi, " (tostring ,name)))

{:greeting #(greet $)}
