#!/usr/bin/env bash
# Use with ``source utils.sh``

function install_port {
    PORT=$1
    sudo port -vb fetch $PORT | cat
    if [ $? -ne 0 ]; then
        sudo port -vp fetch $PORT | cat
    fi
}

function install_dependencies {
    if [ $DEPENDENCIES = macports ]; then
        travis_fold start dependencies_macports
        travis_time_start
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
        install_port gstreamer1
        install_port py$PYTHON_VERSION-gobject3
        travis_time_finish
        travis_fold end dependencies_macports
    fi
    if [ $DEPENDENCIES = homebrew ]; then
        travis_fold start dependencies_homebrew
        travis_time_start
        if [ $PYTHON_VERSION = 2 ]; then
            brew tap homebrew/python
            brew install python-markdown
            brew install numpy
            brew link --overwrite numpy
            brew install Pillow
            brew install matplotlib
            brew install wxpython
            brew install enchant --with-python
            brew install pyqt
            travis_wait brew install pyqt5 --with-python --without-python3
            #travis_wait brew install pyside Takes to long
            brew install gst-python
        fi
        if [ $PYTHON_VERSION = 3 ]; then
            brew tap homebrew/python
            brew install numpy --with-python3 --without-python
            brew install Pillow --with-python3 --without-python
            brew install matplotlib --with-python3 --without-python
            travis_wait brew install pyqt --with-python3 --without-python
            brew install pyqt5
            #travis_wait brew install pyside --with-python3 --without-python Takes to long
            brew install gst-python --with-python3 --without-python
        fi
        travis_time_finish
        travis_fold end dependencies_homebrew
    fi
    toggle_py_sys_site_packages
    export ACCEL_CMD=`dirname $PIP_CMD`/pip-accel
    travis_fold start dependencies_pip
    travis_time_start
    ${ACCEL_CMD} install -r $TRAVIS_BUILD_DIR/$REPO_DIR/tests/requirements-mac.txt | cat
    travis_time_finish
    travis_fold end dependencies_pip
}

function prep_cache {
    df -h
    if [ $SOURCE = macports ]; then
#        ls -R /opt/local/var/macports
        sudo rm -rf $HOME/macports_cache
        sudo rm -rf /opt/local/var/macports/software/software
        mkdir $HOME/macports_cache
        #sudo port clean --work --logs --archive installed
        if [ -d "/opt/local/var/macports/software" ]; then
            sudo mv /opt/local/var/macports/software $HOME/macports_cache
            #sudo mv /opt/local/var/macports/incoming $HOME/macports_cache/incoming
        fi
    fi
    if [ $SOURCE = homebrew ]; then
        brew cleanup -s
    fi
    df -h
}
