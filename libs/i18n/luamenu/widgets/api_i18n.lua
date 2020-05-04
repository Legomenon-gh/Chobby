--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

function widget:GetInfo()
	return {
		name      = "i18n",
		desc      = "Internationalization library for Spring",
		author    = "gajop",
		date      = "WIP",
		license   = "GPLv2",
		version   = "0.1",
		layer     = -1000,
		enabled   = true,  --  loaded by default?
		handler   = true,
		api       = true,
		hidden    = true,
	}
end

local function GetDirectory(filepath)
	return filepath and filepath:gsub("(.*/)(.*)", "%1")
end

assert(debug)
local source = debug and debug.getinfo(1).source
local DIR = GetDirectory(source)


I18N_PATH = DIR .. "i18nlib/i18n/"
TRANSLATIONS_PATH = "LuaMenu/widgets/chobby/i18n/"

function widget:Initialize()
	WG.i18n = VFS.Include(I18N_PATH .. "init.lua", nil, VFS.ZIP)
end

local langValue="en"
local langListeners={}

local translationExtras = { -- lists databases to be merged into the main one
	-- dev strings are in a separate file for code consistency but will not be translated
	lobby = {"dev"}
}

local translations = {
	lobby = true
}

local function addListener(l, widgetName)
	if l and type(l)=="function" then
		local okay, err = pcall(l)
		if okay then
			langListeners[widgetName]=l
		else
			Spring.Echo("i18n API subscribe failed: " .. widgetName .. "\nCause: " .. err)
		end
	end
end

local function loadLocale(i18n,database,locale)
	local path=TRANSLATIONS_PATH..database.."."..locale..".json"
	if VFS.FileExists(path, VFS.ZIP) then
		local lang=Spring.Utilities.json.decode(VFS.LoadFile(path, VFS.ZIP))
		local t={}
		t[locale]=lang
		i18n.load(t)
		return true
	end
	Spring.Echo("Cannot load locale \""..locale.."\" for "..database)
	return false
end

local function fireLangChange()

	for db, trans in pairs(translations) do
		if not trans.locales[langValue] then
			local extras = translationExtras[db]
			if extras then
				for i = 1, #extras do
					loadLocale(trans.i18n, extras[i], langValue)
				end
			end
			loadLocale(trans.i18n, db, langValue)
			trans.locales[langValue] = true
		end
		trans.i18n.setLocale(langValue)
	end

	for w,f in pairs(langListeners) do
		local okay,err=pcall(f)
		if not okay then
			Spring.Echo("i18n API update failed: " .. w .. "\nCause: " .. err)
			langListeners[w]=nil
		end
	end
end

local function lang (newLang)
	if not newLang then
		return langValue
	elseif langValue ~= newLang then
		langValue = newLang
		fireLangChange()
	end
end

local function initializeTranslation(database)
	local trans = {
		i18n = VFS.Include(I18N_PATH .. "init.lua", nil),
		locales = {en = true},
	}
	loadLocale(trans.i18n,database,"en")

	local extras = translationExtras[database]
	if extras then
		for i = 1, #extras do
			loadLocale(trans.i18n, extras[i], "en")
		end
	end

	return trans
end

local function shutdownTranslation(widget_name)
	langListeners[widget_name]=nil
end

local function Translate(text, data)
	return translations["lobby"].i18n(text, data)
end

WG.SetLanguage = lang
WG.InitializeTranslation = addListener
WG.ShutdownTranslation = shutdownTranslation
WG.Translate = Translate

for db in pairs(translations) do
	translations[db] = initializeTranslation (db)
end
