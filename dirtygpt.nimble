# Package

version       = "0.1.0"
author        = "Thiago Navarro"
description   = "A dirty and free way to use ChatGPT in Nim"
license       = "MIT"
srcDir        = "src"
bin = @["userscript"]

installExt = @["nim"]

backend = "js" # for bin (client userscript)

binDir = "build"

# Dependencies

requires "nim >= 1.6.4"

# For userscript
requires "gm_api"
requires "jswebsockets"

# For lib
requires "ws"

import src/dirtygpt/header

from std/strformat import fmt
from std/strutils import replace
from std/base64 import encode
from std/os import `/`

task finalizeUserscript, "Uglify and add header":
  let
    f = binDir / bin[0] & "." & backend
    outF = binDir / bin[0] & ".user." & backend
  exec fmt"uglifyjs -o {f} {f}"
  outF.writeFile userscriptHeader & "\n" & f.readFile
  rmFile f

task buildUserscriptRelease, "Build release version":
  exec "nimble -d:danger build"
  finalizeUserscriptTask()
