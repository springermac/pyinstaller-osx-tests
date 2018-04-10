#!/usr/bin/env bash
# Use with ``source utils.sh``

function port_install {
    PORT=$1
    (sudo port -bN install --no-rev-upgrade $PORT || travis_wait sudo port -pN install --no-rev-upgrade $PORT) | cat
}

function install_dependencies {
    if [ $DEPENDENCIES = macports ]; then
        travis_fold start dependencies_macports
        travis_time_start
        port_install py$PYTHON_VERSION-crypto
        port_install py$PYTHON_VERSION-boto
        port_install py$PYTHON_VERSION-boto3
        port_install py$PYTHON_VERSION-pygments
        port_install py$PYTHON_VERSION-pylint
        port_install py$PYTHON_VERSION-markdown
        port_install py$PYTHON_VERSION-simplejson
        port_install py$PYTHON_VERSION-sphinx
        port_install py$PYTHON_VERSION-sphinx_rtd_theme
        port_install py$PYTHON_VERSION-zmq
        port_install py$PYTHON_VERSION-zopeinterface
        port_install py$PYTHON_VERSION-numpy
        port_install py$PYTHON_VERSION-lxml
        port_install py$PYTHON_VERSION-pycparser
        port_install py$PYTHON_VERSION-tz
        port_install py$PYTHON_VERSION-sqlalchemy
        port_install py$PYTHON_VERSION-Pillow
        port_install py$PYTHON_VERSION-dateutil
        port_install py$PYTHON_VERSION-pandas
        port_install py$PYTHON_VERSION-matplotlib
        port_install qt4-mac
#        port_install py$PYTHON_VERSION-pyqt4
        port_install qt5
#        port_install py$PYTHON_VERSION-pyqt5
#        port_install py$PYTHON_VERSION-pyside
        port_install py$PYTHON_VERSION-tkinter
        port_install py$PYTHON_VERSION-enchant
        port_install py$PYTHON_VERSION-gevent
        port_install gstreamer1
        port_install py$PYTHON_VERSION-gobject3
        travis_time_finish
        travis_fold end dependencies_macports
        toggle_py_sys_site_packages
    elif [ $DEPENDENCIES = homebrew ]; then
        travis_fold start dependencies_homebrew
        travis_time_start
        /usr/local/bin/pip uninstall -y numpy || true
        brew cask uninstall oclint
        brew tap homebrew/boneyard
        if [ $PYTHON_VERSION = 2 ]; then
            brew install --build-bottle python-markdown --without-python
            brew install --build-bottle numpy --without-python
            brew install Pillow
#            brew install matplotlib
            brew install wxpython
            brew install --build-bottle enchant --with-python@2
#            brew install qt
            brew install qt5
            travis_wait 30 brew install --build-bottle pyqt5 --without-python
#            brew install pyside
            brew install gst-python --with-python@2 --without-python
        elif [ $PYTHON_VERSION = 3 ]; then
            brew install --build-bottle numpy --without-python@2
            brew install --build-bottle Pillow --without-python
#            brew install --build-bottle matplotlib --with-python3 --without-python
#            brew install qt
            brew install qt5
            travis-pls brew install --build-bottle pyqt5 --without-python@2
#            travis_wait brew install --build-bottle pyside --with-python3 --without-python
            brew install --build-bottle pygobject3
            brew install --build-bottle gst-python
        fi
        travis_time_finish
        travis_fold end dependencies_homebrew
        toggle_py_sys_site_packages
    elif [ $DEPENDENCIES = pip ]; then
        travis_fold start dependencies_pip
        travis_time_start
        ${PIP_CMD} install -r $TRAVIS_BUILD_DIR/$REPO_DIR/tests/requirements-libraries.txt | cat
        travis_time_finish
        travis_fold end dependencies_pip
    fi
}

function register_cache {
    if [ -d "$HOME/macports_cache" ]; then
        sudo port install -N lighttpd | cat
        echo 'server.document-root = "'$HOME'/macports_cache/software/"

server.username  = "_www"
server.groupname = "_www"

server.port = 6227

dir-listing.activate = "enable"

mimetype.assign = (
    ".tbz2"     => "application/x-bzip-compressed-tar",
    ".rmd160"   => "text/binary",

    # make the default mime type application/octet-stream.
    ""          => "application/octet-stream",
)' > $HOME/macports_cache/macports-archives-lighttpd.conf
        /opt/local/sbin/lighttpd -f $HOME/macports_cache/macports-archives-lighttpd.conf
        cp /opt/local/etc/macports/pubkeys.conf ~
        echo "$HOME/macports_cache/local-pubkey.pem" >> ~/pubkeys.conf
        sudo cp ~/pubkeys.conf /opt/local/etc/macports/pubkeys.conf
        cp /opt/local/etc/macports/archive_sites.conf ~
        echo "name  local
urls    http://localhost:6227/" >> ~/archive_sites.conf
        sudo cp ~/archive_sites.conf /opt/local/etc/macports/archive_sites.conf
        sudo sed -i -e "/archive_sites/d" /opt/local/var/macports/sources/rsync.macports.org/macports/release/tarballs/ports/devel/gmp/Portfile
    fi
    if [ -d "$HOME/macports_cache/distfiles" ]; then
        travis_fold start distfiles
        sudo mkdir -p /opt/local/var/macports/distfiles
        sudo rsync -r --remove-source-files $HOME/macports_cache/distfiles /opt/local/var/macports/
        travis_fold end distfiles
    fi
}

function prep_cache {
    df -h
    if [ $SOURCE = macports ]; then
        if [ ! -a "$HOME/macports_cache/local-pubkey.pem" ]; then
            if [ ! -a "$HOME/macports_cache/local-privkey.pem" ]; then
                openssl genrsa -out $HOME/macports_cache/local-privkey.pem 2048
            fi
            openssl rsa -in $HOME/macports_cache/local-privkey.pem -pubout -out $HOME/macports_cache/local-pubkey.pem
        fi
        sign_archives
        sudo rm -rf $HOME/macports_cache/distfiles
        sudo rm -rf $HOME/macports_cache/software
        sudo mv /opt/local/var/macports/distfiles $HOME/macports_cache/distfiles
        sudo mv /opt/local/var/macports/software $HOME/macports_cache/software
        if [ -d "$HOME/macports_cache/ports" ]; then rm -rf $HOME/macports_cache/ports; fi
    fi
    if [ $SOURCE = homebrew ]; then
        brew cleanup -s
    fi
    df -h
}

function sign_archives {
PRIVKEY="$HOME/macports_cache/local-privkey.pem"
PUBKEY="$HOME/macports_cache//local-pubkey.pem"
SOFTWARE="/opt/local/var/macports/software"

# First, clear out any outdated signatures
for SIGNATURE in "$SOFTWARE"/*/*.rmd160
do
    ARCHIVE_DIR="$(dirname "$SIGNATURE")"
    ARCHIVE="$(basename "$SIGNATURE" .rmd160)"

    if [ "$SIGNATURE" -ot "$ARCHIVE_DIR"/"$ARCHIVE" -o ! -f "$ARCHIVE_DIR"/"$ARCHIVE" ]
    then
        /bin/echo removing outdated signature: "$SIGNATURE"
        sudo /bin/rm -f "$SIGNATURE"
    fi
done

# Now, find every archive that doesn't have a signature
for ARCHIVE in "$SOFTWARE"/*/*.{tbz2,tgz,tar,tbz,tlz,txz,xar,zip,cpgz,cpio}
do
    PORTNAME="$(basename "$(dirname "$ARCHIVE")")"
    ANAME="$(basename "$ARCHIVE")"

    if [ "$ARCHIVE" -nt "$ARCHIVE".rmd160 ]
    then
        /bin/echo -n signing archive: "$ANAME "
        sudo /usr/bin/openssl dgst -ripemd160 -sign "$PRIVKEY" -out "$ARCHIVE".rmd160 "$ARCHIVE"
        sudo /usr/bin/openssl dgst -ripemd160 -verify "$PUBKEY" -signature "$ARCHIVE".rmd160 "$ARCHIVE"
    fi
done
}
