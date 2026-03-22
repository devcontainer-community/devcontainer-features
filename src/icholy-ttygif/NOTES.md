# icholy/ttygif

## Project

- [icholy/ttygif](https://github.com/icholy/ttygif)

## Description

`ttygif` converts a ttyrec terminal recording file into animated GIF files. It captures every frame of a terminal session recorded with `ttyrec` and assembles them into a GIF using ImageMagick.

## Installation Method

Built from source using the [GitHub release tarball](https://github.com/icholy/ttygif/releases) and installed to `/usr/local/bin` via `make install`. Build dependencies (`gcc`, `make`) and runtime dependencies (`imagemagick`, `ttyrec`, `x11-apps`) are installed via APT.

## Other Notes

Because `ttygif` uses `xwd` to capture X11 window screenshots at runtime, it requires a running X server (or virtual framebuffer such as `Xvfb`) when actually recording GIFs. The binary can be installed in a headless container but will need an X11 environment to function fully.
