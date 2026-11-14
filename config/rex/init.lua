-- Keep the tmux keys so switching terminal backends doesn't change muscle memory.
-- shortcut: prefix-only history resets on reload; replace when Rex exposes last-session navigation.
local session_history = {}
local function terminal_binding(key, name, action, args)
    rex.action{
        name = name,
        title = name,
        run = function(ctx)
            local process = rex.block.call("com.superlogical.terminal", "process", {
                session_id = ctx.session_id, block_id = ctx.block_id,
            })
            -- On lookup failure, pass through rather than steal a terminal key.
            if not process or (process.foreground or {}).name == "tmux" then
                rex.client.queue("pane.send_key", { key = key })
            else
                if key == "ctrl+z" then
                    local history = session_history[ctx.client_id] or {}
                    if history.current ~= ctx.session_id then
                        history.previous, history.current = history.current, ctx.session_id
                    end
                    session_history[ctx.client_id] = history
                end
                rex.client.queue(action, args)
            end
        end,
    }
    rex.bind(key, name)
end

-- Decide before consuming the prefix so tmux receives Ctrl-Z immediately.
terminal_binding("ctrl+z", "terminal_prefix", "client.mode.enter", { name = "prefix", once = true })
rex.mode("prefix", { exclusive = true })
rex.bind("prefix/c", "client.tab.new")
rex.bind("prefix/p", "session.switch")
rex.bind("prefix/s", "pane.split", { direction = "down" })
rex.bind("prefix/v", "pane.split", { direction = "right" })
rex.bind("prefix/h", "pane.focus", { direction = "left" })
rex.bind("prefix/j", "pane.focus", { direction = "down" })
rex.bind("prefix/k", "pane.focus", { direction = "up" })
rex.bind("prefix/l", "pane.focus", { direction = "right" })
rex.action{
    name = "last_session",
    title = "Go to Last Used Session",
    run = function(ctx)
        local history = session_history[ctx.client_id]
        if history and history.previous then
            rex.client.queue("session.select", { session_id = history.previous })
        end
    end,
}
rex.bind("prefix/shift+l", "last_session")
rex.bind("prefix/r", "client.config.reload")
rex.action{
    name = "sessionizer",
    title = "Open Project Session",
    run = function(ctx)
        local result, err = rex.exec({
            "/bin/bash", os.getenv("HOME") .. "/.dotfiles/rex_sessionizer.bash",
            "--open-picker", ctx.session_id, ctx.client_id,
        })
        assert(result, err)
        assert(result.ok, result.stderr)
    end,
}
rex.bind("prefix/f", "sessionizer")
terminal_binding("ctrl+l", "terminal_next_tab", "client.tab.next")
terminal_binding("ctrl+h", "terminal_previous_tab", "client.tab.previous")
rex.bind("prefix/x", "client.close")
rex.bind("prefix/shift+w", "client.tab.rename")

-- Send the prefix to the terminal by pressing it twice.
rex.bind("prefix/ctrl+z", "pane.send_key", { key = "ctrl+z" })
