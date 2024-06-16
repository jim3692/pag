function isSupported() {
	which yay
}

function install() {
	yay -S $@
}

function upgrade() {
	yay -Sua
}
