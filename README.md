# ![Akira](akira-logo-transparent.png)
> The Linux Design Tool

**WARNING!!! AKIRA IS CURRENTLY IN PRE-ALPHA, NOT READY FOR PRODUCTION. USE IT AT YOUR OWN RISK!**

Akira is a native Linux Design application built in Vala and GTK. Akira focuses on offering a modern and fast approach to UI and UX Design, mainly targeting web designers and graphic designers.
The main goal is to offer a valid and professional solution for designers who want to use Linux as their main OS.

![](akira-screenshot.png)

## Get it from the elementary OS AppCenter!
Akira, is primarly available from the AppCenter for elementary OS. Download it from there!

[![Get it on AppCenter](https://appcenter.elementary.io/badge.svg)](https://appcenter.elementary.io/com.github.alecaddd.akira)

## Install it from source
You can install Akira by compiling it from the source, here's the list of dependecies required:
 - `gtk+-3.0>=3.9.10`
 - `granite>=0.5.0`
 - `glib-2.0`
 - `gee-0.8`
 - `gobject-2.0`
 - `libxml-2.0`
 - `gtksourceview-3.0`
 
**For non-elementary distros, (Arch, Debian etc) you are required "vala" as additional dependency.**

## Building
```
mkdir build/ && cd build
cmake -DCMAKE_INSTALL_PREFIX=/usr ../
make && sudo make install
```

### Donations
If you like Akira and you want to support its development, consider donating via [PayPal](https://www.paypal.me/alecaddd) or pledge on [Patreon](https://www.patreon.com/alecaddd).
