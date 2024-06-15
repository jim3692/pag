function isSupported() {
	which nix-channel
	which nix-env
}

function install() {
	nix-env -iA $@
	lib.currentProvider.registerPackages $@
}

function upgrade() {
	nix-channel --update
	nix-env -iA $(lib.currentProvider.getInstalledPackages)
}
