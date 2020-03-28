<h1 align="center">
    <br>
    <img src="akira-logo-transparent.png" alt="Akira">
</h1>
<h4 align="center">The Linux Design Tool</h4>
<p align="center">
    <a href="https://github.com/akiraux/Akira/actions"><img src="https://github.com/akiraux/Akira/workflows/CI/badge.svg"
            alt="Build Status"></a>
    <a href="https://liberapay.com/AkiraUX"><img
            src="http://img.shields.io/liberapay/patrons/AkiraUX.svg?logo=liberapay" alt="AkiraUX on Liberapay"></a>
    <a href="https://www.patreon.com/akiraux"><img
            src="https://img.shields.io/badge/patreon-donate-orange.svg?logo=patreon" alt="AkiraUX on Patreon"></a>
</p>
<p align="center">
    <a href="#-install">Install</a> •
    <a href="#-compile">Compile</a> •
    <a href="#-questions-issues">Questions</a> •
    <a href="#-contributing">Contributing</a> •
    <a href="#-support">Support</a> •
    <a href="#-mascot">Mascot</a> •
    <a href="#-license">License</a>
</p>

![screenshot](akira-screenshot.png)

Akira is a native Linux Design application built in Vala and GTK. Akira focuses on offering a modern and fast approach to UI and UX Design, mainly targeting web designers and graphic designers. The main goal is to offer a valid and professional solution for designers who want to use Linux as their main OS.

**AKIRA IS CURRENTLY IN EARLY DEVELOPMENT, NOT READY TO BE USED!**

## 📦 Install

| elementaryOS AppCenter 	| FlatHub       	| Snapcraft Store 	|
|------------------------	|---------------	|-----------------	|
| Coming Soon!          	| Coming Soon! 	    | Coming Soon!   	|

## 🛠 Compile

You can install Akira by compiling it from the source

### Install Dependencies

 - `gtk+-3.0>=3.18`
 - `granite>=5.3.0`
 - `glib-2.0`
 - `gee-0.8`
 - `gobject-2.0`
 - `libxml-2.0`
 - `gtksourceview-3.0`
 - `libjson-glib-1.0`
 - `goocanvas-2.0`
 - `libarchive`
 - `gettext`
 - `cairo`
 - `meson`

> _**Note:** For non-elementary distros, (such as Arch, Debian etc) you are required to install "vala" as additional dependency._

### Compile &amp; Run

Once the above mentioned dependencies are resolved, Akira can be compiled &amp; installed

```sh
meson build --prefix=/usr -Dprofile=default
cd build
ninja && sudo ninja install
```

> _**Note:** Replace the `-Dprofile=default` with `-Dprofile=development` to compile and install Akira in **development** mode where you can make changes._

## 🤔 Questions &amp; Issues

If you want to ask any questions about the project, we have a dedicated Discord channel available to any [Patreon](https://www.patreon.com/akiraux) supporters. If you are trying out Akira and you encounter an error or any problem feel free to just open an issue.

## 👨‍💻 Contributing

Feel free to send a pull request to this repository with your code contributions, but first read our [contributing guidelines](CONTRIBUTING.md) :page_with_curl:

## 📌 Code of Conduct

This project adheres to the adapted version of Contributor Covenant [code of conduct](.github/CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

## 🎉 Support

If you like Akira and you want to support its development, consider donating via [Liberapay](https://liberapay.com/AkiraUX/) or pledge on [Patreon](https://www.patreon.com/akiraux).

## ✨ Mascot

![](https://raw.githubusercontent.com/akiraux/assets/master/mascot/akira-mascot-akari.png)

**Akari the Cyber Phoenix** is a perfectionist. She is tidy, collected and has a sharp eye for detail. Her name Akari (灯理、) means *"the enlightenment of a sophisticated order"*. Her costume resembles the project's icon. Get the Mascot and all the other assets from [here](https://github.com/akiraux/assets).

Mascot character designed by **Tyson Tan**.
Tyson Tan offers mascot design service for free and open source software, free of charge, under free license.
Contact: [http://tysontan.com](http://tysontan.com)  / [tysontan@mail.com](mailto:tysontan@mail.com)

## 📜 License
#### [GNU GPLv3 / Creative Commons BY-SA](./COPYING)

Copyright © 2019 Akira Project.
