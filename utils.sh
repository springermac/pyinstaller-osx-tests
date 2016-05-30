#!/usr/bin/env bash
# Use with ``source utils.sh``

function install_port {
    PORT=$1
    sudo port -qb install $PORT
    if [ $? -ne 0 ]; then
        sudo port -qp install $PORT
    fi
}

function install_dependencies {
    if [ $DEPENDENCIES = macports ]; then
        travis_fold start dependencies_macports
        install_port py$PYTHON_VERSION-crypto
        install_port py$PYTHON_VERSION-boto
        install_port py$PYTHON_VERSION-boto3
        install_port py$PYTHON_VERSION-pygments
        install_port py$PYTHON_VERSION-pylint
        install_port py$PYTHON_VERSION-markdown
        install_port py$PYTHON_VERSION-simplejson
        install_port py$PYTHON_VERSION-sphinx
        install_port py$PYTHON_VERSION-sphinx_rtd_theme
        install_port py$PYTHON_VERSION-zmq
        install_port py$PYTHON_VERSION-zopeinterface
        install_port py$PYTHON_VERSION-numpy
        install_port py$PYTHON_VERSION-lxml
        install_port py$PYTHON_VERSION-pycparser
        install_port py$PYTHON_VERSION-tz
        install_port py$PYTHON_VERSION-sqlalchemy
        install_port py$PYTHON_VERSION-Pillow
        install_port py$PYTHON_VERSION-dateutil
        install_port py$PYTHON_VERSION-pandas
        install_port py$PYTHON_VERSION-matplotlib
        # No binary archives for pyqt*, due to license conflict, which causes build too run to long
        #install_port py$PYTHON_VERSION-pyqt4
        #install_port py$PYTHON_VERSION-pyqt5
        #install_port py$PYTHON_VERSION-pyside Runs too long
        install_port py$PYTHON_VERSION-tkinter
        install_port py$PYTHON_VERSION-enchant
        install_port py$PYTHON_VERSION-gevent
        #install_port gstreamer1
        #install_port py$PYTHON_VERSION-gobject3
        travis_fold end dependencies_macports
    fi
    if [ $DEPENDENCIES = homebrew ]; then
        travis_fold start dependencies_homebrew
        if [ $PYTHON_VERSION = 2 ]; then
            brew -v tap homebrew/python
            brew -v install python-markdown
            brew -v install numpy
            brew -v install Pillow
            brew -v install matplotlib
            brew -v install wxpython
            brew -v install enchant --with-python
            brew -v install pyqt
            travis_wait brew -v install pyqt5 --with-python --without-python3
            #travis_wait brew -v install pyside Takes to long
            #brew -v install gst-python
        fi
        if [ $PYTHON_VERSION = 3 ]; then
            brew -v tap homebrew/python
            brew -v install numpy --with-python3 --without-python
            brew -v install Pillow --with-python3 --without-python
            brew -v install matplotlib --with-python3 --without-python
            travis_wait brew -v install pyqt --with-python3 --without-python
            brew -v install pyqt5
            #travis_wait brew -v install pyside --with-python3 --without-python Takes to long
            #brew -v install pygobject3 --with-python3 --without-python
        fi
        travis_fold end dependencies_homebrew
    fi
    toggle_py_sys_site_packages
    export ACCEL_CMD=`dirname $PIP_CMD`/pip-accel
    travis_fold start dependencies_pip
    ${ACCEL_CMD} install -r $TRAVIS_BUILD_DIR/$REPO_DIR/tests/requirements-mac.txt | cat
    travis_fold end dependencies_pip
}

function prep_cache {
    df -h
    if [ $SOURCE = macports ]; then
        sudo rm -rf $HOME/macports_cache
        mkdir $HOME/macports_cache
        sudo port clean --work --logs --archive installed
        if [ -d "/opt/local/var/macports/software" ]; then
            sudo mkdir $HOME/macports_cache/software
            sudo mv /opt/local/var/macports/software $HOME/macports_cache/software
            #sudo mv /opt/local/var/macports/incoming $HOME/macports_cache/incoming
        fi
    fi
    if [ $SOURCE = homebrew ]; then
        brew cleanup -s
    fi
    df -h
}
