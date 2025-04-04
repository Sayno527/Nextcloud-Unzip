-- Functions to get input files and find user
local files = get_input_files()
local username = users_find()
local is_dirpath = get_input("is_dirpath")

-- Supported extensions
local supportedExtensions = {".zip", ".7z", ".rar", ".tar", ".gz", ".bz2", ".xz"}

-- Function to get the directory path
local function getDirectoryPath(rootpath)    
    -- Execute the shell command to get the directory path
    local result = shell_command("dirname \"" .. rootpath .. "\"")
    -- Trim any trailing whitespace from the output
    local dirPath = result.output:gsub("%s+$", "")
    return dirPath
end

-- Function to remove supported extensions from file paths
local function removeSupportedExtensions(fpath)
    for _, ext in ipairs(supportedExtensions) do
        fpath = fpath:gsub(ext .. "$", "")
    end
    return fpath
end

-- Function to create a directory if it doesn't exist
local function createDirectory(dir)
    -- add_message("Creating directory: " .. dir)
    shell_command("mkdir -p \"" .. dir .. "\"")
end

-- Function to ensure 7z is installed
local function ensure7zInstalled()
    local result = shell_command("7z")
    if result.exit_code ~= 0 then
        add_message("7z not found, attempting to install p7zip")
        local installResult = shell_command("apk add --no-cache p7zip")
        if installResult.exit_code == 0 then
            add_message("Successfully installed p7zip")
        else
            add_message("Failed to install p7zip")
            return false
        end
    end
    return true
end

-- Function to extract files based on their extension
local function extractFile(fpath, noext, outputdir)
    if not ensure7zInstalled() then return end
    
    local command = ""
    if fpath:match("%.rar$") then
        if is_dirpath then
            createDirectory(noext)
            command = "7z e \"" .. fpath .. "\" \"" .. noext .. "\""
        else
            command = "7z e \"" .. fpath .. "\" \"" .. outputdir .. "\""
        end
    else
        if is_dirpath then
            createDirectory(noext)
            command = "7z x \"" .. fpath .. "\" -o\"" .. noext .. "\""
        else
            command = "7z x \"" .. fpath .. "\" -o\"" .. outputdir .. "\""
        end
    end
    return command
end

-- Main script logic
if (#files > 0) then
    for i, file in ipairs(files) do
        local fpath = meta_data(file).local_path
        local noext = removeSupportedExtensions(fpath)
        local outputdir = getDirectoryPath(fpath)
        local command = extractFile(fpath, noext, outputdir)
        -- add_message("Command to execute: " .. command)
        if command then
            shell_command(command)
            -- shell_command("chmod a+rx \"" .. noext .. "\"")
            shell_command("php /app/www/public/occ files:scan --all")
        end
    end
end