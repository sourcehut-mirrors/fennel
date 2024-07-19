local view = require('fennel').view

local function warn(...)
    local cols = {...}
    for i, c in ipairs(cols) do cols[i] = tostring(c) end
    io.stderr:write(table.concat(cols, '\t') .. "\n")
end

local server_port = (os.getenv("IRC_HOST_PORT") or "irc.libera.chat 6667")
local channel = os.getenv("IRC_CHANNEL")
local url = os.getenv("JOB_URL") or "???"

local origin_job_prefix = 'https://builds.sr.ht/technomancy/job/'
local is_origin = url:sub(1, #origin_job_prefix) == origin_job_prefix

local branch = io.popen("git rev-parse --abbrev-ref HEAD"):read('*a')
                 :gsub('\n$', '')
local git_ref = os.getenv('GIT_REF')
local build_submitter = os.getenv('build_submitter')
local is_main = branch == 'main'

-- This may fail in future if libera chat once again blocks builds.sr.ht
-- from connecting; it currently works after we asked them to look into it
return function(failure_count)
    local will_send_irc = not not ((0 ~= tonumber(failure_count))
        and true and is_origin and channel)
    warn(((will_send_irc and "Sending" or "Not sending") .. " IRC report:\n%s"):format(view{
        failure_count = failure_count, branch = branch, is_origin = is_origin,
        IRC_CHANNEL = channel, JOB_URL = url, will_send_irc = will_send_irc, is_main,
        GIT_REF = git_ref, BUILD_SUBMITTER = build_submitter,
    }))
    if will_send_irc then
        print("Announcing failure on", server_port, channel)

        local git_log = io.popen("git log --oneline -n 1 HEAD")
        local log = git_log:read("*a"):gsub("\n", " "):gsub("\n", " ")

        local nc = io.popen(string.format("nc %s > /dev/null", server_port), "w")

        nc:write("NICK fennel-build\n")
        nc:write("USER fennel-build 8 x : fennel-build\n")
        nc:write("JOIN " .. channel .. "\n")
        nc:write(string.format("PRIVMSG %s :Build failure! %s / %s\n",
                               channel, log, url))
        nc:write("QUIT\n")
        nc:close()
    end
    if(failure_count ~= 0) then os.exit(1) end
end
