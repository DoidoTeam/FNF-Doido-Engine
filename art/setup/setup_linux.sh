cd ..
cd ..

haxelib --global install hmm

while true; do
    read -p "Would you like to install these libraries globally (might interfere with other mods) [y/n] ? " i1
    case $i1 in
        [Yy]* ) haxe -cp ./art/setup/deps/ -D analyzer-optimize -main Setup --interp;
                break;;
        [Nn]* ) haxelib --global run hmm init;
                haxelib --global run hmm install;
                break;;
    esac
done

while true; do
    read -p "(OPTIONAL) Install libraries required for video support [y/n] ? " i2
    case $i2 in
        [Yy]* ) haxelib git hxvlc https://github.com/MAJigsaw77/hxvlc 243593311edcc7a8424d73806cda13bd1317bfdd;
                break;;
        [Nn]* ) break;;
    esac
done

while true; do
    read -p "All versions set!! Would you like to build the game now [y/n] ? " i3
    case $i3 in
        [Yy]* ) haxelib run lime test linux;
                break;;
        [Nn]* ) quit;;
    esac
done