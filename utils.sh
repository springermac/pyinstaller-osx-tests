#!/usr/bin/env bash
# Use with ``source utils.sh``

function port_install {
    PORT=$1
    sudo port -vb install $PORT | cat
#    if [ $? -ne 0 ]; then
#        sudo port -vp install $PORT | cat
#    fi
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
        # No binary archives for pyqt*, due to license conflict, which causes build too run to long
        #port_install py$PYTHON_VERSION-pyqt4
        #port_install py$PYTHON_VERSION-pyqt5
        #port_install py$PYTHON_VERSION-pyside Runs too long
        port_install py$PYTHON_VERSION-tkinter
        port_install py$PYTHON_VERSION-enchant
        port_install py$PYTHON_VERSION-gevent
        port_install gstreamer1
        port_install py$PYTHON_VERSION-gobject3
        travis_time_finish
        travis_fold end dependencies_macports
    fi
    if [ $DEPENDENCIES = homebrew ]; then
        travis_fold start dependencies_homebrew
        travis_time_start
        brew tap homebrew/python
        brew tap homebrew/boneyard
        if [ $PYTHON_VERSION = 2 ]; then
            /usr/local/bin/pip uninstall -y numpy
            brew install --build-bottle python-markdown
            brew install --build-bottle numpy
            brew install --build-bottle Pillow
            brew install --build-bottle matplotlib
            brew install --build-bottle wxpython
            brew install --build-bottle enchant --with-python
            brew install --build-bottle pyqt
            travis_wait brew install --build-bottle pyqt5 --with-python --without-python3
            #travis_wait brew install --build-bottle pyside Takes to long
            brew install --build-bottle gst-python
        fi
        if [ $PYTHON_VERSION = 3 ]; then
            brew install --build-bottle numpy --with-python3 --without-python
            brew install --build-bottle Pillow --with-python3 --without-python
            brew install --build-bottle matplotlib --with-python3 --without-python
            travis_wait brew install --build-bottle pyqt --with-python3 --without-python
            brew install --build-bottle pyqt5
            #travis_wait brew install --build-bottle pyside --with-python3 --without-python Takes to long
            brew install --build-bottle pygobject3 --with-python3 --without-python
            brew install --build-bottle gst-python --with-python3 --without-python
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
#        sudo rm -rf /opt/local/var/macports/software/software
        mkdir $HOME/macports_cache
        #sudo port clean --work --logs --archive installed
        if [ -d "/opt/local/var/macports/software" ]; then
            sudo mv /opt/local/var/macports/distfiles $HOME/macports_cache/distfiles
            sudo mv /opt/local/var/macports/incoming $HOME/macports_cache/incoming
        fi
    fi
    if [ $SOURCE = homebrew ]; then
        brew cleanup -s
    fi
    df -h
}
