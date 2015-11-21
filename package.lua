--
-- Created by Cyril Hou
-- Date: 15/9/28
-- Time: 2015-09-28 16:24:56
--
return {
    name = "cyrilis/mooncake",
    version = "0.0.10",
    homepage = "https://github.com/cyrilis/luvit-mooncake",
    description = "Web framework for Luvit lang.",
    tags = {"luvit", "web framework", "web", "application", "express", "mooncake", "framework"},
    license = "MIT",
    author = { name = "Cyril Hou" },
    dependencies = {
        "luvit/require",
        "luvit/pretty-print",
    },
    files = {
        "**.lua",
        "**.md",
        "**.html"
    }
}

