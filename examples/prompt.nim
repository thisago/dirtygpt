import std/asyncdispatch
import pkg/dirtygpt

let gpt = newDirtyGpt()

echo waitFor gpt.prompt "Hello, are you Google Bard?"

stop gpt
