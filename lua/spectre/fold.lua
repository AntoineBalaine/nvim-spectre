local M = {}
M._auto_folding_enabled = false
M._last_fold_line = -1
M._debounce_timer = nil

---@param user_config { auto_fold: boolean }
function M.setup(user_config)
    M._auto_folding_enabled = user_config.auto_fold
end

function M.getSpectreBufferId()
    -- Return the buffer ID stored in state
    return require('spectre.state').bufnr
end

function M.add_autocmds()
    -- Create the autocmd for cursor movement
    vim.api.nvim_create_autocmd('CursorMoved', {
        buffer = M.getSpectreBufferId(),
        -- pattern = 'spectre', -- Use pattern instead of buffer
        callback = function()
            -- Use debounce to prevent performance issues
            if M._debounce_timer then
                vim.fn.timer_stop(M._debounce_timer)
            end

            M._debounce_timer = vim.fn.timer_start(100, function()
                M.toggle_all_folds_except_current()
            end)
        end,
        group = vim.api.nvim_create_augroup('SpectreAutoFold', { clear = true }),
    })

    -- Show notification
    vim.notify('Spectre auto-folding enabled', vim.log.levels.INFO)

    -- Initial fold
    -- M.toggle_all_folds_except_current()
end

function M.clear_autocmds()
    vim.api.nvim_clear_autocmds({ group = 'SpectreAutoFold' })
end

function M.toggle_auto_folding()
    -- Toggle the state
    M._auto_folding_enabled = not M._auto_folding_enabled

    if M._auto_folding_enabled then
        -- Initialize state variables if needed
        M._last_fold_line = -1
        if M._debounce_timer then
            vim.fn.timer_stop(M._debounce_timer)
        end
        M._debounce_timer = nil
        M.add_autocmds()
    else
        -- Clear the autocmd group to disable auto-folding
        vim.api.nvim_clear_autocmds({ group = 'SpectreAutoFold' })

        -- Show notification
        vim.notify('Spectre auto-folding disabled', vim.log.levels.INFO)
    end
end

function M.toggle_all_folds_except_current()
    local current_line = vim.fn.line('.')
    if M._last_fold_line == current_line then
        return
    end
    M._last_fold_line = current_line

    -- Find the start of the current fold (file header)
    local fold_start = current_line
    while fold_start > 0 do
        local line = vim.fn.getline(fold_start)
        local is_header = not line:match('^│')

        if is_header then
            break
        end

        fold_start = fold_start - 1
    end

    -- Close all folds
    vim.cmd('normal! zM')

    -- If we found a valid fold start, open just that fold
    if fold_start > 0 then
        vim.fn.cursor(fold_start, 1)
        vim.cmd('normal! zo')
        -- Return to original position
        vim.fn.cursor(current_line, 1)
    end
end

return M
