#!/usr/bin/env bash
# Use with ``source utils.sh``

function install_dependencies {
    if [ $DEPENDENCIES = macports ]; then
        travis_fold start "dependencies macports"
        sudo port -qp activate py$PYTHON_VERSION-crypto
        sudo port -qp activate py$PYTHON_VERSION-boto
        sudo port -qp activate py$PYTHON_VERSION-boto3
        sudo port -qp activate py$PYTHON_VERSION-pygments
        sudo port -qp activate py$PYTHON_VERSION-pylint
        sudo port -qp activate py$PYTHON_VERSION-markdown
        sudo port -qp activate py$PYTHON_VERSION-simplejson
        sudo port -qp activate py$PYTHON_VERSION-sphinx
        sudo port -qp activate py$PYTHON_VERSION-sphinx_rtd_theme
        sudo port -qp activate py$PYTHON_VERSION-zmq
        sudo port -qp activate py$PYTHON_VERSION-zopeinterface
        sudo port -qp activate py$PYTHON_VERSION-numpy
        sudo port -qp activate py$PYTHON_VERSION-lxml
        sudo port -qp activate py$PYTHON_VERSION-pycparser
        sudo port -qp activate py$PYTHON_VERSION-tz
        sudo port -qp activate py$PYTHON_VERSION-sqlalchemy
        sudo port -qp activate py$PYTHON_VERSION-Pillow
        sudo port -qp activate py$PYTHON_VERSION-dateutil
        sudo port -qp activate py$PYTHON_VERSION-pandas
        sudo port -qp activate py$PYTHON_VERSION-matplotlib
        # No binary archives for pyqt*, due to license conflict, which causes build too run to long
        #sudo port -qp activate py$PYTHON_VERSION-pyqt4
        #sudo port -qp activate py$PYTHON_VERSION-pyqt5
        #sudo port -qp activate py$PYTHON_VERSION-pyside Runs too long
        sudo port -qp activate py$PYTHON_VERSION-tkinter
        sudo port -qp activate py$PYTHON_VERSION-enchant
        sudo port -qp activate py$PYTHON_VERSION-gevent
        #sudo port -qp activate gstreamer1
        #sudo port -qp activate py$PYTHON_VERSION-gobject3
        travis_fold end "dependencies macports"
    fi
    if [ $DEPENDENCIES = homebrew ]; then
        travis_fold start "dependencies homebrew"
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
        travis_fold end "dependencies homebrew"
    fi
    toggle_py_sys_site_packages
    export ACCEL_CMD=`dirname $PIP_CMD`/pip-accel
    travis_fold start "dependencies pip"
    ${ACCEL_CMD} install -r $TRAVIS_BUILD_DIR/$REPO_DIR/tests/requirements-mac.txt | cat
    travis_fold end "dependencies pip"
}

function prep_cache {
    df -h
    if [ $SOURCE = macports ]; then
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
