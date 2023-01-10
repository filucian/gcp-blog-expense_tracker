initializeEnvt() {
	source parameters-deploy.sh

	if [ -z "$DOMAIN_NAME" ] || [ -z "$PROJECT_ID" ] || [ -z "$APP_NAME" ]; then
		if [ -z "$DOMAIN_NAME" ]; then
			printerror "Domain Name not provided"
		fi
		if [ -z "$PROJECT_ID" ]; then
			printerror "Project id not provided"
		fi
		if [ -z "$APP_NAME" ]; then
			printerror "Project id not provided"
		fi
		exit
	fi

	# set environment variables
	source deployment-script-vars.sh

	check_CLI_commands
}

printerror() {
	# Set font color to red
	tput setaf 1

	printf "$1\n"

	tput sgr0
}

printsuccess() {
	# Set font color to red
	tput setaf 2

	printf "$1\n"

	tput sgr0
}

printinfo() {
	# Set font color to red
	tput sgr0

	printf "$1\n"

	tput sgr0
}

check_CLI_commands() {

	printf "\nChecking tools\n"
	if command -v gcloud >/dev/null; then
		printsuccess "gcloud is installed"
	else
		printerror "gcloud is not installed "
		exit
	fi

	if command -v yarn >/dev/null; then
		printsuccess "yarn is installed"
	else
		printerror "yarn is not installed"
		exit
	fi

	if command -v git >/dev/null; then
		printsuccess "git is installed"
	else
		printerror "git is not installed"
		exit
	fi

	if command -v terraform >/dev/null; then
		printsuccess "terraform is installed"
	else
		printerror "terraform is not installed"
		exit
	fi

	echo ""
}

check_Frontend() {
	if test -d "../$frontend_name"; then
		printinfo "Vite App found. Reinstalling node dependencies."
	else
		printerror "No app found."
		printinfo "Installing Vite app."
		cd ..
		yarn create vite "$frontend_name" --template react-ts
	fi
}

enable_APIs() {
	printinfo "\nEnabling Services"
	local BILLING_ACCOUNT_ID=$(gcloud alpha billing accounts list \
		--format json |
		jq '.[0].name' |
		cut -d "/" -f 2 |
		cut -d "\"" -f 1)

	gcloud services enable \
		cloudbilling.googleapis.com

	gcloud alpha billing projects link "$PROJECT_ID" \
		--billing-account="$BILLING_ACCOUNT_ID" 1>/dev/null

	gcloud services enable \
		compute.googleapis.com

	gcloud services enable \
		dns.googleapis.com
}
