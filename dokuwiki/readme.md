## install.sh

This installation script is designed to be run on a shared hosting via SSH. Ensure you have SSH access and sufficient permissions.

```sh
# Step 1: Download the installation script
curl -o install.sh https://raw.githubusercontent.com/InPhyMa/admin-scripts/main/dokuwiki/install.sh

# or
wget https://raw.githubusercontent.com/InPhyMa/admin-scripts/main/dokuwiki/install.sh -O install.sh

# Step 2: Execute the script
bash install.sh [options]

# My preferred options
bash install.sh -y -d -r
```

| Option      | Description                                      |
| ----------- | ------------------------------------------------ |
| `-i <path>` | set installation directory (default: `www`)      |
| `-d [path]` | change data directory (default: data – optional) |
| `-y`        | Automatically confirm deletion of existing files |
| `-r`        | aktivate "userewrite" in .htaccess               |
| `-h`        | Display the help message                         |

**Detailed description of the -d option:** If -d is specified, the default directory "data" is created. If -d is specified with a directory, that directory is used. Without -d, the data directory remains in the installation path.

The following settings are added to config/local.php (depending on the options).

```php
$conf['savedir'] = '../data';
$conf['userewrite'] = 1;
```

### Notes
* If the -y option is specified the installation directory will be deleted before installation. Otherwise, confirmation will be requested.
* While install.sh is running, you will be prompted to open the domain in your browser to complete the installation with install.php. Make sure the domain points to the installation path.
* Security: .htaccess protection is automatically added before installation and removed afterward.
