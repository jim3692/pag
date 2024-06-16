# Package AGgregator

An extensible wrapper around multiple package managers

# Installation

`git clone https://github.com/jim3692/pag.git`

# Usage

```
./pag [options...] <package>
 i, install <package>  Install a package
 u, upgrade            Upgrade all packages
 h, help               Print this help message

The <package> parameter should be <provider name>/<package name>
Example: arch/neofetch

Natively supported providers: arch, aur, nix
```

# Configuration

### Adding a Custom Provider

- Navigate to `~/.config/pag/providers`
- Create a `<custom provider name>.sh` bash script, ex. `apt.sh`
- The syntax of the file should be the following:
  ```bash
  function isSupported() {
    # Script that checks if the provider is supported by the system
    # This function should return an error code, if the provider is not supported
    # Example: `which apt`
  }

  function install() {
    # Script for installing packages
    # This function gets a list of packages in `$@`
    # Example: `sudo apt install $@`
  }

  function upgrade() {
    # Script for upgrading all packages
    # Example: `sudo apt update && sudo apt upgrade`
  }
  ```
- You can now install packages using your custom provider by running `./pag i <custom provider name>/<package name>`, ex. `./pag i apt/neofetch`.
  Your custom provider will also run its `upgrade` function on `./pag u`.

#### Useful `lib` Utilities for Providers

- For providers that cannot natively track their installed packages for easy updates. Check `providers/nix.sh` as a reference.
  - `lib.currentProvider.registerPackages`: Store the packages passed to it, as parameters, to the internal pag's registry
  - `lib.currentProvider.getInstalledPackages`: Return the list of packages from the pag's internal provider's registry
