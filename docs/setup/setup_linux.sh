SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/../.."

haxelib --global install hxpkg
echo ""

while true; do
    echo "Available Profiles:"
    echo "    [1] Default"
    echo "    [2] Default + Video"
    echo "    [3] Default + Android"
    echo "    [4] Full Install"
    echo ""
    read -rp "Select profile [1-4]: " i0

    case "$i0" in
        1) profile=""; break ;;
        2) profile="video"; break ;;
        3) profile="android"; break ;;
        4) profile="video android"; break ;;
        *)
            echo "Invalid selection"
            echo ""
            ;;
    esac
done
echo ""

while true; do
    read -rp "Would you like to install these libraries globally (might interfere with other mods) [y/n]: " i1
    case "$i1" in
        [Yy]) global="--global"; break ;;
        [Nn]) global=""; break ;;
        *)
            echo "Invalid selection"
            echo ""
            ;;
    esac
done

haxelib --global run hxpkg install --force $global $profile
echo ""

case "$OSTYPE" in
    darwin*)  TARGET="mac" ;;
    *)        TARGET="linux" ;;
esac

while true; do
    read -p "All versions set!! Would you like to build the game now [y/n] ? " i3
    case $i3 in
        [Yy] ) haxelib run lime test $TARGET; break;;
        [Nn] ) quit;;
    esac
done