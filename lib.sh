function lib.groupByProvider() {
	local packageLists="$(lib.mkTempDir)"

	for pkg in $@; do
		lib.validatePackage $pkg
		providerName=$(lib.getProviderOfPackage $pkg)
		packageName=$(lib.getNameOfPackage $pkg)
		echo $packageName >> "${packageLists}/$providerName"
	done

	echo $packageLists
}

function lib.validatePackage() {
	if ! echo $1 | grep '/' >/dev/null; then
		echo "Unexpected package '$1'" >/dev/stderr
		lib.fail
	fi
}

function lib.getProviderOfPackage() {
	echo "$1" | tr '/' ' ' | awk '{ print $1 }'
}

function lib.getNameOfPackage() {
	echo "$1" | tr '/' ' ' | awk '{ print $2 }'
}

function lib.getAllProviders() {
	find $GLOBAL_STD_PROVIDERS_ROOT -mindepth 1 -maxdepth 1
	find $GLOBAL_USER_PROVIDERS_ROOT -mindepth 1 -maxdepth 1
}

function lib.resolveProvider() {
	if (echo $1 | grep -E '^/' >/dev/null) && [ -f "$1" ]; then
		echo $1
		return
	fi

	if [ -f "$GLOBAL_STD_PROVIDERS_ROOT/$1.sh" ]; then
		echo "$GLOBAL_STD_PROVIDERS_ROOT/$1.sh"
		return
	fi

	if [ -f "$GLOBAL_USER_PROVIDERS_ROOT/$1.sh" ]; then
		echo "$GLOBAL_USER_PROVIDERS_ROOT/$1.sh"
		return
	fi

	echo "Provider '$1' not found!" >/dev/stderr
	lib.fail
}

function lib.importProvider() {
	local providerPath="$(lib.resolveProvider $1)"

	source "$providerPath"

	if ! isSupported 2>&1 >/dev/null; then
		[ "$IMPORT_OR_FAIL" -eq 1 ] && lib.exception.providerNotSupported $1
		return 1
	fi

	global_currentProviderName="$(basename $providerPath | sed -E 's/\..*$//g')"
	global_currentProviderPath="$providerPath"
}

function lib.getTempDir() {
	if [[ "$lib_tempDir" = "" ]]; then
		lib_tempDir="$(mktemp -d)"
	fi

	echo $lib_tempDir
}

function lib.mkTempFile() {
	local tempDir=$(lib.getTempDir)
	mktemp -p "$tempDir"
}

function lib.mkTempDir() {
	local tempDir=$(lib.getTempDir)
	mktemp -d -p "$tempDir"
}

function lib.clearTempFiles() {
	local tempDir=$(lib.getTempDir)
	rm -rf "$tempDir"
}

function lib.validateAllProviders() {
	for provider in $(lib.getAllProviders); do
		bash -c "
			set -e
			source $provider
			[[ \$(type -t isSupported) = 'function' ]]
			[[ \$(type -t install) = 'function' ]]
			[[ \$(type -t upgrade) = 'function' ]]
		" || lib.exception.providerInvalid $1
	done
}

function lib.exception() {
	echo $1 >/dev/stderr
	lib.fail
}

function lib.exception.providerInvalid() {
	lib.exception "Provider '$1' is not valid!"
}

function lib.exception.providerNotSupported() {
	lib.exception "Provider '$1' is not supported by your system!"
}

function lib.currentProvider.registerPackages() {
	[ -f "$GLOBAL_REGISTRIES_ROOT/$global_currentProviderName" ] || touch "$GLOBAL_REGISTRIES_ROOT/$global_currentProviderName"

	local packagesFile="$(lib.mkTempFile)"

	(
		cat "$GLOBAL_REGISTRIES_ROOT/$global_currentProviderName"
		echo # In case the registry does not contain a trailing new line
		for pkgName in $@; do echo "$pkgName"; done
	) | awk NF | sort | uniq >"$packagesFile"

	cat "$packagesFile" >"$GLOBAL_REGISTRIES_ROOT/$global_currentProviderName"
}

function lib.currentProvider.getInstalledPackages () {
	[ -f "$GLOBAL_REGISTRIES_ROOT/$global_currentProviderName" ] && cat "$GLOBAL_REGISTRIES_ROOT/$global_currentProviderName"
}

function lib.fail() {
	kill -HUP $GLOBAL_MAIN_PID
}
