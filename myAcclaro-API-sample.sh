#!/bin/bash

### "Global" variables to work with
SCRIPT=$( basename "$0" )
VERSION="0.4-beta"
consoleActivated=false #sets the console mode off by default

##################
# Core Functions #
##################

### Basic Log
logFile=/tmp/myAcclaro.log
if [[ ! -e /tmp/myAcclaro.log ]]; then
    touch /tmp/myAcclaro.log
fi

### Allow History
if [[ ! -e /tmp/myAcclaroConsole.history ]]; then
    touch /tmp/myAcclaroConsole.history
fi
history -r /tmp/myAcclaroConsole.history
history -w /tmp/myAcclaroConsole.history


# Checks that dependencies are installed
function checkToolsInstalled()
{
	tools=("curl" "jq")
	for tool in ${tools[@]}
	do
		output=$(${tool} --version 2>&1) 
		if [ $? -ne 0 ]; then
			execFailed "[${tool}] is necessary to run this application, exiting."
			handleExit 1
		fi
	done
} #checkCurlInstalled

# Function to handle success messages
function execSuccess()
{
	echo -e "$(date +%F\ %T) :: [\e[92mSUCCESS\e[39m] - $1" | tee -a ${logFile}
} #execSuccess

# Function to handle failed messages
function execFailed()
{
	echo -e "$(date +%F\ %T) :: [\e[31mFAIL\e[39m] - $1" | tee -a ${logFile}
} #execFailed

# Checks that mandatory arguments are sent to function before launching
function checkNotEmpty()
{
	if [[ -z $1 ]]; then
		execFailed "The following mandatory argument [$2] is empty."
		handleExit 1
	fi
} #checkNotEmpty

# Checks if CSV output is requested
function outputCsv()
{
	if [[ "$1" == "-csv" ]]; then
		csvOutput=true
	fi
} #outputCsv

# Handles the exit, if on script it should exit 1 but on console it should just return error
function handleExit()
{
	if [[ "${consoleActivated}" != true ]]; then
		exit $1
	else
		echo $1 >/dev/null #just do something xD
	fi
} #handleExit

# Message to display when wrong usage of scirpt.
function wrongUsage()
{
	local message="$1"
	local txt=(
		"For an overview of the command, execute:"
		"$SCRIPT --help"
	)

	[[ ${message} ]] && printf "${message}\n"

	printf "%s\n" "${txt[@]}"
} #wrongUsage
function wrongUsageConsole()
{
	echo "command '${line[0]}' not found"
} #wrongUsage

# Message to display for version (script).
function version
{
	local txt=(
		"$SCRIPT version $VERSION"
	)

	printf "%s\n" "${txt[@]}"
} #version

# Message to display version (console)
function versionConsole()
{
	echo "MyAcclaro Console ${VERSION}"
} #versionConsole

# Message to display for usage and help (script). 
function usage()
{
	local txt=(
		"Utility ${SCRIPT} for Querying My Acclaro's REST API."
		"Usage: $SCRIPT <base URL> <API key> [options] <arguments>"
		""
		"Command:"
		"--------"
		"	<base URL>	e.g. \"apisandbox.acclaro.com\""
		"	<api Key>	e.g. \"pYXQiOjE2MjYyODYxOTIsInN1YiI6...\""
		""
		"Options:"
		"--------"
		"	--help, -h	Print help."
		"	--version, -v	Print version."
		"	--console, -c	Starts the interactive Console Mode"
		""
		"Parameters"
		"----------"
		"* Orders:"
		"	--create-order, -co <name> [string]	Creates an Order, if \"string\" added as parameter, then the Order takes strings rather than files."
		"	--add-target-lang, -atl <orderID> <targetLang>	Adds a target language to the specified Order."
		"	--add-lang-pair, -alp <orderID> <sourceLang> <targetLang>	Adds a language pair to the specified Order."
		"	--get-order-details, -god <orderID>	Gets the specified Order details."
		"	--get-all-order-details, -gaod <orderID>	Gets all Order details."
		"	--set-order-comment, -soc <orderID> <comment>	Sets a comment for the Order"
		"	--get-order-comments, -goc <orderID>	Gets the Order comments"
		"	--submit-order, -so <orderID>	Submits the Order for preparation and then translation."
		"* Files:"
		"	--send-file, -sf <orderID> <sourceLang> <targertLang> <path_to_file>	Sends a source file for translation."
		"	--send-reference-file, -srf <orderID> <sourceLang> <targertLang> <path_to_reference_file>	Sends a reference file (e.g. a styleguide) for a particular language."
		"	--get-file, -gf <orderID> <fileID>	Gets a file based on its ID."
		"	--get-file-info, -gfi <orderID> <fileID>	Gets the information of a file based on its ID."
		"* Strings:"
		"	--post-string, -ps <orderID> <sourceString> <sourceLang> <targertLang>	Posts a string for translation."
		"	--get-string-info, -gsi <orderID> <stringID>	Gets the string information and the translated string once completed."
		"* Quotes:"
		"	--request-quote, -rq <orderID>	Requests a quote for the Order."
		"	--get-quote-details, -gqd <orderID>	Gets the Quote status and details for the Order."
		"	--quote-decision, -qd <orderID> [--approve,-a/--decline,-d]	Approves/declines the quoted price for the Order."
		""
		"Example:"
		"	$SCRIPT \"apisandbox.acclaro.com\" \"pYXQiOjE2MjYyODYxOTIsInN1YiI6...\" --send-file \"15554\" \"en-us\" \"de-de\" \"./mySourceFile.docx\""
	)
	printf "%s\n" "${txt[@]}"
} #usage

# Message to display for usage and help (console). 
function usageConsole()
{
	local txt=(
		""
		"MyAcclaro Console for Querying MyAcclaro's REST API."
		""
		"System Commands:"
		"	login	Interactive login to MyAcclaro API."
		"	logout	Clears the login information."
		"	exit	Exits the MyAcclaro console"
		"	help	Print help."
		"	version	Print version."
		""
		"Shell commands:"
		"	The following shell commands are available: ls, cd, pwd, grep, find, cat, less"
		"	[CTRL+C] Is captured by this script" 
		""
		"MyAcclaro Commands"
		"* Orders:"
		"	create-order <name> [string]	Creates an Order, if \"string\" added as parameter, then the Order takes strings rather than files."
		"	add-target-lang <orderID> <targetLang>	Adds a target language to the specified Order."
		"	add-lang-pair <orderID> <sourceLang> <targetLang>	Adds a language pair to the specified Order."
		"	get-order-details <orderID>	Gets the specified Order details."
		"	get-all-order-details <orderID>	Gets all Order details."
		"	set-order-comment <orderID> <comment>	Sets a comment for the Order"
		"	get-order-comments <orderID>	Gets the Order comments"
		"	submit-order <orderID>	Submits the Order for preparation and then translation."
		"* Files:"
		"	send-file <orderID> <sourceLang> <targertLang> <path_to_file>	Sends a source file for translation."
		"	send-reference-file <orderID> <sourceLang> <targertLang> <path_to_reference_file>	Sends a reference file (e.g. a styleguide) for a particular language."
		"	get-file <orderID> <fileID>	Gets a file based on its ID."
		"	get-file-info <orderID> <fileID>	Gets the information of a file based on its ID."
		"* Strings:"
		"	post-string <orderID> <sourceString> <sourceLang> <targertLang>	Posts a string for translation."
		"	get-string-info <orderID> <stringID>	Gets the string information and the translated string once completed."
		"* Quotes:"
		"	request-quote <orderID>	Requests a quote for the Order."
		"	get-quote-details <orderID>	Gets the Quote status and details for the Order."
		"	quote-decision <orderID> [--approve,-a/--decline,-d]	Approves/declines the quoted price for the Order."
		""
		""
		"Example:"
		"MyAcclaro@test> send-file 15554 en-us de-de ./mySourceFile.docx"
		""
	)
	printf "%s\n" "${txt[@]}"
} #usageConsole


############
# Console  #
############

# Main console handler, builds the "console echo"
function console()
{
	trap ctrl_c INT #trap control+c and send it to function to handle
	unset line #clean before using, for sanity purposes! :)
	if [[ -z ${baseUrl} || -z ${apiKey} ]]; then
		read -e -p $(echo -e -n "\e[33mMyAcclaro@DISCONNECTED\e[39m>") input
		history -s "${input}"
		eval line=(${input})
	else
		read -e -p $(echo -e -n "\e[92mMyAcclaro@${baseUrl}\e[39m>") input
		history -s "${input}"
		eval line=(${input})
	fi
} #console

function ctrl_c()
{
	printf "\n[CTRL+C] detected - if you need to exit, please type 'exit' (press 'enter' to continue)"
}

# Allows to set the domain and the API key for MyAcclaro API
function logIn()
{
	if [[ -z ${baseUrl} || -z ${apiKey} ]]; then
		echo -e -n "Please enter the MyAcclaro domain: "
		read -e -a domain
		
		echo -e -n "Please paste your API key here: "
		read -e -a key
		response=$(
			curl --location --silent --request GET "https://${domain}/api/v2/info/account" \
			--header "Authorization: Bearer ${key}" \
		)
		if [ $? -eq 0 ] && [[ $(jq -r '.success' <<< ${response}) == true ]]; then
			firstname=$(echo ${response} | jq -r '(.data.firstname)')
			lastname=$(echo ${response} | jq -r '(.data.lastname)')
			execSuccess "Welcome back ${firstname} ${lastname}!"
			baseUrl=${domain}
			apiKey=${key}
		else
			execFailed "the domain or the API key are wrong, please check output"
			echo ${response} | jq
		fi
	else
		echo "you are already logged in into [${baseUrl}] using the following API key:"
		echo "[${apiKey}]"
	fi
} #logIn

# Unsets the domain and the API key for MyAcclaro API
function logOut()
{
	if [[ -z ${baseUrl} || -z ${apiKey} ]]; then
		execFailed "You cannot be logged out because you are not logged in!"
	else
		baseUrl=""
		apiKey=""
		execSuccess "You have been successfully logged out."
	fi
} #logOut

# Creates a greeting screen so it looks cooler
function headerGreeting()
{
	versionConsole
	local txt=(
		""                                             
		"                                   _                  "
		"                     /\           | |                 "
		"  _ __ ___  _   _   /  \   ___ ___| | __ _ _ __ ___   "
		" |  _   _ \| | | | / /\ \ / __/ __| |/ _  | \__/ _ \  "
		" | | | | | | |_| |/ ____ \ (_| (__| | (_| | | | (_) | "
		" |_| |_| |_|\__  /_/    \_\___\___|_|\__ _|_|  \___/  "
		"             __/ |                                    "
		"            |___/                                     "
		""
		""
		"Type 'help' to see the available commands."
		""
	)
	printf "%s\n" "${txt[@]}"
} #headerGreeting

# Provides the command control for console
function consoleMode()
{
	consoleActivated=true
	headerGreeting
	console
	while [ "${line[0]}" != "exit" ]
	do 
		case "${line[0]}" in
		
			ls)
				"${line[@]}"
			;;
			cd)
				"${line[0]}" "${line[1]}"
			;;
			
			pwd)
				"${line[@]}"
			;;
			
			grep)
				"${line[@]}"
			;;
			
			find)
				"${line[@]}"
			;;
			
			cat)
				"${line[@]}"
			;;
			
			less)
				"${line[@]}"
			;;
			
			help)
				usageConsole
			;;
	
			version)
				versionConsole
			;;
		
			create-order)
				createAnOrder "${line[1]}"
			;;
			
			post-sting)
				postString "${line[1]}" "${line[2]}" "${line[3]}" "${line[4]}"
			;;
			
			send-file)
				sendFile "${line[1]}" "${line[2]}" "${line[3]}" "${line[4]}"
			;;		
			
			send-reference-file)
				sendReferenceFile "${line[1]}" "${line[2]}" "${line[3]}" "${line[4]}"
			;;
			
			get-order-details)
				getOrderDetails "${line[1]}"
			;;
			
			get-all-order-details)
				getAllOrderDetails
			;;
			
			submit-order)
				submitOrder "${line[1]}"
			;;
			
			get-string-info)
				getStringInfo "${line[1]}" "${line[2]}"
			;;
			
			get-file)
				getFile "${line[1]}" "${line[2]}"
			;;
			
			get-file-info)
				getFileInfo "${line[1]}" "${line[2]}"
			;;
			
			get-order-comments)
				getComments "${line[1]}" "${line[2]}"
			;;
			
			set-order-comment)
				setComment "${line[1]}" "${line[2]}"
			;;
			
			request-quote)
				requestQuote "${line[1]}"
			;;
			
			get-quote-details)
				getQuoteDetails "${line[1]}"
			;;
			
			quote-decision)
				quoteWorkflow "${line[1]}" "${line[2]}"
			;;
			
			add-target-lang)
				addTargetToOrder "${line[1]}" "${line[2]}"
			;;
			
			add-lang-pair)
				addSourceAndTargetToOrder "${line[1]}" "${line[2]}" "${line[3]}"
			;;
			
			login)
				logIn
			;;
			
			logout)
				logOut
			;;
			
			"")
				#do nothing
			;;
			
			*)
				wrongUsageConsole
			;;
		esac
		console
	done
	exit 0
} #consoleMode


####################
#   API WRAPPING   #
####################

function createAnOrder()
{
	orderName=$1
	string=$2
	if [ "${string}" = "string" ]; then 
		processType="--form process_type=\"string\""
	else
		processType=""
	fi
	checkNotEmpty "${orderName}" "<name>"
	response=$(
		curl --silent --location --request POST "https://${baseUrl}/api/v2/orders" \
		--header 'Content-Type: multipart/form-data' \
		--header "Authorization: Bearer ${apiKey}" \
		--form "name=\"${orderName}\"" \
		${processType} \
	)
	if [ $? -eq 0 ] && [[ $(jq -r '.success' <<< ${response}) == true ]]; then
		#getting the Order ID using bash methods only (python strongly recommended for JSON parsing)
		orderId=$(jq -r '.data.orderid' <<< ${response})
			if [ "${string}" = "string" ]; then 
				execSuccess "Your Order for Strings has been created and has id [${orderId}]" 
			else
				execSuccess "Your Order for Files has been created and has id [${orderId}]" 
			fi
	else
		execFailed "There was a problem while creating your Order, please see the response below:"
		echo ${response} | jq
	fi
	resultOrderId=${orderId}
} #createAnOrder

function postString ()
{
	orderId=$1
	checkNotEmpty "${orderId}" "<orderID>"
	sourceString=$2
	checkNotEmpty "${sourceString}" "<sourceString>"
	sourceLang=$3
	checkNotEmpty "${sourceLang}" "<sourceLang>"
	targertLang=$4
	checkNotEmpty "${targertLang}" "<targertLang>"
	response=$(
		curl --silent --location --request POST "https://${baseUrl}/api/v2/orders/${orderId}/strings" \
		--header "Authorization: Bearer ${apiKey}" \
		--header 'Content-Type: application/json' \
		--data-raw "{\"strings\":[{\"value\":\"${sourceString}\",\"target_lang\":[\"${targertLang}\"],\"source_lang\": \"${sourceLang}\"}]}" \
	)
	if [ $? -eq 0 ] && [[ $(jq -r '.success' <<< ${response}) == true ]]; then
		#getting the string ID using bash methods only (python strongly recommended for JSON parsing)
		stringId=$(grep -oE '"string_id":[0-9]*' <<< "${response}" | sed 's@"string_id":@@')
		execSuccess "Your string has been posted to Order [${orderId}] and has String ID: [${stringId}]" 
	else
		execFailed "There was a problem while posting your string, please see bellow the response:"
		echo ${response} | jq
		handleExit 1
	fi
	resultStringId=${stringId}
} #postString

function sendFile ()
{
	orderId=$1
	checkNotEmpty "${orderId}" "<OrderID>"
	sourceLang=$2
	checkNotEmpty "${sourceLang}" "<sourceLang>"
	targetLang=$3
	checkNotEmpty "${targetLang}" "<targertLang>"
	pathToSourceFile=$4
	checkNotEmpty "${pathToSourceFile}" "<path_to_file>"
	response=$(
		curl --silent --location --request POST "https://${baseUrl}/api/v2/orders/${orderId}/files" \
		--header 'Content-Type: multipart/form-data' \
		--header "Authorization: Bearer ${apiKey}" \
		--form "sourcelang=\"${sourceLang}\"" \
		--form "targetlang=\"${targetLang}\"" \
		--form "file=@\"${pathToSourceFile}\"" \
	)
	if [ $? -eq 0 ] && [[ $(jq -r '.success' <<< ${response}) == true ]]; then
		#getting the file ID using bash methods only (python strongly recommended for JSON parsing)
		fileId=$(jq -r '.data.fileid' <<< ${response})
		execSuccess "Your source file has been posted to Order [${orderId}] and has File ID: [${fileId}]" 
	else
		execFailed "There was a problem while sending your source file, please see bellow the response:"
		echo ${response} | jq
		handleExit 1
	fi
	resultFileId=${fileId}
} #sendFile

function getOrderDetails ()
{
	orderId=$1
	checkNotEmpty "${orderId}" "<OrderID>"
	response=$(
		curl --silent --location --request GET "https://${baseUrl}/api/v2/orders/${orderId}"  \
		--header "Authorization: Bearer ${apiKey}" \
	)
	if [ $? -eq 0 ] && [[ $(jq -r '.success' <<< ${response}) == true ]]; then
		getting the attributes using jq - yes, an array would have made sense
		orderName=$(jq -r '.data.name' <<< "${response}")
		orderStatus=$(jq -r '.data.status' <<< "${response}")
		processType=$(jq -r '.data.process_type' <<< "${response}")
		dueDate=$(jq -r '.data.duedate' <<< "${response}") 
		createdDate=$(jq -r '.data.created' <<< "${response}") 
		createdBy=$(jq -r '.data.emailaddress' <<< "${response}")
		sourceLang=$(jq -r '.data.sourcelang' <<< "${response}")
		targetLangs=$(jq -r '.data.targetlang[]' <<< "${response}")
		execSuccess "Your Order [${orderId}] has the following attributes:" 
		local txt=(
			""
			"	* Order ID: ${orderId}"
			"	* Order Name: ${orderName}"
			"	* Status: ${orderStatus}"
			"	* Process Type: ${processType}"
			"	* Source Language: ${sourceLang}"
			"	* Target Language(s): ${targetLangs[@]}"
			"	* Creation Date: ${createdDate}"
			"	* Created By: ${createdBy}"
			"	* Due date: ${dueDate}"
			""
		)
		printf "%s\n" "${txt[@]}"
	else
		execFailed "There was a problem while getting your Order, please see the response below:"
		echo ${response} | jq
		handleExit 1
	fi
} #getOrderDetails

function getAllOrderDetails ()
{
	outputCsv $1
	response=$(
		curl --silent --location --request GET "https://${baseUrl}/api/v2/orders"  \
		--header "Authorization: Bearer ${apiKey}" \
	)
	if [ $? -eq 0 ] && [[ $(jq -r '.success' <<< ${response}) == true ]]; then
		if [ "${csvOutput}" = true ]; then
			echo ${response} | jq -r '.data[] | [.orderid, .name, .status, .process_type, .user.email, .duedate] | @csv' | awk -v FS="\t" 'BEGIN{print "\"Order ID\",\"Order Name\",\"Status\",\"Type\",\"Creator\",\"Due Date\""}{printf "%s\t%s\t%s%s\t%s\t%s\t%s",$1,$2,$3,$4,$5,$6,ORS}'
		else
			execSuccess "Please see a list of Orders bellow" 
			echo ${response} | jq -r '["Order ID","Order Name","Status","Process Type","Creator","Due Date"], ["--------","----------","------","------------","-------","--------"], (.data[] | [.orderid, .name, .status, .process_type, .user.email, .duedate]) | @tsv' | column -ts $'\t'
		fi
	else
		execFailed "There was a problem while getting your Order, please see the response below:"
		echo ${response} | jq
		handleExit 1
	fi
} #getAllOrderDetails

function submitOrder ()
{
	orderId=$1
	checkNotEmpty "${orderId}" "<OrderID>"
	response=$(
		curl --silent --location --request POST "https://${baseUrl}/api/v2/orders/${orderId}/submit"  \
		--header "Authorization: Bearer ${apiKey}" \
	)
	if [ $? -eq 0 ] && [[ $(jq -r '.success' <<< ${response}) == true ]]; then
		execSuccess "Your Order [${orderId}] has beeen submitted" 
	else
		execFailed "There was a problem while submitting your Order, please see the response below:"
		echo ${response} | jq
		handleExit 1
	fi
} #submitOrder

function getStringInfo ()
{
	orderId=$1
	checkNotEmpty "${orderId}" "<OrderID>"
	stringId=$2
	checkNotEmpty "${stringId}" "<stringID>"
	response=$(
		curl --silent --location --request GET "https://${baseUrl}/api/v2/orders/${orderId}/strings/${stringId}"  \
		--header "Authorization: Bearer ${apiKey}" \
	)
	if [ $? -eq 0 ] && [[ $(jq -r '.success' <<< ${response}) == true ]]; then
		#getting the attributes using bash methods only (python strongly recommended for JSON parsing)
		execSuccess " has the following strings submitted" 
		translatedString=$(grep -oE '"translated_value":[^,]*,' <<< "${response}" | sed 's@"translated_value":@@')
		stringStatus=$(grep -oE '"status":"[^"]*"' <<< "${response}" | sed 's@"status":@@')
		#using the string status to evaluate if it was completed or not, can also be done the other way arround, if "complete" do this, else is not complete...
		if [ "$stringStatus" != "\"complete\"" ]; then
			execSuccess "Your Order [${orderId}] has a string with ID [${stringId}] which has not yet been translated, and its status is [${stringStatus}]."
		else
			execSuccess "Your Order [${orderId}] has a string with ID [${stringId}] which has been translated."
			printf "\n\t* Translated String: ${translatedString}\n"
		fi
	else
		execFailed "There was a problem while getting your string, please see the response below:"
		echo ${response} | jq
		handleExit 1
	fi
} #getStringInfo

function getFile ()
{
	orderId=$1
	checkNotEmpty "${orderId}" "<OrderID>"
	fileId=$2
	checkNotEmpty "${fileId}" "<FileID>"
	#set a filename if needed, you can also use the "fileName" variable form the function "getFileInfo"
	fileName="$(pwd)/output.myacclaro"
		response=$(
			curl --silent --location --request GET -w "%{http_code}" "https://${baseUrl}/api/v2/orders/${orderId}/files/${fileId}" -o ${fileName}  \
			--header "Authorization: Bearer ${apiKey}" \
		)
	if [ ${response} -eq 200 ]; then
		writeFileTest=$(echo ${fileName} >${fileName}.test && rm ${fileName}.test) #test to check if we can write in the destination folder, cURL will not return an error for that
		if [ $? -eq 0 ]; then
			execSuccess "Your file with ID [${fileId}] has been downloaded here: ${fileName}" 
		else
			execFailed "The system failed while trying to save the file, please check the error message"
			echo ${writeFile}
			handleExit 1
		fi
	else
		execFailed "There was a problem while getting your file, the status code is [${response}]"
		handleExit 1
	fi
} #getFile

function getFileInfo ()
{
	orderId=$1
	checkNotEmpty "${orderId}" "<OrderID>"
	fileId=$2
	checkNotEmpty "${fileId}" "<FileID>"
	response=$(
		curl --silent --location --request GET "https://${baseUrl}/api/v2/orders/${orderId}/files/${fileId}/status"  \
		--header "Authorization: Bearer ${apiKey}" \
	)
	if [ $? -eq 0 ] && [[ $(jq -r '.success' <<< ${response}) == true ]]; then
		#getting the attributes using bash methods only (python strongly recommended for JSON parsing)
		fileName=$(grep -oE '"filename":"[^"]*"' <<< "${response}" | sed 's@"filename":@@')
		fileStatus=$(grep -oE '"status":"[^"]*"' <<< "${response}" | sed 's@"status":@@')
		targetFileId=$(grep -oE '"targetfile":[0-9]*' <<< "${response}" | sed 's@"targetfile":@@')
		if [[ "$fileStatus" == "\"complete\"" ]]; then
			execSuccess "Your file [${fileName}] has been translated with status: [${fileStatus}], please proceed to download the file using file ID: [${targetFileId}]" 
		else
			execSuccess "Your file [${fileName}] has yet not been translated and has status: [${fileStatus}]" 
		fi
	else
		execFailed "There was a problem while getting your file info, please see the response below:"
		echo ${response} | jq
		handleExit 1
	fi
} #getFileInfo

function getComments ()
{
	orderId=$1
	checkNotEmpty "${orderId}" "<OrderID>"
	outputCsv $2
	response=$(
		curl --location --silent --request GET "https://${baseUrl}/api/v2/orders/${orderId}/comments" \
		--header "Authorization: Bearer ${apiKey}" \
	)
	if [ $? -eq 0 ] && [[ $(jq -r '.success' <<< ${response}) == true ]]; then
		if [ "${csvOutput}" = true ]; then
			echo ${response} | jq -r '.data[] | [.author, .timestamp, .comment] | @csv' | awk -v FS="\t" 'BEGIN{print "\"Author\",\"Creation Date\",\"Comment\""}{printf "%s\t%s\t%s%s",$1,$2,$3,ORS}'	
		else
			execSuccess "Your Order [${orderId}] has comments, please see comments bellow:" 
			echo ${response} | jq -r '["Author","Timestamp","Comment"], ["------","---------","-------"], (.data[] | [.author, .timestamp, .comment] ) | @tsv' | column -ts $'\t'
		fi
	else
		execFailed "There was a problem while getting your comments"
		echo ${response} | jq
		handleExit 1
	fi
} #getComments	

function setComment ()
{
	orderId=$1
	checkNotEmpty "${orderId}" "<OrderID>"
	commentLine=$2
	checkNotEmpty "${commentLine}" "<Comment>"
	response=$(
		curl --location --silent --request POST "https://${baseUrl}/api/v2/orders/${orderId}/comment" \
		--header "Authorization: Bearer ${apiKey}" \
		--data-urlencode "comment=${commentLine}" \
	)
	if [ $? -eq 0 ] && [[ $(jq -r '.success' <<< ${response}) == true ]]; then
		execSuccess "Your Order [${orderId}] has been added the following comment:"
		echo "	*    ${commentLine}"
	else
		execFailed "There was a problem while posting your comment"
		echo ${response} | jq
		handleExit 1
	fi
} #setComment

function requestQuote()
{
	orderId=$1
	checkNotEmpty "${orderId}" "<OrderID>"
	response=$(
		curl --location --silent --request GET "https://${baseUrl}/api/v2/orders/${orderId}/quote" \
		--header "Authorization: Bearer ${apiKey}" \
	)
	if [ $? -eq 0 ] && [[ $(jq -r '.success' <<< ${response}) == true ]]; then
		execSuccess "Quote succesfully requested for Order [${orderId}]" 
	else
		execFailed "There was a problem while requestiong your Quote for Order [${orderId}]"
		echo ${response} | jq
		handleExit 1
	fi
} #requestQuote

function getQuoteDetails()
{
	orderId=$1
	checkNotEmpty "${orderId}" "<OrderID>"
	response=$(
		curl --location --silent --request GET "https://${baseUrl}/api/v2/orders/${orderId}/quote-details" \
		--header "Authorization: Bearer ${apiKey}" \
	)
	if [ $? -eq 0 ] && [[ $(jq -r '.success' <<< ${response}) == true ]]; then
		totalQuote=$(echo ${response} | jq -r .data.total)
		execSuccess "Quote details for Order [${orderId}] are bellow:"
		echo ${response} | jq -r '["Description","Quantity","Unit Price","Subtotal"], ["-----------","--------","----------","--------"], (.data.lines[] | [.description, .quantity, "$"+.unitprice, "$"+.price])  | @tsv' | column -ts $'\t'
		echo "** TOTAL: \$${totalQuote}" 
	else
		execFailed "There was a problem while getting your Quote"
		echo ${response} | jq
		handleExit 1
	fi
} #getQuoteDetails

function quoteWorkflow()
{
	orderId=$1
	checkNotEmpty "${orderId}" "<OrderID>"
	checkNotEmpty "$2" "<--approve/--decline>"
	case "$2" in
		--approve | -a)
			quoteDecision="quote-approve"
			verbPresCont="approving"
			verbPast="approved"
		;;

		--decline | -d)
			quoteDecision="quote-decline"
			verbPresCont="declining"
			verbPast="declined"
		;;
		
		*)
			execFailed "You should either decline or approve the quote [--approve/--decline]"
			handleExit 1
		;;

	esac

		response=$(
			curl --location --silent --request POST "https://${baseUrl}/api/v2/orders/${orderId}/${quoteDecision}" \
			--header "Authorization: Bearer ${apiKey}" \
		)
		if [ $? -eq 0 ] && [[ $(jq -r '.success' <<< ${response}) == true ]]; then
			execSuccess "The Quote for Order [${orderId}] has been succesfully ${verbPast}"
		else
			execFailed "There was a problem while ${verbPresCont} your Quote for Order [${orderId}]"
			echo ${response} | jq
			handleExit 1
		fi	
} #quoteWorkflow

function addTargetToOrder()
{
	orderId=$1
	checkNotEmpty "${orderId}" "<OrderID>"
	targetLang=$2
	checkNotEmpty "${targetLang}" "<targetLang>"
	response=$(
		curl --location --silent --request POST "https://${baseUrl}/api/v2/orders/${orderId}/language" \
		--header "Authorization: Bearer ${apiKey}" \
		--data-urlencode "targetlang=${targetLang}" \
	)
	if [ $? -eq 0 ] && [[ $(jq -r '.success' <<< ${response}) == true ]]; then
		execSuccess "The following target language: [${targetLang}] has been succesfully added to the Order [${orderId}]"
	else
		execFailed "There was a problem while adding the target lang [${targetLang}] to Order [${orderId}]"
		echo ${response} | jq
		handleExit 1
	fi
} #addTargetToOrder

function addSourceAndTargetToOrder()
{
	orderId=$1
	checkNotEmpty "${orderId}" "<OrderID>"
	sourceLang=$2
	checkNotEmpty "${sourcetLang}" "<sourceLang>"
	targetLang=$3
	checkNotEmpty "${targetLang}" "<targetLang>"
	response=$(
		curl --location --silent --request POST "https://${baseUrl}/api/v2/orders/${orderId}/language-pair" \
		--header "Authorization: Bearer ${apiKey}" \
		--data-urlencode "sourcelang=${sourceLang}" \
		--data-urlencode "targetlang=${targetLang}" \
	)
	if [ $? -eq 0 ] && [[ $(jq -r '.success' <<< ${response}) == true ]]; then
		execSuccess "The following language pair: [${sourceLang} > ${targetLang}] has been succesfully added to the Order [${orderId}]"
	else
		execFailed "There was a problem while adding the language pair: [${sourceLang} > ${targetLang}] to Order [${orderId}]"
		echo ${response} | jq
		handleExit 1
	fi
} #addSourceAndTargetToOrder

function sendReferenceFile()
{
	orderId=$1
	checkNotEmpty "${orderId}" "<OrderID>"
	sourceLang=$2
	checkNotEmpty "${sourceLang}" "<sourceLang>"
	targetLang=$3
	checkNotEmpty "${targetLang}" "<targertLang>"
	pathToReferenceFile=$4
	checkNotEmpty "${pathToReferenceFile}" "<path_to_reference_file>"
	response=$(
		curl --silent --location --request POST "https://${baseUrl}/api/v2/orders/${orderId}/reference-file" \
		--header 'Content-Type: multipart/form-data' \
		--header "Authorization: Bearer ${apiKey}" \
		--form "sourcelang=\"${sourceLang}\"" \
		--form "targetlang=\"${targetLang}\"" \
		--form "file=@\"${pathToReferenceFile}\"" \
	)
	if [ $? -eq 0 ] && [[ $(jq -r '.success' <<< ${response}) == true ]]; then
		#getting the file ID using bash methods only (python strongly recommended for JSON parsing)
		fileId=$(jq -r '.data.fileid' <<< ${response})
		execSuccess "Your reference file has been posted to Order [${orderId}] for the following target lang(s): [${targetLang}]" 
	else
		execFailed "There was a problem while sending your reference file, please see bellow the response:"
		echo ${response} | jq
		handleExit 1
	fi
} #sendReferenceFile


################
###   BODY   ###
################

# check that all dependencies are met before starting
checkToolsInstalled

# if no arguments defined, then print script usage
if [[ $# -eq 0 ]] ; then
	usage
	exit 1
fi

# read arguments and execute accordingly
while (( $# ))
do
	case "$1" in

		--help | -h)
			usage
			exit 0
		;;

		--version | -v)
			version
			exit 0
		;;
		
		--console | -c)
			consoleMode
		;;
		
	esac
	
	baseUrl="$1"
	checkNotEmpty "${baseUrl}" "base URL"
	apiKey="$2"
	checkNotEmpty "${apiKey}" "API key"
	case "$3" in

		--create-order | -co)
			createAnOrder "$4" "$5"
			exit 0
		;;
		
		--post-sting | -ps)
			postString "$4" "$5" "$6" "$7"
			exit 0
		;;
		
		--send-file | -sf)
			sendFile "$4" "$5" "$6" "$7"
			exit 0
		;;		
		
		--send-reference-file | -srf)
			sendReferenceFile "$4" "$5" "$6" "$7"
			exit 0
		;;
		
		--get-order-details | -god)
			getOrderDetails "$4"
			exit 0
		;;
		
		--get-all-order-details | -gaod)
			getAllOrderDetails "$4"
			exit 0
		;;
		
		--submit-order | -so)
			submitOrder "$4"
			exit 0
		;;
		
		--get-string-info | -gsi)
			getStringInfo "$4" "$5"
			exit 0
		;;
		
		--get-file | -gf)
			getFile "$4" "$5"
			exit 0
		;;
		
		--get-file-info | -gfi)
			getFileInfo "$4" "$5"
			exit 0
		;;
		
		--get-order-comments | -goc)
			getComments "$4" "$5"
			exit 0
		;;
		
		--set-order-commnet | -soc)
			setComment "$4" "$5"
			exit 0
		;;
		
		--request-quote | -rq)
			requestQuote "$4"
			exit 0
		;;
		
		--get-quote-details | -gqd)
			getQuoteDetails "$4"
			exit 0
		;;
		
		--quote-decision | -qd)
			quoteWorkflow "$4" "$5"
			exit 0
		;;
		
		--add-target-lang | -atl)
			addTargetToOrder "$4" "$5"
			exit 0
		;;
		
		--add-lang-pair | -alp)
			addSourceAndTargetToOrder "$4" "$5" "$6"
			exit 0
		;;
		
		*)
			wrongUsage "Option/command not recognized. Please use --help to see what arguments are valid."
			exit 1
		;;
	esac
done

