# ESP development image

XFCE development desktop streamed by Selkies 2 and intended for the `esp-dev`
Coder template. The image provides `selkies-session`; Coder starts it through
Selkies' official Terraform module and proxies it over an authenticated path.

## Included toolchains

- ESP-IDF and Espressif OpenOCD/toolchains
- Arduino CLI
- ESPHome
- PlatformIO and PIOArduino
- esptool and `esp_rfc2217_server`
- CMake, Ninja, GCC, Clang, GDB and ccache
- Python, Node.js, Git, GitHub CLI and Codex CLI
- Chromium, MQTT and serial/network troubleshooting tools

The image contains no credentials. GitHub, Codex, MQTT and device credentials
must be configured at runtime and are persisted under `/home/coder`.

ESP-IDF toolchains are installed into `/home/coder/.espressif` during the first
workspace start. This keeps OCI layers small enough for Talos/containerd and
persists the downloaded tools across workspace restarts and image updates.

## Remote serial

An RFC2217 endpoint can be used without exposing USB devices to the workspace:

```bash
esp_rfc2217_server --help
esptool --port 'rfc2217://HOST:PORT?ign_set_control' chip-id
```

Keep RFC2217 on a trusted private network. It does not provide transport
encryption or authentication by itself.

## Local build

```bash
docker build -t esp-dev:local images/esp-dev
```
