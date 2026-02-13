
<div align="right">
  <details>
    <summary >🌐 Language</summary>
    <div>
      <div align="center">
        <a href="https://openaitx.github.io/view.html?user=phase1geo&project=Annotator&lang=en">English</a>
        | <a href="https://openaitx.github.io/view.html?user=phase1geo&project=Annotator&lang=zh-CN">简体中文</a>
        | <a href="https://openaitx.github.io/view.html?user=phase1geo&project=Annotator&lang=zh-TW">繁體中文</a>
        | <a href="https://openaitx.github.io/view.html?user=phase1geo&project=Annotator&lang=ja">日本語</a>
        | <a href="https://openaitx.github.io/view.html?user=phase1geo&project=Annotator&lang=ko">한국어</a>
        | <a href="https://openaitx.github.io/view.html?user=phase1geo&project=Annotator&lang=hi">हिन्दी</a>
        | <a href="https://openaitx.github.io/view.html?user=phase1geo&project=Annotator&lang=th">ไทย</a>
        | <a href="https://openaitx.github.io/view.html?user=phase1geo&project=Annotator&lang=fr">Français</a>
        | <a href="https://openaitx.github.io/view.html?user=phase1geo&project=Annotator&lang=de">Deutsch</a>
        | <a href="https://openaitx.github.io/view.html?user=phase1geo&project=Annotator&lang=es">Español</a>
        | <a href="https://openaitx.github.io/view.html?user=phase1geo&project=Annotator&lang=it">Italiano</a>
        | <a href="https://openaitx.github.io/view.html?user=phase1geo&project=Annotator&lang=ru">Русский</a>
        | <a href="https://openaitx.github.io/view.html?user=phase1geo&project=Annotator&lang=pt">Português</a>
        | <a href="https://openaitx.github.io/view.html?user=phase1geo&project=Annotator&lang=nl">Nederlands</a>
        | <a href="https://openaitx.github.io/view.html?user=phase1geo&project=Annotator&lang=pl">Polski</a>
        | <a href="https://openaitx.github.io/view.html?user=phase1geo&project=Annotator&lang=ar">العربية</a>
        | <a href="https://openaitx.github.io/view.html?user=phase1geo&project=Annotator&lang=fa">فارسی</a>
        | <a href="https://openaitx.github.io/view.html?user=phase1geo&project=Annotator&lang=tr">Türkçe</a>
        | <a href="https://openaitx.github.io/view.html?user=phase1geo&project=Annotator&lang=vi">Tiếng Việt</a>
        | <a href="https://openaitx.github.io/view.html?user=phase1geo&project=Annotator&lang=id">Bahasa Indonesia</a>
        | <a href="https://openaitx.github.io/view.html?user=phase1geo&project=Annotator&lang=as">অসমীয়া</
      </div>
    </div>
  </details>
</div>

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
- libgranite-7-dev
- libgtk-4-dev
- libxml2-dev
- libarchive-dev
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

To build the elementary Flatpak from source, run `./app elementary`.

To build the Flathub Flatpak from source, run `./app flathub`.

Afterwards, you can run it via: `./app run-flatpak`.

<p align="center">
  <a href="https://appcenter.elementary.io/com.github.phase1geo.annotator">
    <img src="https://appcenter.elementary.io/badge.svg" alt="Get it on AppCenter"/>
  </a>
</p>

## Credits

Incorporates `document-edit-symbolic.svg` and `image-crop-symbolic.svg` from
[elementary/icons](https://github.com/elementary/icons/tree/main/actions/symbolic),
under the terms of the GPL v3.0 license.
