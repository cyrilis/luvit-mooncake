--
-- Created by Cyril Hou
-- Date: 15/9/28
-- Time: 2015-09-28 16:24:56
--
return {
    name = "cyrilis/mooncake",
    version = "0.1.11",
    homepage = "https://github.com/cyrilis/luvit-mooncake",
    description = "Web framework for Luvit lang.",
    tags = {"luvit", "web framework", "web", "application", "express", "mooncake", "framework"},
    license = "MIT",
    author = { name = "Cyril Hou", email = "houshoushuai@gmail.com"},
    dependencies = {
        "luvit/require",
        "luvit/pretty-print",
        "luvit/http",
        "luvit/https",
        "luvit/path",
        "luvit/fs",
        "luvit/json"
    },
    files = {
        "**.lua",
        "**.md",
        "**.html",
        "**.elua"
    }
}
