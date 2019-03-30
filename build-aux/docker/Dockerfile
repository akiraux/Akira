FROM docker.io/fedora:30

# Update the system and install what we need to build a flatpak package
RUN dnf update -y 
RUN dnf -y install flatpak \ 
                   flatpak-builder

# Add Flathub remote and install the latest GNOME SDk
RUN flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo 
RUN flatpak install flathub org.gnome.Sdk//3.32 -y
RUN flatpak update -y 