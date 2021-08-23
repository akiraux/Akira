# Contributing to Akira

:tada: First off, thank you for considering contributing to Akira :tada:

Akira is an open source project and we love to receive contributions from our community — you! There are many ways to contribute, from submitting bug reports and feature requests or writing code which can be incorporated into Akira itself.

All members of our community are expected to follow our [Code of Conduct](.github/CODE_OF_CONDUCT.md). Please make sure you are welcoming and friendly in all of our spaces.

The following is a set of guidelines for contributing to Akira, which is hosted in the [Akira UX Organization](https://github.com/akiraux) on GitHub.
Following these guidelines helps to communicate that you respect the time of the developers managing and developing this open source project. In return, they should reciprocate that respect in addressing your issue, assessing changes, and helping you finalize your pull requests.

These are mostly guidelines, not rules. Use your best judgment, and feel free to propose changes to this document in a pull request.

## Table of contents

* [Getting started](#getting-started)
* [Reporting bugs and issues](#reporting-bugs-and-issues)
* [Feature requests](#feature-requests)
* [Your first contributions](#your-first-contribution)
* [Pull requests](#pull-requests)
* [Code review process](#code-review-process)

## Getting started

* Akira is written in [Vala language](https://wiki.gnome.org/Projects/Vala).

* To start learning how to program in Vala, check out the [official tutorial](https://wiki.gnome.org/Projects/Vala/Tutorial)

* To follow up on general questions about development in GTK, head over to [Gnome Wiki](https://wiki.gnome.org/Newcomers/)

* Akira's main source repository is at [Github](https://github.com/akiraux/Akira).

* Development happens in the `master` branch, thus all Pull Request should be opened against the `master` branch.

* Installing

    You can install Akira by compiling it from the source

    1. Install required dependencies:

        * `gtk4>=4.0`
        * `granite>=6.0.0`
        * `glib-2.0`
        * `gee-0.8`
        * `gobject-2.0`
        * `libxml-2.0`
        * `cairo`
        * `meson`

        > For non-elementary distros, (such as Arch, Debian etc) you are required to install "vala" as additional dependency.

    * Debian (Elementary/Ubuntu/Linux Mint)

        ```sh
        sudo apt-get install libgtk-4-dev elementary-sdk glib-2.0 gee-0.8 gobject-2.0 libxml2 libjson-glib-1.0  libarchive-dev libcairo2-dev meson valac
        ```

    2. Building:
        ```
        meson build --prefix=/usr -Dprofile=default|development
        cd build
        ninja && sudo ninja install
        ```

## Reporting bugs and issues

### Security vulnerability

**If you find a security vulnerability, do NOT open an issue. Email _castellani.ale@gmail.com_ instead.**

In order to determine whether you are dealing with a security issue, ask yourself these two questions:

* Can I access something that's not mine, or something I shouldn't have access to?
* Can I disable something for other people?
If the answer to either of those two questions are "yes", then you're probably dealing with a security issue. Note that even if you answer "no" to both questions, you may still be dealing with a security issue, so if you're unsure, just email us at _castellani.ale@gmail.com_.

### Bugs/Issues

If you think you have found a bug in Akira, first make sure that you are testing against the latest version of Akira (latest commit on `master` branch) - your issue may already have been fixed. If not, search our [issues list](https://github.com/akiraux/Akira/issues) on GitHub in case a similar issue has already been opened.

If the issue has not been reported before, simply create [a new issue](https://github.com/akiraux/Akira/issues/new) via the [**Issues** section](https://github.com/akiraux/Akira/issues)

It is very helpful if you can prepare a reproduction of the bug. In other words, provide all the steps as well as a GIF demonstrating the bug. It makes it easier to find the problem and to fix it.

Please adhere to the issue template and make sure you have provided as much information as possible. This helps the maintainers in resolving these issues considerably.

> **Please be careful** of publishing sensitive information you don't want other people to see, or images whose copyright does not allow redistribution; the bug tracker is a public resource and attachments are visible to everyone.

## Feature requests

If you find yourself wishing for a feature that doesn't exist in Akira, you are probably not alone. There are bound to be others out there with similar needs. Many of the features that Akira has today have been added because our users saw the need.

To request a feature, open an issue on our [issues list](https://github.com/akiraux/Akira/issues) on GitHub which describes the feature you would like to see, why you need it, and how it should work.

> Akira is maintained by a small team of individuals, who aim to provide good support as much as possible.

## Your first contribution

Unsure where to begin contributing to Akira? You can start by looking through the help-wanted issues:
 * [Help wanted issues](https://github.com/akiraux/Akira/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22) - issues which the team has marked for some help.

> Working on your first Pull Request? You can learn how from this [link](https://www.firsttimersonly.com/).

At this point, you're ready to make your changes! Feel free to ask for help; everyone is a beginner at first 😸

> If a maintainer asks you to "rebase" your PR, they're saying that a lot of code has changed, and that you need to update your branch so it's easier to merge.

## Pull requests

For something that is bigger than a one or two line fix:

1. Create your own fork of the code
1. Create a branch
1. Commit your changes in the new branch
1. If you like the change and think the project could use it:
    * Be sure you have followed the code style for the project.
    * Open a pull request with a good description (including issue number)

## Code review process

The core team looks at Pull Requests on a regular basis and they are dealt with on case by case basis and roadmap in mind.
