import pkg/gm_api/metadata

const userscriptHeader* = genMetadataBlock(
  name = "DirtyGPT",
  description = "A dirty and free way to use ChatGPT in Nim",
  author = "Thiago Navarro",
  version = "0.1.0",
  match = [
    "https://chat.openai.com/*"
  ],
  runAt = GmRunAt.docIdle,
  require = [
    "https://unpkg.com/turndown/dist/turndown.js",
  ]
)
