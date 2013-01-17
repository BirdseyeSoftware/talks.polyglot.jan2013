function create_phantomjs_symlink {
    if command -v phantomjs 2>&1 /dev/null; then
        echo "Found phantomjs, using it..."
        ln -s `command -v phantomjs` phantomjs
    else    
        echo "phantomjs not found, downloading Linux x64 version"
        mkdir -p $VENDOR_DIR
        if [[ ! -d $VENDOR_DIR/phantomjs-1.8.1-linux-x86_64 ]]; then
            pushd .
            cd $VENDOR_DIR
            wget http://phantomjs.googlecode.com/files/phantomjs-1.8.1-linux-x86_64.tar.bz2
            tar xvfj phantomjs-1.8.1-linux-x86_64.tar.bz2
            popd
        fi
        ln -s ../vendor/phantomjs-1.8.1-linux-x86_64/bin/phantomjs phantomjs
    fi
}

npm install
PATH=`pwd`/bin:$PATH
VENDOR_DIR=`pwd`/vendor
ROOT_DIR=`pwd`

cd bin
for F in ../node_modules/buster/bin/buster*; do
    [[ -e $(basename "$F") ]] || ln -s "$F"
done
[[ -e coffee ]] || ln -s ../node_modules/coffee-script/bin/coffee coffee
[[ -e browserify ]] || ln -s ../node_modules/.bin/browserify
[[ -e phantomjs ]] || create_phantomjs_symlink

cd $ROOT_DIR
## 
bundle install --binstubs=bin
