-- Some code from: https://github.com/voronianski/luvit-connect/blob/master/lib/helpers.lua

local floor = require('math').floor
local http = require('http')
local table = require('table')
local string = require('string')
local math = require('math')
require("./ansicolors")
local uv = require("uv")
timer = require("timer")

local digits = {
  "0", "1", "2", "3", "4", "5", "6", "7",
  "8", "9", "A", "B", "C", "D", "E", "F",
  "G", "H", "I", "J", "K", "L", "M", "N",
  "O", "P", "Q", "R", "S", "T", "U", "V",
  "W", "X", "Y", "Z", "a", "b", "c", "d",
  "e", "f", "g", "h", "i", "j", "k", "l",
  "m", "n", "o", "p", "q", "r", "s", "t",
  "u", "v", "w", "x", "y", "z", "_", "$"
}

local function numToBase(num, base)
  local parts = {}
  repeat
    table.insert(parts, digits[(num % base) + 1])
    num = floor(num / base)
  until num == 0
  return table.concat(parts)
end


local function log (req, res)
  local currentDate = os.date("[%Y-%m-%d %H:%M:%S]"):dim()
  local statusCode = res.statusCode
  local stCode = ""
  if 100 <= statusCode and statusCode < 200 then
    stCode = tostring(statusCode):red()
  elseif 200 <= statusCode and statusCode < 300 then
    stCode = tostring(statusCode):green()
  elseif 300 <= statusCode and statusCode < 400 then
    stCode = tostring(statusCode):blue()
  elseif 400 <= statusCode and statusCode < 500 then
    stCode = tostring(statusCode):yellow()
  else
    stCode = tostring(statusCode):red()
  end
  timer.setImmediate(function()
    uv.update_time()
    timeCosted = uv.now() - req.start_time
    print(currentDate:dim(), " - [", stCode, "]", (" " .. tostring(req.method) .. " "):yellow(), (tostring(timeCosted) .. "ms "):cyan(), req.url:blue(), (" UserAgent: "):magenta(), req.headers["user-agent"])
  end)
end

local function calcEtag(stat)
  return (not stat.is_file and 'W/' or '') ..
         '"' .. numToBase(stat.ino or 0, 64) ..
         '-' .. numToBase(stat.size, 64) ..
         '-' .. numToBase(stat.mtime.sec, 64) .. '"'
end

local function copy(obj, seen)
  if type(obj) ~= 'table' then return obj end
  if seen and seen[obj] then return seen[obj] end
  local s = seen or {}
  local res = setmetatable({}, getmetatable(obj))
  s[obj] = res
  for k, v in pairs(obj) do res[copy(k, s)] = copy(v, s) end
  return res
end

-- nil, boolean, number, string, userdata, function, thread, and table.
function colorise (anything)
  typeStr = type(anything)
  str = tostring(anything)
  if typeStr == "nil" then
    return str:dim()
  elseif typeStr == "boolean" then
    return str:cyan()
  elseif typeStr == "number" then
    return str:red()
  elseif typeStr == "string" then
    return str:yellow()
  elseif typeStr == "userdata" then
    return str:cyan()
  elseif typeStr == "function" then
    return str:blue()
  elseif typeStr == "thread" then
    return str:white()
  elseif typeStr == "table" then
    return str:magenta()
  end
end

-- pretty print of tables to console
function tprint (tbl, indent)
	indent = indent or 0
  if indent >= 5 then return false end
	for key, value in pairs(tbl) do

    key = colorise(key)

		formatting = string.rep('  ', indent) .. key .. ': '

		if type(value) == 'table' then
			print(formatting)
			tprint(value, indent + 1)
		else
			print(formatting .. colorise(value))
		end
	end
end

-- filter values from table
function filter (tbl, fn)
	local result = {}

	if not tbl or type(tbl) ~= 'table' then return result end

	for key, value in pairs(tbl) do
		if fn(value, key, tbl) then
			table.insert(result, value)
		end
	end

	return result
end

-- round number to decimals, defaults to 2 decimals
function roundToDecimals (num, decimals)
	decimals = decimals or 2
	local shift = 10 ^ decimals
	local result = math.floor(num * shift + 0.5) / shift
	return result
end

-- merge table2 into table1
function merge (table1, table2)
	for key, value in pairs(table2) do
		table1[key] = value
	end
	return table1
end

-- get index of field in table or character in string
function indexOf (target, field)
	if type(target) == 'string' then
		return target:find(field, 1, true)
	end

	for index, value in pairs(target) do
		if value == field then
			return index
		end
	end

	return nil
end

-- last index of an element in string
function lastIndexOf (str, elem)
	if type(str) ~= 'string' then error('string required') end
	if type(str) ~= 'string' then error('elem required') end

	local index = str:match('.*' .. elem .. '()')
	if not index then
		return nil
	else
		return index - 1
	end
end

-- split string
function split (str, sep)
	sep = sep or '%s+'

	local result = {}
	local i = 1

	for value in str:gmatch('([^' .. sep .. ']+)') do
		result[i] = value
		i = i + 1
	end

	return result
end

-- create an error table to throw
function throwError (code, msg)
	return {
		status = code,
		msg = msg or http.STATUS_CODES[code]
	}
end

return {
	merge = merge,
	tprint = tprint,
	filter = filter,
	split = split,
	indexOf = indexOf,
	lastIndexOf = lastIndexOf,
	mime = mime,
	throwError = throwError,
	roundToDecimals = roundToDecimals,
	supportMethod = supportMethod,
	hasBody = hasBody,
  copy = copy,
  calcEtag = calcEtag,
  log = log
}
