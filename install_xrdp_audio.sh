function install_xrdp_pa() {
        apt-get install -y git libpulse-dev autoconf m4 intltool build-essential dpkg-dev libtool libsndfile1-dev libspeexdsp-dev libudev-dev pulseaudio
        cp /etc/apt/sources.list /etc/apt/sources.list.u2ad
        sed -Ei 's/^# deb-src /deb-src /' /etc/apt/sources.list
        apt-get update -y
        apt build-dep pulseaudio -y
        cd /tmp
        apt source pulseaudio
        pulsever=$(pulseaudio --version | awk '{print $2}')
        cd /tmp/pulseaudio-$pulsever
        # ./configure --without-caps
        ./configure
        git clone https://github.com/neutrinolabs/pulseaudio-module-xrdp.git
        cd pulseaudio-module-xrdp
        ./bootstrap
        ./configure PULSE_DIR="/tmp/pulseaudio-$pulsever"
        make
        cd /tmp/pulseaudio-$pulsever/pulseaudio-module-xrdp/src/.libs
        install -t "/var/lib/xrdp-pulseaudio-installer" -D -m 644 *.so
        # systemctl restart dbus
        # systemctl restart pulseaudio
        systemctl restart xrdp
        # fix PulseAudio no sound issue at Ubuntu 20.04
        # Issue: https://github.com/neutrinolabs/pulseaudio-module-xrdp/issues/44
        fix_pa_systemd_issue
}

# Fix PA no sound issue in Ubuntu 20.04.
# Issue: https://github.com/neutrinolabs/pulseaudio-module-xrdp/issues/44
function fix_pa_systemd_issue() {
mkdir -p /home/covid19/.config/systemd/user/
ln -s /dev/null /home/covid19/.config/systemd/user/pulseaudio.service
mkdir -p /home/covid19/.config/autostart/
cat <<EOF | \
  sudo tee /home/covid19/.config/autostart/pulseaudio.desktop
[Desktop Entry]
Type=Application
Exec=pulseaudio
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name[en_US]=pulseaudio
Name=pulseaudio
Comment[en_US]=pulseaudio
Comment=pulseaudio
EOF
chown -R covid19 /home/covid19/.config/
chmod -R 755 /home/covid19/.config/
}

# create a new desktop user
function create_desktop_user() {
useradd -s /bin/bash -m covid19
usermod -a -G sudo covid19
echo "covid19 ALL=(ALL) ALL" >> /etc/sudoers
echo "1212
1212
" | passwd covid19
}


create_desktop_user

install_xrdp_pa

echo "Install Done!"
echo "Now you can reboot and connect port 3389 with rdp client"
echo "Default xRDP Username: covid19"
echo "Default xRDP User's Password: 1212"

