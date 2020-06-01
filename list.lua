local tArg = {...}

local repoName = tArg[1] or "LDDestroier/STD-GUI"
local repoPath = tArg[2] or "default"

-- don't get any funny ideas, this key has zero permissions
local token = "0f7e97e6524dcb03f79978ff88235a510f5ff4ae"

std = std or {}
local verbose = false

std.aliases = {
	ldd = "~f&1LDD&8estroier",
	eldidi = "~f&1Eldidi&8Stroyrr",
	oeed = "~d&0oeed",
	lur = "~b&fLur",
	theoriginalbit = "&ftheoriginal&3bit",
	cloudninja = "~b&0Cloud Ninja",
	run = "&0~dRUN",
	download = "&0~dDOWNLOAD"
}

for k,v in pairs(std.aliases) do std.aliases[k] = v.."&r~r" end

std.storeCatagoryNames = {
	[1] = "Utility",			-- A general utility that doesn't fit into other categories.
	[2] = "Pocket",				-- Tailored specifically for pocket computers.
	[3] = "Game",				-- An actual game, not an animation or whatever.
	[4] = "Toy",				-- This is where animations and whatnot would go.
	[5] = "Operating System",	-- Links to an operating system install.
	[6] = "Networking",			-- More specific utilities that use modems.
	[7] = "Malicious",			-- Malicious code. Bad stuff.
	[8] = "API",				-- Code to help with code? What sorcery!
	[9] = "Turtle",				-- For turtles, using the Turtle API.
	[10] = "Command",			-- If it uses the command API in its core utility.
	[11] = "HTTP",				-- If it is centered around HTTP, put it here.
	[12] = "Error!"				-- if it is a broken STD-GUI entry...
}

std.storeCatagoryColors = {
	[1] = {
		txt = colors.black,
		bg = colors.pink
	},
	[2] = {
		txt = colors.white,
		bg = colors.red
	},
	[3] = {
		txt = colors.lightBlue,
		bg = colors.blue
	},
	[4] = {
		txt = colors.white,
		bg = colors.green
	},
	[5] = {
		txt = colors.black,
		bg = colors.white
	},
	[6] = {
		txt = colors.white,
		bg = colors.purple
	},
	[7] = {
		txt = colors.red,
		bg = colors.orange
	},
	[8] = {
		txt = colors.black,
		bg = colors.yellow
	},
	[9] = {
		txt = colors.white,
		bg = colors.brown
	},
	[10] = {
		txt = colors.gray,
		bg = colors.lime
	},
	[11] = {
		txt = colors.white,
		bg = colors.cyan
	},
	[12] = {
		txt = colors.white,
		bg = colors.red
	},
}

-- thank you ElvishJerricco for this JSON API
local json = {}
local controls = {["\n"]="\\n", ["\r"]="\\r", ["\t"]="\\t", ["\b"]="\\b", ["\f"]="\\f", ["\""]="\\\"", ["\\"]="\\\\"}
local function isArray(t)
	local max = 0
	for k,v in pairs(t) do
		if type(k) ~= "number" then
			return false
		elseif k > max then
			max = k
		end
	end
	return max == #t
end
local whites = {['\n']=true; ['\r']=true; ['\t']=true; [' ']=true; [',']=true; [':']=true}
function json.removeWhite(str)
	while whites[str:sub(1, 1)] do
		str = str:sub(2)
	end
	return str
end
local function encodeCommon(val, pretty, tabLevel, tTracking)
	local str = ""
	local function tab(s)
		str = str .. ("\t"):rep(tabLevel) .. s
	end
	local function arrEncoding(val, bracket, closeBracket, iterator, loopFunc)
		str = str .. bracket
		if pretty then
			str = str .. "\n"
			tabLevel = tabLevel + 1
		end
		for k,v in iterator(val) do
			tab("")
			loopFunc(k,v)
			str = str .. ","
			if pretty then str = str .. "\n" end
		end
		if pretty then
			tabLevel = tabLevel - 1
		end
		if str:sub(-2) == ",\n" then
			str = str:sub(1, -3) .. "\n"
		elseif str:sub(-1) == "," then
			str = str:sub(1, -2)
		end
		tab(closeBracket)
	end
	if type(val) == "table" then
		assert(not tTracking[val], "Cannot encode a table holding itself recursively")
		tTracking[val] = true
		if isArray(val) then
			arrEncoding(val, "[", "]", ipairs, function(k,v)
				str = str .. encodeCommon(v, pretty, tabLevel, tTracking)
			end)
		else
			arrEncoding(val, "{", "}", pairs, function(k,v)
				assert(type(k) == "string", "JSON object keys must be strings", 2)
				str = str .. encodeCommon(k, pretty, tabLevel, tTracking)
				str = str .. (pretty and ": " or ":") .. encodeCommon(v, pretty, tabLevel, tTracking)
			end)
		end
	elseif type(val) == "string" then
		str = '"' .. val:gsub("[%c\"\\]", controls) .. '"'
	elseif type(val) == "number" or type(val) == "boolean" then
		str = tostring(val)
	else
		error("JSON only supports arrays, objects, numbers, booleans, and strings", 2)
	end
	return str
end
function json.encode(val)
	return encodeCommon(val, false, 0, {})
end
function json.encodePretty(val)
	return encodeCommon(val, true, 0, {})
end
local decodeControls = {}
for k,v in pairs(controls) do
	decodeControls[v] = k
end
function json.parseBoolean(str)
	if str:sub(1, 4) == "true" then
		return true, json.removeWhite(str:sub(5))
	else
		return false, json.removeWhite(str:sub(6))
	end
end
function json.parseNull(str)
	return nil, json.removeWhite(str:sub(5))
end
local numChars = {['e']=true; ['E']=true; ['+']=true; ['-']=true; ['.']=true}
function json.parseNumber(str)
	local i = 1
	while numChars[str:sub(i, i)] or tonumber(str:sub(i, i)) do
		i = i + 1
	end
	local val = tonumber(str:sub(1, i - 1))
	str = json.removeWhite(str:sub(i))
	return val, str
end
function json.parseString(str)
	str = str:sub(2)
	local s = ""
	while str:sub(1,1) ~= "\"" do
		local next = str:sub(1,1)
		str = str:sub(2)
		assert(next ~= "\n", "Unclosed string")

		if next == "\\" then
			local escape = str:sub(1,1)
			str = str:sub(2)

			next = assert(decodeControls[next..escape], "Invalid escape character")
		end

		s = s .. next
	end
	return s, json.removeWhite(str:sub(2))
end
function json.parseArray(str)
	str = json.removeWhite(str:sub(2))

	local val = {}
	local i = 1
	while str:sub(1, 1) ~= "]" do
		local v = nil
		v, str = json.parseValue(str)
		val[i] = v
		i = i + 1
		str = json.removeWhite(str)
	end
	str = json.removeWhite(str:sub(2))
	return val, str
end
function json.parseObject(str)
	str = json.removeWhite(str:sub(2))

	local val = {}
	while str:sub(1, 1) ~= "}" do
		local k, v = nil, nil
		k, v, str = json.parseMember(str)
		val[k] = v
		str = json.removeWhite(str)
	end
	str = json.removeWhite(str:sub(2))
	return val, str
end
function json.parseMember(str)
	local k = nil
	k, str = json.parseValue(str)
	local val = nil
	val, str = json.parseValue(str)
	return k, val, str
end
function json.parseValue(str)
	local fchar = str:sub(1, 1)
	if fchar == "{" then
		return json.parseObject(str)
	elseif fchar == "[" then
		return json.parseArray(str)
	elseif tonumber(fchar) ~= nil or numChars[fchar] then
		return json.parseNumber(str)
	elseif str:sub(1, 4) == "true" or str:sub(1, 5) == "false" then
		return json.parseBoolean(str)
	elseif fchar == "\"" then
		return json.parseString(str)
	elseif str:sub(1, 4) == "null" then
		return json.parseNull(str)
	end
	return nil
end
function json.decode(str)
	str = json.removeWhite(str)
	t = json.parseValue(str)
	return t
end
function json.decodeFromFile(path)
	local file = assert(fs.open(path, "r"))
	local decoded = json.decode(file.readAll())
	file.close()
	return decoded
end

local getTableSize = function(tbl)
	local output = 0
	for k,v in pairs(tbl) do
		output = output + 1
	end
	return output
end

local function getSTDStoreList(files) --thanks squiddev
	if not files then return end
	local urls = {}
	local remaining = getTableSize(files)
	for name, url in pairs(files) do
		http.request(url)
		urls[url] = name
	end
	local contents
	while true do
		if remaining == 0 then
			break
		end
		local event, url, handle = os.pullEvent()
		local name = urls[url]
		if (event == "http_success") and (name and handle) then
			remaining = remaining - 1
			if verbose then
				write(".")
			end
			contents = handle.readAll()
			if contents then
				std.storeURLs[name] = textutils.unserialize(contents:gsub("std.aliases.%a+", function(i) return "\""..load("return "..i,nil,nil,{std = std})().."\"" end))
			else
				std.storeURLs[name] = {
					title = "ERROR ("..name..")",
					url = "",
					creator = "???",
					description = "This app is broken. Please contact LDDestroier on the forums and nag his ears off.",
					catagory = 12,
					forumPost = "n/a ",
					keywords = {"fucking","error"},
				}
			end
			handle.close()
			urls[url] = nil
		elseif event == "http_failure" and name then
			remaining = remaining - 1
			if verbose then
				write("x")
			end
			std.storeURLs[name] = {
				title = "ERROR ("..name..")",
				url = "",
				creator = "???",
				description = "This app cannot be downloaded. Please contact the developer and nag them.",
				catagory = 12,
				forumPost = "n/a ",
				keywords = {"fucking","error"},
			}
		end
	end
	return true
end

local listings = http.get("https://api.github.com/repos/" .. repoName .. "/contents/" .. repoPath), {Authorization = token})
local simulDownloads = {}
local amnt = 0
if listings then
	listings = json.decode(listings.readAll())
	std.storeURLs = {}
	for k,v in pairs(listings) do
		if v.name then
			simulDownloads[v.name] = v.download_url
			amnt = amnt + 1
		end
	end
	if verbose then
		print("\nFound " .. amnt .. " valid STD entries.")
		write("Attempting to download")
	end
	getSTDStoreList(simulDownloads)
else
	return false
end

-- if not std.std_version then return end

if ((std.std_version or 0) < 101) or requireInjector then

	local colors_names = {
		["0"] = colors.white,
		["1"] = colors.orange,
		["2"] = colors.magenta,
		["3"] = colors.lightBlue,
		["4"] = colors.yellow,
		["5"] = colors.lime,
		["6"] = colors.pink,
		["7"] = colors.gray,
		["8"] = colors.lightGray,
		["9"] = colors.cyan,
		["a"] = colors.purple,
		["b"] = colors.blue,
		["c"] = colors.brown,
		["d"] = colors.green,
		["e"] = colors.red,
		["f"] = colors.black,
	}
	local blit_names = {}
	for k,v in pairs(colors_names) do
		blit_names[v] = k
	end

	local codeNames = { --just for checking, not for any translation
		["r"] = "reset",
	}

	local moveOn
	local textToBlit = function(str)
		local p = 1
		local output = ""
		local txcolorout = ""
		local bgcolorout = ""
		local txcode = "&"
		local bgcode = "~"
		local doFormatting = true
		local usedformats = {}
		local txcol,bgcol = blit_names[term.getTextColor()], blit_names[term.getBackgroundColor()]
		local origTX,origBG = blit_names[term.getTextColor()], blit_names[term.getBackgroundColor()]
		local cx,cy
		moveOn = function(tx,bg)
			output = output..str:sub(p,p)
			txcolorout = txcolorout..tx --(doFormatting and tx or origTX)
			bgcolorout = bgcolorout..bg --(doFormatting and bg or origBG)
		end
		while p <= #str do
			if str:sub(p,p) == txcode then
				if colors_names[str:sub(p+1,p+1)] and doFormatting then
					txcol = str:sub(p+1,p+1)
					usedformats.txcol = true
					p = p + 1
				elseif codeNames[str:sub(p+1,p+1)] then
					if str:sub(p+1,p+1) == "r" and doFormatting then
						txcol = blit_names[term.getTextColor()]
						p = p + 1
					elseif str:sub(p+1,p+1) == "{" and doFormatting then
						doFormatting = false
						p = p + 1
					elseif str:sub(p+1,p+1) == "}" and (not doFormatting) then
						doFormatting = true
						p = p + 1
					else
						moveOn(txcol,bgcol)
					end
				else
					moveOn(txcol,bgcol)
				end
				p = p + 1
			elseif str:sub(p,p) == bgcode then
				if colors_names[str:sub(p+1,p+1)] and doFormatting then
					bgcol = str:sub(p+1,p+1)
					usedformats.bgcol = true
					p = p + 1
				elseif codeNames[str:sub(p+1,p+1)] and (str:sub(p+1,p+1) == "r") and doFormatting then
					bgcol = blit_names[term.getBackgroundColor()]
					p = p + 1
				else
					moveOn(txcol,bgcol)
				end
				p = p + 1
			else
				moveOn(txcol,bgcol)
				p = p + 1
			end
		end
		return output, txcolorout, bgcolorout, usedformats
	end

	for k,v in pairs(std.storeURLs) do
		std.storeURLs[k].title = textToBlit(std.storeURLs[k].title)
		std.storeURLs[k].creator = textToBlit(std.storeURLs[k].creator)
		std.storeURLs[k].description = textToBlit(std.storeURLs[k].description)
	end
end
--_G.std = std
