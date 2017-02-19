-- Some code from: https://github.com/voronianski/luvit-connect/blob/master/lib/helpers.lua

local floor = require('math').floor
local http = require('http')
local table = require('table')
local string = require('string')
local math = require('math')
require("./ansicolors")

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

-- microsecond precision
local ffi = require("ffi")

local getTime;
do
	if jit.os == "Windows" then
		ffi.cdef [[
			typedef unsigned long DWORD, *PDWORD, *LPDWORD;
			typedef struct _FILETIME {
			  DWORD dwLowDateTime;
			  DWORD dwHighDateTime;
			} FILETIME, *PFILETIME;

			void GetSystemTimeAsFileTime ( FILETIME* );
		]]
		local ft = ffi.new ( "FILETIME[1]" )
		getTime = function ( ) -- As found in luasocket's timeout.c
			ffi.C.GetSystemTimeAsFileTime ( ft )
			local t = tonumber ( ft[0].dwLowDateTime ) / 1e7 + tonumber ( ft[0].dwHighDateTime ) * ( 2^32 / 1e7 )
			-- Convert to Unix Epoch time (time since January 1, 1970 (UTC))
			t = t - 11644473600
			return math.floor(t * 1000 + 0.5)
		end
	else -- Assume posix

		if pcall(ffi.typeof, "struct timeval") then
		else
		    ffi.cdef[[
		        typedef long time_t;

		        typedef struct timeval {
		            time_t tv_sec;
		            time_t tv_usec;
		        } timeval;

		        int gettimeofday(struct timeval* t, void* tzp);
		    ]]
		end

		local gettimeofday_struct = ffi.new("timeval")
		getTime = function ()
		 	ffi.C.gettimeofday(gettimeofday_struct, nil)
		 	return tonumber(gettimeofday_struct.tv_sec) * 1000 + tonumber(gettimeofday_struct.tv_usec / 1000)
		end
	end
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
  local timeCosted = getTime() - req.start_time
  d(currentDate:dim(), " - [", stCode, "]", (" " .. tostring(req.method) .. " "):yellow(), (tostring(timeCosted) .. "ms "):cyan(), req.url:blue(), (" UserAgent: "):magenta(), req.headers["user-agent"])
end

local function calcEtag(stat)
  return (not stat.type == "file" and 'W/' or '') ..
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

local find , sub= string.find, string.sub
function split2(str, sep, nmax)
	if sep == nil then
		sep = '%s+'
	end
	local r = { }
	if #str <= 0 then
		return r
	end
	local plain = false
	nmax = nmax or -1
	local nf = 1
	local ns = 1
	local nfr, nl = find(str, sep, ns, plain)
	while nfr and nmax ~= 0 do
		r[nf] = sub(str, ns, nfr - 1)
		nf = nf + 1
		ns = nl + 1
		nmax = nmax - 1
		nfr, nl = find(str, sep, ns, plain)
	end
	r[nf] = sub(str, ns)
	return r
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
	split2 = split2,
	indexOf = indexOf,
	lastIndexOf = lastIndexOf,
	mime = mime,
	throwError = throwError,
	roundToDecimals = roundToDecimals,
	supportMethod = supportMethod,
	hasBody = hasBody,
  	copy = copy,
  	calcEtag = calcEtag,
  	log = log,
  	getTime = getTime
}
