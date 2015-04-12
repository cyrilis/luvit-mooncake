local fs = require("fs");
local pathJoin = require('luvi').path.join

function getDirData (dir, files, rootDir)
  dirFiles = fs.readdirSync(dir)
  files = files or {}
  for _, file in pairs(dirFiles) do
    objPath = pathJoin(dir, file)
    stat = fs.statSync(objPath)
    if stat.type == "file" then
      filePath = file
      if rootDir and rootDir ~= dir then
        filePath = string.gsub(objPath, rootDir, "")
      end
      files[filePath] = stat
    else
      getDirData(objPath, files, rootDir or dir)
    end
  end
  return files
end

function readDirFile (dir, options)
  return getDirData(dir, nil, dir)
end

exports.readDirFile = readDirFile
