function isSupported() {
	which pacman
}

function install() {
	sudo pacman -S $@
}

function upgrade() {
	sudo pacman -Syu
}
