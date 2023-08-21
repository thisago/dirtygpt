# Package

version       = "0.1.0"
author        = "Thiago Navarro"
description   = "A dirty and free way to use ChatGPT in Nim"
license       = "MIT"
srcDir        = "src"
# installExt = @["nim"]


# Dependencies

requires "nim >= 1.6.4"

# For userscript
requires "gm_api"
requires "jswebsockets"

# For lib
requires "ws"


from std/strformat import fmt
from std/strutils import replace
from std/base64 import encode
from std/os import `/`

when dirExists getCurrentDir() / "src":
  binDir = "build"
  import src/dirtygpt/header
  var nimUserscript = "src/"
else:
  binDir = "."
  import dirtygpt/header
  var nimUserscript = ""

nimUserscript.add "userscript"

let
  jsOutFile = binDir / "userscript.js"
  userscriptOutFile = binDir / "userscript.user.js"

task finalizeUserscript, "Uglify and add header":
  exec fmt"uglifyjs -o {jsOutFile} {jsOutFile}"
  userscriptOutFile.writeFile userscriptHeader & "\n" & jsOutFile.readFile
  rmFile jsOutFile

task buildUserscriptRelease, "Build release version":
  exec fmt"nim js --outDir:{binDir} -d:danger {nimUserscript}"
  finalizeUserscriptTask()

after install:
  buildUserscriptReleaseTask()
  echo "\l\lPlease, don't forget to install the client userscript in your browser: " & getCurrentDir() / userscriptOutFile
