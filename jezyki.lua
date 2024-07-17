Jezyki = Jezyki or {
    tryb = 0
}

local Jezyk2nazwa = {
    ["bretonsku"] = "bretonski",
    ["Drukh-Eltharin"] = "drukh-eltharin",
    ["estalijsku"] = "estalijski",
    ["Fan-Eltharin"] = "fan-eltharin",
    ["Ghassally"] = "ghassally",
    ["gnomiemu"] = "gnomi",
    ["Grumbarth"] = "grumbarth",
    ["halflinsku"] = "halflinski",
    ["Khazalidzie"] = "khazalid",
    ["kislevicku"] = "kislevicki",
    ["Krasnoludow Mahakamskich"] = "krasnoludzki",
    ["nilfgaardzku"] = "nilfgaardzki",
    ["norskim"] = "norski",
    ["Reikspielu"] = "reikspiel",
    ["skelligansku"] = "skelliganski",
    ["tileansku"] = "tileanski",
    ["Starszej Mowie"] = "starsza mowa",
    ["Tar-Eltharin"] = "tar-eltharin",
    ["zerrikansku"] = "zerrikanski"
}

local JezykPostepy = {
    ["minimalne"] = "1",
    ["nieznaczne"] = "2",
    ["bardzo male"] = "3",
    ["male"] = "4",
    ["nieduze"] = "5",
    ["zadowalajace"] = "6",
    ["spore"] = "7",
    ["dosc duze"] = "8",
    ["znaczne"] = "9",
    ["duze"] = "A",
    ["bardzo duze"] = "B",
    ["ogromne"] = "C",
    ["imponujace"] = "D",
    ["wspaniale"] = "E",
    ["gigantyczne"] = "F",
    ["niebotyczne"] = "G"
}

misc["lang_desc"] = {
    ["znikoma"] = 1,
    ["niewielka"] = 2,
    ["czesciowa"] = 3,
    ["niezla"] = 4,
    ["dosc dobra"] = 5,
    ["dobra"] = 6,
    ["bardzo dobra"] = 7,
    ["doskonala"] = 8,
    ["prawie pelna"] = 9,
    ["pelna"] = 10
}

Jezyki.db = db:create("nauka", {
    nauka = {
        jezyk = "",
        character = "",
        nauczyciel = "",
        postepy = "",
        datetime = "",
        changed = db:Timestamp("CURRENT_TIMESTAMP"),
        _index = {"jezyk"}
    },
    jezyki = {
        nazwa = "",
        poziom = "",
        character = "",
        datetime = "",
        changed = db:Timestamp("CURRENT_TIMESTAMP")
    },
    jezyki_max = {
        nazwa = "",
        poziom = "",
        is_max = 0,
        character = "",
        _index = {"nazwa"},
        _unique = {"nazwa"},
        _violations = "REPLACE"
    }
})

-- overload arkadia\skrypty\misc.lua
function alias_func_skrypty_misc_jezyki()
    Jezyki.tryb = 1
    Jezyki:enableTrigger()
    tempTimer(0.1, function()
        send("jezyki", false)
    end)
    tempTimer(1, function()
        Jezyki:disableTrigger()
    end)
end
-- overload end

function alias_func_skrypty_misc_jezyki_maksymalne()
    Jezyki.tryb = 2
    Jezyki:enableTrigger()
    tempTimer(0.1, function()
        send("jezyki maksymalne", false)
    end)
    tempTimer(1, function()
        Jezyki:disableTrigger()
    end)
end

function alias_func_jezyk_command()
    Jezyki:command(matches[2])
end

function Jezyki:enableTrigger()
    local regexp = "^([a-z]\\w+(?>[ -]\\w+)?):\\s+(.+)$"
    if self.jezyki_trigger then
        killTrigger(self.jezyki_trigger)
        self.jezyki_trigger = nil
    end
    self.jezyki_trigger = tempRegexTrigger(regexp, function()
        self:parse()
    end)
end

function Jezyki:disableTrigger()
    if self.jezyki_trigger then
        killTrigger(self.jezyki_trigger)
        self.jezyki_trigger = nil
    end
    self.tryb = 0
end

function Jezyki:parse()
    local nazwa = matches[2]
    local poziom = matches[3]
    if self.tryb == 1 then

        local h = {}
        for key, val in pairs(misc["lang_desc"]) do
            local q = "select f.nauczyciel, f.jezyk, f.postepy, strftime('%Y-%m-%d %H:%M',f.changed, 'localtime') as datetime from nauka as f where " ..
                          "f.changed between (select ifnull(max(changed),0) from jezyki where nazwa=f.jezyk and changed<(select changed from jezyki where nazwa=f.jezyk and poziom = '" .. key .. "')) " ..
                          " and (select changed from jezyki where nazwa=f.jezyk and poziom = '" .. key .. "')" .. "and f.jezyk = '" .. nazwa .. "'"
            h[key] = {}
            local r = db:fetch_sql(self.db.nauka, q)
            for k, v in pairs(r) do
                local p = v['postepy']
                h[key][p] = h[key][p] and h[key][p] + 1 or 1
            end
        end
        local lv = misc.lang_desc[poziom]
        local lv_max = self:get_jezyk_max(nazwa)
        if lv_max == -1 then
            lv_max = 10
        end

        selectString(nazwa, 1)
        setLink(function()
            send("justaw " .. nazwa)
        end, "zmien jezyk na " .. nazwa)
        cecho(string.rep(" ", 13 - string.len(poziom)) .. " [")
        local is_max = self:is_jezyk_max(nazwa)
        local color = is_max and "<green_yellow>" or "<green>"
        for i = 1, 10 do
            for k, v in pairs(misc["lang_desc"]) do
                if v == i then
                    local msg = "<reset> "
                    if i <= lv then
                        msg = color .. "="
                    elseif i <= lv_max then
                        msg = "<red>-"
                    end
                    if h[k] and h[k] ~= {} then
                        local hint = k .. " "
                        for n, m in pairs(h[k]) do
                            hint = hint .. n .. ":" .. m .. " "
                        end
                        cechoLink(msg, function()
                        end, hint, true)
                    else
                        cecho(msg)
                    end
                    break
                end
            end
        end
        cecho("<reset>]")
        -- "<green>" ..string.rep("=",lv).."<red>" .. string.rep("-",lv_max-lv) .."<reset>".. string.rep(" ",10-lv_max) .. "]"
        -- local add_text = string.rep(" ", 13 - string.len(poziom)) .. "<DarkSlateBlue>" ..string.rep("#",lv).."<light_pink>" .. string.rep("-",lv_max-lv) .."<reset>"
        -- cecho(add_text)
        if not is_max then
            local r = db:fetch_sql(self.db.nauka,
                "select f.nauczyciel, f.jezyk, f.postepy, strftime('%Y-%m-%d %H:%M',f.changed, 'localtime') as datetime from nauka as f where f.changed > (select MAX(changed) as max_date FROM jezyki where nazwa = f.jezyk ) and f.jezyk = '" ..
                    nazwa .. "' and f.character = '" .. scripts.character_name .. "'")
            for key, val in pairs(r) do
                local postepy = JezykPostepy[val["postepy"]] or val["postepy"]
                cechoLink(postepy, function()
                end, val["nauczyciel"], true)
            end
        end

        self:insert_jezyk(nazwa, poziom)
    elseif self.tryb == 2 then
        self:insert_jezyk_max(nazwa, poziom)
    end
end

function Jezyki:get_jezyk_max(nazwa)
    local q = "select poziom from jezyki_max where nazwa='" .. nazwa .. "' and character = '" .. scripts.character_name .. "'"
    local r = db:fetch_sql(self.db.jezyki_max, q)
    return table.size(r) > 0 and misc["lang_desc"][r[1]['poziom']] or -1
end

function Jezyki:is_jezyk_max(nazwa)
    local q = "select is_max from jezyki_max where nazwa='" .. nazwa .. "' and character = '" .. scripts.character_name .. "'"
    local r = db:fetch_sql(self.db.jezyki_max, q)
    return table.size(r) > 0 and r[1]['is_max'] == 1 or false
end

function Jezyki:insert_jezyk_max(nazwa, poziom)
    local q = "select * from jezyki_max where nazwa='" .. nazwa .. "' and character = '" .. scripts.character_name .. "'"
    local r = db:fetch_sql(self.db.jezyki_max, q)
    if table.size(r) > 0 and r[1]['poziom'] == poziom then
        return
    end
    db:add(self.db.jezyki_max, {
        nazwa = nazwa,
        poziom = poziom,
        character = scripts.character_name,
        is_max = false
    })
end

-- db:add(Jezyki.db.nauka, { jezyk = "krasnoludzki", nauczyciel = "Vorid", postepy= "minimalne", changed=db:Timestamp(os.time({year=2021, month=11, day=25, hour=16, minute=50}))})
function Jezyki:insert_jezyk(nazwa, poziom)
    local q = "select * from jezyki where nazwa='" .. nazwa .. "' and poziom='" .. poziom .. "' and character = '" .. scripts.character_name .. "'"
    local r = db:fetch_sql(self.db.jezyki, q)
    if r == nil or table.size(r) == 0 then
        db:add(self.db.jezyki, {
            nazwa = nazwa,
            poziom = poziom,
            character = scripts.character_name
        })
    end
end

function Jezyki:Flush()
    db:add(self.db.nauka, {
        jezyk = self.temp_jezyk,
        nauczyciel = self.temp_nauczyciel,
        postepy = self.temp_postepy,
        character = scripts.character_name
    })
    self.temp_jezyk = nil
    self.temp_nauczyciel = nil
end

function Jezyki:chcecieuczyc()
    if not Jezyk2nazwa[matches['jezyk']] then
        self.temp_jezyk = matches['jezyk']
        scripts:print_log("Nierozpoznany jezyk: '" .. self.temp_jezyk .. "'")
        -- Jezyki:wybierz()
    else
        self.temp_jezyk = Jezyk2nazwa[matches['jezyk']]
    end
    local lowered_name = string.lower(matches['kto'])
    for k, v in pairs(gmcp.objects.nums) do
        if ateam.objs[v]["desc"] and string.lower(ateam.objs[v]["desc"]) == lowered_name and not ateam.objs[v].enemy then
            local command = "jucz sie jezyka od ob_" .. v
            if scripts.utils.functional_key ~= command then
                raiseEvent("playBeep")
                scripts.utils.bind_functional(command, false)
            end
            break
        end
    end
end

function Jezyki:wybierz()
    echo("\nPodaj jaki to jezyk:")
    for k, _ in pairs(misc.lang.languages) do
        local znany = false
        for _, v in pairs(Jezyk2nazwa) do
            if v == k then
                znany = true
                break
            end
        end
        if znany == false then
            echo(" ")
            cechoLink("<light_slate_blue>" .. k .. "<reset>", function()
                Jezyki.temp_jezyk = k
            end, "ustaw " .. k, true)
        end
    end
    echo("\n")
end

function Jezyki:uczyciemowic()
    self.temp_nauczyciel = matches['kto']

    if Jezyk2nazwa[matches['jezyk']] then
        self.temp_jezyk = Jezyk2nazwa[matches[3]]
    else
        scripts:print_log("Nierozpoznany jezyk: '" .. self.temp_jezyk .. "'")
    end
end

function Jezyki:postepywnauce()
    self.temp_postepy = matches[2]
    if self:get_jezyk_max(self.temp_jezyk) == -1 then
        scripts.utils.bind_functional("jezyki maksymalne", false, false)
    else
        scripts.utils.bind_functional("jezyki", false, false)
    end
    self:Flush()
end

function Jezyki:maxnauki()
    if self.temp_jezyk then
        local nazwa = self.temp_jezyk
        if self:is_jezyk_max(nazwa) == false then
            cechoLink("<green> [ustaw " .. nazwa .. " jako nauczony]", function()
                local bob = db:fetch(Jezyki.db.jezyki_max, db:AND(db:eq(Jezyki.db.jezyki_max.nazwa, nazwa), db:eq(Jezyki.db.jezyki_max.character, scripts.character_name)))[1]
                bob.is_max = 1
                db:update(Jezyki.db.jezyki_max, bob)
            end, "zaznacza jezyk jako wyuczony", true)
        end
        self.temp_jezyk = nil
    end
end

function Jezyki:print2()
    local q = "select nazwa, poziom, strftime('%Y-%m-%d %H:%M',changed, 'localtime') as datetime from jezyki order by nazwa,datetime"
    local r = db:fetch_sql(Jezyki.db.jezyki, q)
    for key, val in pairs(r) do
        cecho(val["datetime"] .. " <green>" .. val["nazwa"] .. "<reset> " .. val["poziom"] .. "\n")
    end
end

function Jezyki:print()
    local q = "select f.nauczyciel, f.jezyk, f.postepy, strftime('%Y-%m-%d %H:%M',f.changed, 'localtime') as datetime from nauka as f order by datetime"
    local r = db:fetch_sql(Jezyki.db.nauka, q)
    for key, val in pairs(r) do
        cecho(val["datetime"] .. " " .. val["nauczyciel"] .. string.rep(" ", 12 - string.len(val["nauczyciel"])) .. "<green>" .. val["jezyk"] .. "<reset>" .. string.rep(" ", 15 - string.len(val["jezyk"])) ..
                  val["postepy"] .. "\n")
    end
end

function Jezyki:Init()
    local regexp = "^\\[?(?'kto'.+?)\\]? chce cie uczyc mowic (?>w(?> jezyku)?|po) (?'jezyk'.+)\\.$"
    if self.chcecieuczyc_trigger then
        killTrigger(self.chcecieuczyc_trigger)
    end
    self.chcecieuczyc_trigger = tempRegexTrigger(regexp, function()
        self:chcecieuczyc()
    end)

    local regexp2 = "^\\[?(?'kto'.+?)\\]? uczy cie mowic (?>w(?> jezyku)?|po) (?'jezyk'.+)\\.$"
    if self.uczyciemowic_trigger then
        killTrigger(self.uczyciemowic_trigger)
    end
    self.uczyciemowic_trigger = tempRegexTrigger(regexp2, function()
        self:uczyciemowic()
    end)

    local regexp3 = "^Wydaje ci sie, ze poczynil[ae]s (.+) postepy w nauce\\.$"
    if self.postepywnauce_trigger then
        killTrigger(self.postepywnauce_trigger)
    end
    self.postepywnauce_trigger = tempRegexTrigger(regexp3, function()
        self:postepywnauce()
    end)

    local regexp4 = "^Raczej niczego sie od (.+?) nie nauczysz\\.$"

    if self.maxnauki_trigger then
        killTrigger(self.maxnauki_trigger)
    end
    self.maxnauki_trigger = tempRegexTrigger(regexp4, function()
        self:maxnauki()
    end)

    scripts.plugins_update_check:github_check_version("arkadia-jezyki", "axesider")
end

function Jezyki:command(command)
    local cmd = {
        ["raport1"] = {
            opis = "raport uczenia sie",
            fun = function()
                self:print()
            end
        },
        ["raport2"] = {
            opis = "raport postepow w nauce",
            fun = function()
                self:print2()
            end
        },
        ["maksymalne"] = {
            opis = "jezyki maksymalne",
            fun = function()
                send("jezyki maksymalne")
            end
        }
    }

    if cmd[command] then
        cmd[command].fun()
    else
        for i, k in pairs(cmd) do
            echo("- ")
            cechoLink("<light_slate_blue>/jezyk " .. i .. "<reset>", k.fun, "", true)
            echo(" - " .. k.opis .. "\n")
        end
    end
end

Jezyki:Init()
