<div align=center>

# DirtyGPT

#### A dirty and free way to use ChatGPT in Nim

</div>

## About

Prompt in ChatGPT web using Nim!

## How it works?

The client userscript controls the ChatGPT webpage, it connects with backend,
the lib via Websocket and wait the prompts. Once that userscript receives, it
prompts to AI manipulating DOM and send to backend the answered MD.

## TODO

- [ ] Add pinging because `connectedClients` is just updated when exceeds timeout

## License

This piece of software is libre, licensed over the MIT license.
