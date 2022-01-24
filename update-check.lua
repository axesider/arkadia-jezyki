Jezyki.updateCheck = Jezyki.updateCheck or {
    plugin_name = "arkadia-jezyki",
    repo = "axesider",
    storeKey = "Jezyki"
}

function Jezyki.updateCheck:getFile()
    return getMudletHomeDir() .. "/plugins/" .. self.plugin_name .. "/commits"
end

function Jezyki.updateCheck:getURL()
    return "https://api.github.com/repos/" .. self.repo .. "/" .. self.plugin_name .. "/commits"
end

function Jezyki.updateCheck:checkNewVersion()
    downloadFile(self.getFile(), self.getURL())
    registerAnonymousEventHandler("sysDownloadDone", function(_, file)
        self:handle(file)
    end, true)
    coroutine.yield(self.coroutine)
end

function Jezyki.updateCheck:handle(fileName)
    if fileName ~= self.file then
        return
    end

    local JezykiState = scripts.state_store:get(self.storeKey) or {}

    local file, s, contents = io.open(self.getFile())
    if file then
        contents = yajl.to_value(file:read("*a"))
        io.close(file)
        os.remove(self.getFile())
        local sha = contents[1].sha
        if JezykiState.sha ~= nil and sha ~= JezykiState.sha then
            echo("\n")
            cecho("<CadetBlue>(skrypty)<tomato>: Plugin "..self.plugin_name .." posiada nowa aktualizacje. Kliknij ")
            cechoLink("<green>tutaj", [[Jezyki.updateCheck:update()]], "Aktualizuj", true)
            cecho(" <tomato>aby pobrac")
            echo("\n")
        end
        JezykiState.sha = sha
        scripts.state_store:set(self.storeKey, JezykiState)
    end
end

function Jezyki.updateCheck:update()
    scripts.plugins_installer:install_from_url("https://codeload.github.com/" .. self.repo .. "/" .. self.plugin_name .. "/zip/master")
end

Jezyki.updateCheck.coroutine = coroutine.create(function()
    Jezyki.updateCheck:checkNewVersion()
end)
tempTimer(5, function() coroutine.resume(Jezyki.updateCheck.coroutine) end)

