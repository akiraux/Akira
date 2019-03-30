# Docker + Flatpak  = <3

We use a Docker container to bundle what we need to build a daily version of Akira using Flatpak.
The public repository: https://hub.docker.com/r/akiraux/flatpak

## How to update the docker repository

First of all, change whatever you have to change on the Dockerfile and then run the following

```bash
docker build . -t docker.io/akiraux/flatpak
docker push docker.io/akiraux/flatpak
```
