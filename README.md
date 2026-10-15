# Coder images and templates

Reproducible development environments for the Coder deployment at
`https://coder.myk8s.se`.

## ESP development desktop

The first image and template target ESP32 development with:

- XFCE streamed through Selkies
- Microsoft Visual Studio Code with curated extensions
- ESP-IDF, Arduino CLI, ESPHome, PlatformIO, OpenOCD and esptool
- Intel i915 hardware acceleration through the Kubernetes device plugin
- Coder agent support in the same toolchain image

See [images/esp-dev/README.md](images/esp-dev/README.md) and
[templates/esp-dev/README.md](templates/esp-dev/README.md).

## Repository layout

```text
images/esp-dev/     OCI image source
templates/esp-dev/  Coder Kubernetes template
```

Images are built by GitHub Actions and published to:

```text
ghcr.io/exhalesthlm/coder-images-and-templates/esp-dev
```

## ESP32 Development
