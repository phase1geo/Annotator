# Annotator

<p align="center">
  <a href="https://appcenter.elementary.io/com.github.phase1geo.annotator">
    <img src="https://appcenter.elementary.io/badge.svg" alt="Get it on AppCenter"/>
  </a>
</p>

![<center><b>Main Window - Light Theme</b></center>](https://raw.githubusercontent.com/phase1geo/Annotator/master/data/screenshots/screenshot-editor.png "Image Annotation for Elementary OS")

## Overview

Annotate your images and let a picture say 1000 words.

- Load image from the file system, clipboard, or create a screenshot to annotate.
- Add shapes, stickers, images, text, drawings, and other callouts to highlight image details.
- Add magnifiers to enhance image details.
- Blur out portions of the image to obfuscate data.
- Crop, resize and add image borders.
- Control colors, line thickness and font details.
- Zoom support.
- Color picker support within a loaded image.
- Unlimited undo/redo of any change.
- Drag-and-drop PNG copies of the annotated image.
- Export to JPEG, PNG, TIFF, BMP, PDF, SVG and WebP image formats.
- Support for copying annotated image to clipboard.
- Printer support.

## Installation

### Debian (from source)

You will need the following dependencies to build Annotator:

- meson
- valac
- debhelper
- gobject-2.0
- glib-2.0
- libgee-0.8-dev
- libgranite-dev
- libxml2-dev
- libgtk-3-dev
- libhandy-1-dev
- libwebp-dev

To install Annotator from source, run `./app install`.

To run Annotator, run `com.github.phase1geo.annotator`.

### Ubuntu (PPA)

You can use the [PPA](https://launchpad.net/~ubuntuhandbook1/+archive/ubuntu/annotator/) maintained by @PandaJim. The PPA supports Ubuntu 20.04+. Enter the following commands one by one

```
sudo add-apt-repository ppa:ubuntuhandbook1/annotator
sudo apt update
sudo apt install com.github.phase1geo.annotator
```

### Arch Linux

If you're an Arch Linux user, there's an
[AUR package](https://aur.archlinux.org/packages/annotator/)
`annotator`:

```
% yay -S annotator
```

### Flatpak

Additionally, Annotator can be installed and run via Flatpak.

To build and install the Flatpak from source, run `./app flatpak`.

Afterwards, you can run it via: `flatpak run com.github.phase1geo.annotator`.

<p align="center">
  <a href="https://appcenter.elementary.io/com.github.phase1geo.annotator">
    <img src="https://appcenter.elementary.io/badge.svg" alt="Get it on AppCenter"/>
  </a>
</p>

## Credits

Incorporates `document-edit-symbolic.svg` and `image-crop-symbolic.svg` from
[elementary/icons](https://github.com/elementary/icons/tree/main/actions/symbolic),
under the terms of the GPL v3.0 license.
