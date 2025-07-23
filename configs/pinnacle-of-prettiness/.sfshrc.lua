local ANSI_RESET = "\x1b[0m"
local ANSI_BOLD = "\x1b[1m"
local ANSI_DIM = "\x1b[2m"
local ANSI_ITALIC = "\x1b[3m"
local ANSI_UNDERLINE = "\x1b[4m"
local ANSI_BLINK = "\x1b[5m"
local ANSI_INVERT = "\x1b[7m"

local ANSI_BLACK = "\x1b[30m"
local ANSI_RED = "\x1b[31m"
local ANSI_GREEN = "\x1b[32m"
local ANSI_YELLOW = "\x1b[33m"
local ANSI_BLUE = "\x1b[34m"
local ANSI_MAGENTA = "\x1b[35m"
local ANSI_CYAN = "\x1b[36m"
local ANSI_WHITE = "\x1b[37m"

local ANSI_BRIGHT_BLACK = "\x1b[90m"
local ANSI_BRIGHT_RED = "\x1b[91m"
local ANSI_BRIGHT_GREEN = "\x1b[92m"
local ANSI_BRIGHT_YELLOW = "\x1b[93m"
local ANSI_BRIGHT_BLUE = "\x1b[94m"
local ANSI_BRIGHT_MAGENTA = "\x1b[95m"
local ANSI_BRIGHT_CYAN = "\x1b[96m"
local ANSI_BRIGHT_WHITE = "\x1b[97m"

local GLYPH_PROMPT_ARROW = "❯"
local GLYPH_TIME = "󰥔"
local GLYPH_USER = "󰍹"
local GLYPH_HOST = "󰐕"
local GLYPH_GIT_BRANCH = "󰑠"
local GLYPH_GIT_DIRTY = "󰅖"
local GLYPH_GIT_CLEAN = "󰄬"
local GLYPH_HOME_DIR = "󰋩"
local GLYPH_FOLDER = "󰉋"
local GLYPH_SUCCESS = "󰄬"
local GLYPH_FAILURE = "󰅖"

local BOX_TOP_LEFT = "╭"
local BOX_TOP_RIGHT = "╮"
local BOX_BOTTOM_LEFT = "╰"
local BOX_BOTTOM_RIGHT = "╯"
local BOX_HORIZONTAL = "─"
local BOX_VERTICAL = "│"
local BOX_TEE_RIGHT = "├"

modules_path = "./modules"
history_file = "~/.sfsh_history"

local Softhostname = require("softhostname")

local function get_short_cwd()
    local cwd_full = io.popen("pwd"):read("*l") or ""
    cwd_full = cwd_full:gsub("\n", "")

    local home_dir = os.getenv("HOME")
    if home_dir and cwd_full:find(home_dir, 1, true) == 1 then
        local relative_path = cwd_full:sub(#home_dir + 1)
        if relative_path == "" or relative_path == "/" then
            return GLYPH_HOME_DIR
        else
            return GLYPH_HOME_DIR .. relative_path
        end
    end

    local parts = {}
    for part in cwd_full:gmatch("[^/\\]+") do
        table.insert(parts, part)
    end

    if #parts > 0 then
        return parts[#parts]
    elseif cwd_full == "/" or cwd_full == "\\" then
        return "/"
    end
    return "[error_cwd]"
end

local function get_git_info()
    local branch = ""
    local status_glyph = ""

    local branch_output = io.popen("git rev-parse --abbrev-ref HEAD 2>/dev/null"):read("*l")
    if branch_output then
        branch = branch_output:gsub("\n", "")
    end

    if branch ~= "" and branch ~= "HEAD" then
        local dirty_output = io.popen("git status --porcelain 2>/dev/null"):read("*a")
        if dirty_output and dirty_output:find(".") then
            status_glyph = string.format("%s%s", ANSI_YELLOW, GLYPH_GIT_DIRTY)
        else
            status_glyph = string.format("%s%s", ANSI_GREEN, GLYPH_GIT_CLEAN)
        end
        return string.format("%s%s %s%s%s", ANSI_MAGENTA, GLYPH_GIT_BRANCH, branch, status_glyph, ANSI_RESET)
    end
    return ""
end

function get_prompt()
    local user = os.getenv("USER") or "user"
    local host = Softhostname.get_hostname()
    local cwd_short = get_short_cwd()
    local git_info = get_git_info()
    local current_time = os.date("%H:%M")

    local exit_status = string.format("%s%s%s", ANSI_GREEN, GLYPH_SUCCESS, ANSI_RESET)

    local line1_segments = {}
    table.insert(line1_segments, ANSI_BRIGHT_BLACK .. BOX_TOP_LEFT)
    table.insert(line1_segments, BOX_HORIZONTAL)

    table.insert(line1_segments, string.format("[%s%s %s%s%s]%s", ANSI_DIM, GLYPH_TIME, current_time, ANSI_RESET, ANSI_BRIGHT_BLACK, BOX_HORIZONTAL))
    table.insert(line1_segments, string.format("[%s%s %s%s@%s %s%s%s]%s", ANSI_CYAN, GLYPH_USER, ANSI_GREEN, user, ANSI_BRIGHT_GREEN, GLYPH_HOST, host, ANSI_RESET, ANSI_BRIGHT_BLACK, BOX_HORIZONTAL))

    if git_info ~= "" then
        table.insert(line1_segments, string.format("[%s%s]%s", git_info, ANSI_BRIGHT_BLACK, BOX_HORIZONTAL))
    end

    table.insert(line1_segments, BOX_TOP_RIGHT)

    local line1 = table.concat(line1_segments) .. ANSI_RESET

    local line2_segments = {}
    table.insert(line2_segments, ANSI_BRIGHT_BLACK .. BOX_BOTTOM_LEFT)
    table.insert(line2_segments, BOX_HORIZONTAL)

    table.insert(line2_segments, string.format("[%s%s %s%s%s]%s", ANSI_BRIGHT_BLUE, GLYPH_FOLDER, cwd_short, ANSI_RESET, ANSI_BRIGHT_BLACK, BOX_HORIZONTAL))
    table.insert(line2_segments, string.format("%s%s%s", BOX_HORIZONTAL, exit_status, ANSI_BRIGHT_BLACK))

    table.insert(line2_segments, BOX_HORIZONTAL .. GLYPH_PROMPT_ARROW .. " ")

    local line2 = table.concat(line2_segments) .. ANSI_RESET

    return line1 .. "\n" .. line2
end

mycommands = {}

function mycommands.greet(name)
    name = name or "Traveler"
    print(string.format("%sHello, %s%s%s from sfrice!%s", ANSI_CYAN, ANSI_BOLD, name, ANSI_RESET, ANSI_RESET))
end

function mycommands.theme_info()
    print("\n" .. ANSI_BOLD .. "--- sfrice Theme Info ---" .. ANSI_RESET)
    print("This prompt is designed for a Nerd Font enabled terminal.")
    print("It aims for a clean, multi-line display with contextual information.")
    print("Icons include: " .. GLYPH_TIME .. " (Time), " .. GLYPH_USER .. " (User), " .. GLYPH_HOST .. " (Host),")
    print("               " .. GLYPH_GIT_BRANCH .. " (Git Branch), " .. GLYPH_GIT_CLEAN .. " (Clean), " .. GLYPH_GIT_DIRTY .. " (Dirty),")
    print("               " .. GLYPH_HOME_DIR .. " (Home), " .. GLYPH_FOLDER .. " (Folder), " .. GLYPH_SUCCESS .. " (Success), " .. GLYPH_FAILURE .. " (Failure).")
    print(ANSI_BOLD .. "-------------------------" .. ANSI_RESET .. "\n")
end

print(string.format("%s==========================================%s", ANSI_BOLD, ANSI_RESET))
print(string.format("%s sfsh: %s's Pinnacle of Prettiness Loaded! %s", ANSI_CYAN, ANSI_BOLD, ANSI_RESET))
print(string.format("%s==========================================%s", ANSI_BOLD, ANSI_RESET))
print("Type 'mycommands.theme_info()' for prompt details.")
