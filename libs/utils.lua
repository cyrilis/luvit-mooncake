local floor = require('math').floor
local table = require 'table'

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

exports.calcEtag = calcEtag
exports.copy = copy
