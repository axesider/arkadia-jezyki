Jezyki = Jezyki or {
    tryb = 0
}

local Jezyk2nazwa = {
    ["bretonsku"] = "bretonski",
    ["Drukh-Eltharin"] = "drukh-eltharin",
        ["estalijsku"] = "estalijski",
    ["Fan-Eltharin"] = "fan-eltharin",
    ["gnomiemu"] = "gnomi",
    ["Grumbarth"] = "grumbarth",
    ["halflinsku"] = "halflinski",
        ["khazalidzie"] = "khazalid",
    ["kislevicku"] = "kislevicki",
    ["Krasnoludow Mahakamskich"] = "krasnoludzki",
        ["nilfgaardzku"] = "nilfgaardzki",
    ["norskim"] = "norski",
    ["Reikspielu"] = "reikspiel",
    ["skelligansku"] = "skelliganski",
    ["tileansku"] = "tileanski",
        ["starszej mowie"] = "starsza mowa",
        ["Tar-Eltharin"] = "tar-eltharin",
    ["zerrikansku"] = "zerrikanski",   
        ["ghassally"] = "ghassally",
}

misc["lang_desc"] = {["znikoma"] = 1, ["niewielka"] = 2, ["czesciowa"] = 3, ["niezla"] = 4, ["dosc dobra"] = 5, ["dobra"] = 6, ["bardzo dobra"] = 7, ["doskonala"] = 8, ["prawie pelna"] = 9, ["pelna"] = 10}

Jezyki.db = db:create("nauka", {
    nauka = {
      jezyk = "",
      character = "",
      nauczyciel = "",
      postepy = "",
      datetime = "",
      changed = db:Timestamp("CURRENT_TIMESTAMP"),
      _index = { "jezyk"}
    },
    jezyki = {
        nazwa = "",
        poziom = "",
        character = "",
        datetime = "",
        changed = db:Timestamp("CURRENT_TIMESTAMP"),
    },
    jezyki_max = {
        nazwa = "",
        poziom = "",
        character = "",
        _index = { "nazwa" },
        _unique = { "nazwa" },
        _violations = "REPLACE"
    }
  })

-- overload arkadia\skrypty\misc.lua
function alias_func_skrypty_misc_jezyki()
    Jezyki.tryb = 1
    Jezyki:enableTrigger()
    tempTimer(0.1, function() send("jezyki", false) end)
    tempTimer(1, function() Jezyki:disableTrigger() end)
end
-- overload end

function alias_func_skrypty_misc_jezyki_maksymalne()
    Jezyki.tryb = 2
    Jezyki:enableTrigger()
    tempTimer(0.1, function() send("jezyki maksymalne", false) end)
    tempTimer(1, function() Jezyki:disableTrigger() end)
end

function alias_func_jezyk_command()
    Jezyki:command(matches[2])
end

function Jezyki:enableTrigger()
    local regexp = "^([a-z]\\w+(?>[ -]\\w+)?):\\s+(.+)$"
    if self.jezyki_trigger then killTrigger(self.jezyki_trigger) self.jezyki_trigger = nil end
    self.jezyki_trigger = tempRegexTrigger(regexp, function() self:parse() end)
end

function Jezyki:disableTrigger()
    if self.jezyki_trigger then killTrigger(self.jezyki_trigger) self.jezyki_trigger = nil end
    self.tryb = 0
end

function Jezyki:parse()
    local nazwa = matches[2]
    local poziom = matches[3]
    if self.tryb == 1 then
        local lv = misc.lang_desc[poziom]
        local lv_max = self:get_jezyk_max(nazwa)
        
        local sub =""
        local r = db:fetch_sql(self.db.nauka, "select f.nauczyciel, f.jezyk, f.postepy, strftime('%Y-%m-%d %H:%M',f.changed, 'localtime') as datetime from nauka as f where f.changed > (select MAX(changed) as max_date FROM jezyki where nazwa = f.jezyk ) and f.jezyk = '"..nazwa.."' and f.character = '".. scripts.character_name .."'")
        for key, val in pairs(r) do
                if val["postepy"] == "minimalne" then sub = sub .."1"
            elseif val["postepy"] == "nieznaczne" then sub = sub .."2"
            else sub = sub .."3" end
        end
        
        selectString(nazwa, 1)
        setLink(function() send("justaw "..nazwa)end, "zmien jezyk na "..nazwa)
        
        local add_text = string.rep(" ", 13 - string.len(poziom)) .. " [<green>" ..string.rep("=",lv).."<red>" .. string.rep("-",lv_max-lv) .."<reset>".. string.rep(" ",10-lv_max) .. "]" .. sub
        --local add_text = string.rep(" ", 13 - string.len(poziom)) .. "<DarkSlateBlue>" ..string.rep("#",lv).."<light_pink>" .. string.rep("-",lv_max-lv) .."<reset>"
        cecho(add_text)
        self:insert_jezyk(nazwa, poziom)
    elseif self.tryb == 2 then
        self:insert_jezyk_max(nazwa, poziom)
    end
end

-- db:fetch_sql(Jezyki.db.jezyki_max, "select * from jezyki_max")
function Jezyki:get_jezyk_max(nazwa)
    local q = "select poziom from jezyki_max where nazwa='"..nazwa.."' and character = '".. scripts.character_name .."'"
    local r = db:fetch_sql(self.db.jezyki_max, q)
    if table.size(r) > 0 then
        return misc["lang_desc"][r[1]['poziom']]
    else
        return 10
    end
end

function Jezyki:insert_jezyk_max(nazwa, poziom)
    db:add(self.db.jezyki_max, { nazwa = nazwa, poziom = poziom, character = scripts.character_name })
    --local q = "select poziom from jezyki_max where nazwa='"..nazwa
    --local r = db:fetch_sql(self.db.jezyki_max, q)
    --if table.size(r) == 0 then
    --    db:add(self.db.jezyki_max, { nazwa = nazwa, poziom = poziom })
    --else
    --    local query = "update jezyki_max set poziom = '"..poziom.."' where nazwa = '"..nazwa.."'"
    --    db:fetch_sql(self.db.jezyki_max, query)
    --end
end

-- db:add(Jezyki.db.nauka, { jezyk = "krasnoludzki", nauczyciel = "Vorid", postepy= "minimalne", changed=db:Timestamp(os.time({year=2021, month=11, day=25, hour=16, minute=50}))})
function Jezyki:insert_jezyk(nazwa, poziom)
    local q = "select * from jezyki where nazwa='"..nazwa.."' and poziom='"..poziom.."' and character = '".. scripts.character_name .."'"
    local r = db:fetch_sql(self.db.jezyki, q)
    if r == nil or table.size(r) == 0 then
        db:add(self.db.jezyki, { nazwa = nazwa, poziom = poziom, character = scripts.character_name })
    end
end

function Jezyki:Flush()
    db:add(self.db.nauka, { jezyk = self.temp_jezyk, nauczyciel = self.temp_nauczyciel, postepy= self.temp_postepy, character = scripts.character_name})
    echo("{"..self.temp_jezyk .."|".. self.temp_nauczyciel .."|".. self.temp_postepy.."}\n")
end

function Jezyki:chcecieuczyc()
    local name = matches[2]
    local lowered_name = string.lower(name)
    local obj_to_join = nil

    if not Jezyk2nazwa[matches[3]] then
        echo("Co to '"..matches[3].."'\n")
        Jezyki:wybierz()
    end
    for k, v in pairs(gmcp.objects.nums) do
        if ateam.objs[v]["desc"] == name or ateam.objs[v]["desc"] == lowered_name and not ateam.objs[v].enemy and not table.index_of(scripts.people.enemy_people)then
            local command = "jucz sie jezyka od ob_".. v
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
    for k,_ in pairs(misc.lang.languages) do
        local znany = false
        for _,v in pairs(Jezyk2nazwa) do
            if v == k then znany = true break end
        end
        if znany == false then
            echo(" ")
            cechoLink("<light_slate_blue>".. k .. "<reset>", function() Jezyki.temp_jezyk = k end, "ustaw "..k, true)
        end
    end
    echo("\n")
end

function Jezyki:uczyciemowic()
    self.temp_nauczyciel = matches[2]
    
    if Jezyk2nazwa[matches[3]] then 
        self.temp_jezyk = Jezyk2nazwa[matches[3]]
    else
        scripts:print_log("Blad. Nieznany jezyk "..self.temp_jezyk)
    end
end

function Jezyki:postepywnauce()
    self.temp_postepy = matches[2]
    scripts.utils.bind_functional("jezyki", false, false)
    self:Flush()
end

function Jezyki:print2()
  local q = "select nazwa, poziom, strftime('%Y-%m-%d %H:%M',changed, 'localtime') as datetime from jezyki order by nazwa,datetime"
  local r = db:fetch_sql(Jezyki.db.jezyki, q)
  for key, val in pairs(r) do
    cecho(val["datetime"].." <green>".. val["nazwa"].."<reset> "..val["poziom"].."\n")
  end
end

function Jezyki:print()
  local q = "select f.nauczyciel, f.jezyk, f.postepy, strftime('%Y-%m-%d %H:%M',f.changed, 'localtime') as datetime from nauka as f order by datetime"
  local r = db:fetch_sql(Jezyki.db.nauka, q)
  for key, val in pairs(r) do
    cecho(val["datetime"].." ".. val["nauczyciel"]..string.rep(" ", 12 - string.len(val["nauczyciel"])).."<green>"..val["jezyk"].."<reset>"..string.rep(" ", 13 - string.len(val["jezyk"]))..val["postepy"].."\n")
  end 
end

function Jezyki:Init()
    local regexp = "^.*([A-Z]\\w+).* chce cie uczyc mowic (?>w(?> jezyku)?|po) (.+)\\.$"
    if self.chcecieuczyc_trigger then killTrigger(self.chcecieuczyc_trigger) end
    self.chcecieuczyc_trigger = tempRegexTrigger(regexp, function() self:chcecieuczyc() end)
    
    local regexp2 = "^(.+) uczy cie mowic (?>w(?> jezyku)?|po) (.+)\\.$"
    if self.uczyciemowic_trigger then killTrigger(self.uczyciemowic_trigger) end
    self.uczyciemowic_trigger = tempRegexTrigger(regexp2, function() self:uczyciemowic() end)

    local regexp3 = "^Wydaje ci sie, ze poczynil[ae]s (.+) postepy w nauce\\.$"
    if self.postepywnauce_trigger then killTrigger(self.postepywnauce_trigger) end
    self.postepywnauce_trigger = tempRegexTrigger(regexp3, function() self:postepywnauce() end)
    

    local r = "^Raczej niczego sie od (.+) nie nauczysz\\.$"
    
    local r = db:fetch_sql(Jezyki.db.jezyki_max, "select count(*) as poziom from jezyki_max where character = '".. scripts.character_name .."'")
    if r == nil or table.size(r) == 0 then
        cecho("Wykonaj komende:")
        cechoLink("<light_slate_blue>jezyki maksymalne<reset>", [[send("jezyki maksymalne")]], "jezyki maksymalne", true)
        cecho("\n")
    end
end

function Jezyki:command(command)
    local cmd = {
        ["raport1"]       = {opis = "raport uczenia sie", fun = function() Jezyki:print() end},
        ["raport2"]       = {opis = "raport postepow w nauce", fun = function() Jezyki:print2() end},
    }
    
    if cmd[command] then
       cmd[command].fun()
    else
        for i, k in pairs(cmd) do 
            echo("- ")
            cechoLink("<light_slate_blue>/jezyk ".. i .. "<reset>", k.fun, "", true)
            echo(" - ".. k.opis .. "\n")
        end
    end
end

Jezyki:Init()
