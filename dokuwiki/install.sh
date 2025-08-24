#!/bin/bash

# default values
INSTALL_DIR="www"
DATA_DIR=""
CONFIRM_DELETE=false
USE_REWRITE=false
CLEANUP=false
CLIENT_IP=$(echo $SSH_CLIENT | awk '{print $1}')

# function for display help
help_message() {
    echo "Usage:"
    echo ""
    echo " $0 [-h] [-y] [-i installation_path] [-d [data_path]] [-s sneaky_url]"
    echo "   -i   set installation directory (default: www)"
    echo "   -d   change data directory (default: data – optional)"
    echo "   -y   automatically confirm deletion of existing files (optional)"
    echo "   -r   aktivate \"userewrite\" in .htaccess"
    echo "   -h   show this help message"
}

# show CLIENT_IP
echo "Your IP is: $CLIENT_IP"

# parse option
if [ $# -eq 0 ];
then
   DATA_DIR="";
else
    while getopts "i:dychr?" opt; do
        case $opt in
        i) INSTALL_DIR="$OPTARG" ;;
        d)  if [[ ${!OPTIND} && ! ${!OPTIND} =~ ^- ]]; then
                DATA_DIR="${!OPTIND}"
                OPTIND=$((OPTIND + 1))
            else
                DATA_DIR="data"
            fi;;
        y) CONFIRM_DELETE=true ;;
        c) CLEANUP=true ;;
        r) USE_REWRITE=true ;;
        :) help_message; exit 1;;
        ? | h ) help_message; exit 1 ;;
      esac
   done
fi

# delete existing files in install dir if confirmed
if [ -d "$INSTALL_DIR" ]; then
    if $CONFIRM_DELETE; then
        echo "Existing installation directory '$INSTALL_DIR' will be emptied."
    else
        read -p "Installation directory '$INSTALL_DIR' exists. Delete contents? (y/N): " answer
        if [[ ! "$answer" =~ ^[Yy]$ ]]; then
            echo "Installation aborted."
            exit 1
        fi
    fi
    rm -rf "$INSTALL_DIR"
fi
mkdir -p "$INSTALL_DIR"
echo "Installation directory '$INSTALL_DIR' is empty."

# .htaccess erzeugen
echo "Allow access to $INSTALL_DIR only from $CLIENT_IP."
cat > "$INSTALL_DIR/.htaccess" <<EOF
# Access only from the current IP
Order Deny,Allow
Deny from all
Allow from $CLIENT_IP
EOF

shopt -s dotglob

# Download the latest official DokuWiki
echo "download dokuwiki-stable.tgz"
wget -O dokuwiki.tgz https://download.dokuwiki.org/src/dokuwiki/dokuwiki-stable.tgz

# Unpacking DokuWiki
echo "Unpacking dokuwiki-stable.tgz"
tar xf dokuwiki.tgz
mv dokuwiki-*/* "$INSTALL_DIR"/
rmdir dokuwiki-*
echo "Delete dokuwiki-stable.tgz"
rm -f dokuwiki.tgz

# Create data directory (optional)
if [[ -n "$DATA_DIR" ]]; then
    if [[ -d "$DATA_DIR" ]]; then
        echo "Data directory '$DATA_DIR' exists."
        # Delete the data directory in the installation path
        if [[ -d "$INSTALL_DIR/data" ]]; then
            echo "Delete $INSTALL_DIR/data because $DATA_DIR exists."
            rm -rf "$INSTALL_DIR/data"
        fi
    else
        mkdir -p "$DATA_DIR"
        echo "Data directory “$DATA_DIR” created."
        # Move content from the Dokuwiki Data directory
        if [[ -d "$INSTALL_DIR/data" ]]; then
            mv "$INSTALL_DIR/data/"* "$DATA_DIR/"
            rmdir "$INSTALL_DIR/data"
        fi
    fi
    REL_PATH=$(realpath --relative-to="$INSTALL_DIR" "$DATA_DIR")
    echo "Relative path to data: $REL_PATH"
    printf "\$conf['savedir'] = '%s';\n" "$REL_PATH" >> "$INSTALL_DIR/conf/local.php"
fi

shopt -u dotglob

echo "===================================================="
echo "Now start the installation in your browser:"
echo "   https://DOMAIN.TLD/install.php"
echo "Press [Enter] once the installation is complete."
echo "===================================================="
read -r

echo "Delete install.php."
rm -f "$INSTALL_DIR/install.php"

echo "Delete installation protection."
rm -f "$INSTALL_DIR/.htaccess"

# setting up htaccess
if [[ -f "$INSTALL_DIR/.htaccess.dist" ]]; then
    cp "$INSTALL_DIR/.htaccess.dist" "$INSTALL_DIR/.htaccess"
    echo "Standard .htaccess copied."
    # enable RewriteRules when -r is set
    if [[ -n "$USE_REWRITE" ]]; then
        sed -i '/^#RewriteEngine on/,/^##/ s/^#//' "$INSTALL_DIR/.htaccess"
        printf "\$conf['userewrite'] = 1;" >> "$INSTALL_DIR/conf/local.php"
        echo "RewriteRules enabled."
    fi
else
    echo ".htaccess.dist not found - RewriteRules not enabled."
fi

echo "Delete myself."

rm -- "$0"

echo "Completed!"
