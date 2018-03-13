    sudo dpkg --get-selections | sed "s/.*deinstall//" | sed "s/install$//g" > ~/pkglist
    sudo apt-key add pgp-pub-key
    sudo apt update && cat pkglist.txt | xargs sudo apt install -y
