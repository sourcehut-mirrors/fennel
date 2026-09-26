(local t (require :test.faith))

(macro v [form] (view form))

;; These are the slowest tests, so for now we just have a basic sanity check
;; to ensure that it compiles and can evaluate math.

(local test-all? (os.getenv :FNL_TESTALL)) ; set by `make testall`

(local dotless? (not (string.find (. arg -1) "5%.")))
(local lua-versions (if dotless?
                        [:lua51 :lua52 :lua53 :lua54]
                        [:lua5.1 :lua5.2 :lua5.3 :lua5.4]))

(local host-lua (let [long (case _VERSION
                             "Lua 5.1" (if _G.jit :luajit (. lua-versions 1))
                             _ (.. :lua (_VERSION:sub 5)))
                      p (io.popen (.. long " -v") :w)]
                  (if (p:close)
                      long
                      (or (os.getenv "LUA") "lua"))))

(fn file-exists? [filename]
  (let [f (io.open filename)]
    (when f (f:close) true)))

(λ sh/esc [str] (.. "'" (str:gsub "'" "'\\''") "'"))
(λ fennel-cli [...]
  (let [cmd [host-lua :fennel ...]
        proc (io.popen (table.concat cmd " "))
        output (: (proc:read :*a) :gsub "\n$" "")]
    (values (proc:close) output))) ; proc:close gives exit status on 5.2+

(λ peval [code ...] (fennel-cli :--eval (sh/esc code) ...))

(fn test-cli []
  ;; skip this if we haven't compiled the CLI or on Windows
  (when (and (file-exists? "fennel") (= "/" (package.config:sub 1 1)))
    (t.= [true "1\tnil\t2\tnil\tnil"]
         [(peval (v (values 1 nil 2 nil nil)))])))

(fn pick-lua [?i ?lua-v]
  (if (= (host-lua:match "(lua.*)") ?lua-v)
      ;; circular next
      (. lua-versions (+ 1 (math.fmod ?i (length lua-versions))))
      (pick-lua (next lua-versions ?i))))

(fn test-lua-flag []
  ;; skip this when cli is not compiled or not running tests with `make testall`
  ;; or when running luajit, because then you can't tell whether to be dotless
  (when (and test-all? (file-exists? "fennel") (not _G.jit))
    (let [;; running io.popen for all 20 combinations of lua versions is slow,
          ;; so we'll just pick the next one in the list after host-lua
          lua-exec (pick-lua)
          run #(pick-values 2 (peval $ (: "--lua %q" :format lua-exec)))]
      (t.= [true (if dotless?
                     (pick-values 1 (lua-exec:gsub "5" "5."))
                     lua-exec)]
           [(run (v (case (_VERSION:sub 5)
                      :5.1 (if _G.jit :luajit :lua5.1)
                      v-num (.. :lua v-num))))]
           (.. "should execute code in Lua runtime: " lua-exec))
      (let [(success? output) (run (v (do (print :test) (os.exit 1 true))))]
        (t.= "test" output)
        ;; pcall in Lua 5.1 doesn't give status with (proc:close)
        (t.= (if (= _VERSION "Lua 5.1") true nil)
             success?
             (.. "errors should cause failing exit status with --lua "
                 lua-exec))))))

(fn test-lua-plugin []
  (let [lua-plug :test/plugin/lua-plugin.lua]
    (t.= [true :s]
         [(fennel-cli :--plugin lua-plug
                      :-e (sh/esc (v (let [s 1] (is-in-scope s)))))]
         "lua plugins should be loaded with full compiler env")))

(fn test-args []
  (when (and test-all? (file-exists? "fennel"))
    (t.= [true "-l"] [(peval  "(. arg 3)" "-l")])))

{: test-cli
 : test-lua-flag
 : test-lua-plugin
 : test-args}
