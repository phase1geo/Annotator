#!/usr/bin/env bash

arg=$1

function initialize {
    meson setup build --prefix=/usr
    result=$?

    if [ $result -gt 0 ]; then
        echo "Unable to initialize, please review log"
        exit 1
    fi

    cd build

    ninja

    result=$?

    if [ $result -gt 0 ]; then
        echo "Unable to build project, please review log"
        exit 2
    fi
}

function test {
    initialize 0

    export DISPLAY=:0
    ./com.github.phase1geo.annotator --run-tests
    result=$?

    export DISPLAY=":0.0"

    echo ""
    if [ $result -gt 0 ]; then
        echo "Failed testing"
        exit 100
    fi

    echo "Tests passed!"
}

case $1 in
"clean")
    sudo rm -rf ./build
    ;;
"generate-i18n")
    grep -rc _\( * | grep ^src | grep -v :0 | cut -d : -f 1 | sort -o po/POTFILES
    echo "data/com.github.phase1geo.annotator.shortcuts.ui" >> po/POTFILES
    initialize 0
    ninja com.github.phase1geo.annotator-pot
    ninja com.github.phase1geo.annotator-update-po
    ninja extra-pot
    ninja extra-update-po
    cp data/* ../data
    ;;
"install")
    initialize 0
    sudo ninja install
    ;;
"install-deps")
    output=$((dpkg-checkbuilddeps ) 2>&1)
    result=$?

    if [ $result -eq 0 ]; then
        echo "All dependencies are installed"
        exit 0
    fi

    replace="sudo apt install"
    pattern="(\([>=<0-9. ]+\))+"
    sudo_replace=${output/dpkg-checkbuilddeps: error: Unmet build dependencies:/$replace}
    command=$(sed -r -e "s/$pattern//g" <<< "$sudo_replace")
    
    $command
    ;;
"emmet-true")
    cd build
    meson configure -Demmet=true
    ;;
"emmet-false")
    cd build
    meson configure -Demmet=false
    ;;
"run")
    initialize 0
    GDK_BACKEND=x11 ./com.github.phase1geo.annotator "${@:2}"
    ;;
"run-emmet")
    initialize 1
    ./com.github.phase1geo.annotator "${@:2}"
    ;;
"debug")
    initialize 0
    G_DEBUG=fatal-criticals GDK_BACKEND=x11 gdb --args ./com.github.phase1geo.annotator "${@:2}"
    ;;
"test")
    test
    ;;
"test-run")
    test
    GDK_BACKEND=x11 ./com.github.phase1geo.annotator "${@:2}"
    ;;
"uninstall")
    initialize 0
    sudo ninja uninstall
    ;;
"flatpak")
    sudo flatpak-builder --install --force-clean ../build-annotator com.github.phase1geo.annotator.yml
    ;;
*)
    echo "Usage:"
    echo "  ./app [OPTION]"
    echo ""
    echo "Options:"
    echo "  clean             Removes build directories (can require sudo)"
    echo "  generate-i18n     Generates .pot and .po files for i18n (multi-language support)"
    echo "  emmet-<bool>      Sets the Emmet build mode to true or false"
    echo "  install           Builds and installs application to the system (requires sudo)"
    echo "  install-deps      Installs missing build dependencies"
    echo "  run               Builds and runs the application (must run install once before successive calls to this command)"
    echo "  test              Builds and runs testing for the application"
    echo "  test-run          Builds application, runs testing and if successful application is started"
    echo "  uninstall         Removes the application from the system (requires sudo)"
    echo "  flatpak           Builds and installs the Flatpak version of the application"
    ;;
esac
