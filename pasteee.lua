local Args = {...}

if not fs.exists("/paste.eeLibs/") then
    fs.makeDir("/paste.eeLibs/")
    local dJson = http.get("https://svn.apache.org/repos/infra/infrastructure/trunk/projects/gitwcsub/JSON.lua").readAll()
    local file = fs.open("/paste.eeLibs/JSON_DEC","w")
    file.write(dJson)
    file.close()
end

JSON = (loadfile "/paste.eeLibs/JSON_DEC")()

local key = "e1eabfbda65d508cd2133cd1c995aff9"

local showUsage = function()
    print("Correct Usage: ")
    print(shell.getRunningProgram().." put <filename> <desc>")
    print(shell.getRunningProgram().." get <paste id> <save file>")
end

if #Args <  2 then
    return showUsage()
elseif Args[1] == "put" or Args[1] == "get" then
    if #Args > 3 or #Args < 3 then
        return showUsage()
    end
elseif Args[1] ~= "put" or Args[1] ~= "get" then
    return showUsage()
end

local command = Args[1]

if command == "put" then
    local file = Args[2]
    local desc = Args[3]
    local path = shell.resolve(file)

    if not fs.exists(path) or fs.isDir(path) then
        print("No such file")
        return
    end

    local name = fs.getName(path)
    local file = fs.open(path, "r")
    local code = file.readAll()
    file.close()

    write("Connecting to paste.ee..... ")
    local response = http.post(
        "http://paste.ee/api",
        "key="..key.."&"..
        "description="..desc.."&"..
        "language=lua&"..
        "paste="..code
    )

    if response then
        print("Connected.")
        local TResponse = response.readAll()
        response.close()
        local DResponse = JSON:decode(TResponse)
        if DResponse["status"] == "success" then
            print("Uploaded as: "..DResponse["paste"].link)
            print("Run: '"..shell.getRunningProgram().." get "..DResponse["paste"].id.." <file name>' to download the file.")
        elseif DResponse["status"] == "error" then
            printError("Error: "..DResponse["error"])
        end
    else
        printError("Connection failed.")
    end
elseif command == "get" then
    local PasteID = Args[2]
    local File = Args[3]
    local Path = shell.resolve(File)
    if fs.exists(Path) then
        print("File already exists")
        return
    end

    write("Connecting to paste.ee..... ")
    local response = http.get("http://paste.ee/r/"..textutils.urlEncode(PasteID))
    if response then
        print("Connected.")

        local rResponse = response.readAll()
        response.close()
        local file = fs.open(Path, "w")
        file.write(rResponse)
        file.close()
        print("Downloaded as "..File)
    else
        printError("Connection failed.")
    end
end
