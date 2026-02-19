# LAN Detector
<p align="center" width="100%">
    <img width="15%" src="https://raw.githubusercontent.com/jmscreation/gdplugin-lan-detector/refs/heads/main/logo.png">
</p>

## This plugin quickly and simply establishes a peer to peer connection within the [local broadcast domain](https://en.wikipedia.org/wiki/Broadcast_domain) automatically.

It's simple to use:
### Server
Attach the script `lan_detector_server.gd` to your Node, and add it to your scene tree.
This will start a server.

### Client
Attach the script `lan_detector_client.gd` to your Node, and add it to your scene tree.
This will start searching for the server within the local broadcast domain.


### Communication
You can send and receive simple short commands by using the `send()` function and by connecting to the `on_peer_message(msg:LANDATA.TYPE, data:Variant)` signal.

Here's a basic server example
```gdscript

var server = lan_detector_server

func _ready():
  server.on_peer_message.connect(received)
  server.on_peer_connected.connect(connected)

func connected():
  server.send(LANDATA.TYPE.ECHO, "Hello World")

func received(msg, data):
  if msg == LANDATA.TYPE.REPLY:
    print("Reply: " + data)

```

Here's a basic client example
```gdscript

var client = lan_detector_client

func _ready():
  client.on_peer_message.connect(received)

func received(msg, data):
  if msg == LANDATA.TYPE.ECHO:
    client.send(LANDATA.TYPE.REPLY, data)

```

In the code examples, we assume the following:
 - Both `lan_detector_server` and `lan_detector_client` are project Autoloads that have each been set to a Node which should have the appropriate script attached.
 - The `LANDATA.TYPE` enum has `ECHO` and `REPLY` defined.

When both the server and client are both running within the same local broadcast domain, they should automatically be established. Once established, the `on_peer_connected()` signal will be emitted. This causes the server to send an echo to the client, then the client responds back to the server with the data.

_Note that the firewall on the server must allow incoming UDP connections_
_Note that you cannot send more than ~1500 bytes as this does not support fragmentation_
