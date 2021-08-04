#!/bin/bash
### "Global" variables to work with
SCRIPT=$( basename "$0" )
VERSION="0.4-beta"
consoleActivated=false
bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'
history -r script_history
set -o vi
history -w script_history


#######################################
# Function to handle success messages #
# call as:						 	  #
#   execSuccess ${message}			  #
#######################################
function execSuccess()
{
	echo -e "$(date +%F\ %T) :: [\e[92mSUCCESS\e[39m] - $1"
} #execSuccess

######################################
# Function to handle failed messages #
# call as:						     #
#   execFailed ${message}			 #
######################################
function execFailed()
{
	echo -e "$(date +%F\ %T) :: [\e[31mFAIL\e[39m] - $1"
} #execFailed

##################
# Checks that necessary arguments are sent before launching the function
##################
function checkNotEmpty()
{
	if [[ -z $1 ]]; then
		execFailed "The following mandatory argument [$2] is empty."
		handleExit 1
	fi
}

##################
# Checks if CSV output is requested
##################
function outputCsv()
{
	if [[ "$1" == "-csv" ]]; then
		csvOutput=true
	fi
}

##################
# Checks that cURL is installed
##################
function checkToolsInstalled()
{
	tools=("curl" "jq")
	for tool in ${tools[@]}
	do
		output=$(${tool} --version)
		if [ $? -ne 0 ]; then
			execFailed "[${tool}] is necessary to run this script, exiting."
			handleExit 1
		fi
	done
} #checkCurlInstalled

##########################################
# Message to display for usage and help. #
##########################################
function usage()
{
	local txt=(
		"Utility ${SCRIPT} for Querying My Acclaro's REST API."
		"Usage: $SCRIPT <base URL> <API key> [options] <arguments>"
		""
		"Command:"
		"	<base URL>	e.g. \"apisandbox.acclaro.com\""
		"	<api Key>	e.g. \"pYXQiOjE2MjYyODYxOTIsInN1YiI6...\""
		""
		"Options:"
		"	--help, -h	Print help."
		"	--version, -v	Print version."
		"	--console, -c	Starts the interactive Console Mode"
		"	--create-order, -co <name> [string]	Create an Order, if \"string\" added as parameter, then the Order takes strings rather than files."
		"	--add-target-lang, -atl <orderID> <targetLang>	Adds a target language to an Order."
		"	--post-string, -ps <orderID> <sourceString> <sourceLang> <targertLang>	Post a string."
		"	--send-file, -sf <orderID> <sourceLang> <targertLang> <path_to_file>	Sends a source file."
		"	--send-reference-file, -srf <orderID> <sourceLang> <targertLang> <path_to_reference_file>	Sends a reference file (e.g. a styleguide) for a particular language."
		"	--get-order-details, -god <orderID>	Gets Order details."
		"	--get-all-order-details, -gaod <orderID>	Gets All Order details."
		"	--set-order-comment, -soc <orderID> <comment>	Sets a Comment for the Order"
		"	--get-order-comments, -goc <orderID>	Gets the Order Comments"
		"	--submit-order, -so <orderID>	Submits the Order for preparation and then translation."
		"	--get-string-info, -gsi <orderID> <stringID>	Gets the String information and the translated string once completed."
		"	--get-file, -gf <orderID> <fileID>	Gets a file based on its ID."
		"	--get-file-info, -gfi <orderID> <fileID>	Gets the information of a file based on its ID."
		"	--request-quote, -rq <orderID>	Requests a quote for the Order."
		"	--get-quote-details, -gqd <orderID>	Gets the Quote status for the Order."
		"	--quote-decision, -qd <orderID> [--approve,-a/--decline,-d]	Approves/declines the quoted price for the Order."
		""
		"Example:"
		"	$SCRIPT \"apisandbox.acclaro.com\" \"pYXQiOjE2MjYyODYxOTIsInN1YiI6...\" --send-file \"15554\" \"en-us\" \"de-de\" \"./mySourceFile.docx\""
	)
	printf "%s\n" "${txt[@]}"
} #usage

function usageConsole()
{
	local txt=(
		""
		"MyAcclaro Console for Querying MyAcclaro's REST API."
		""
		"Commands:"
		"	login	Interactive login to MyAcclaro API."
		"	logout	Clears the login information."
		"	help	Print help."
		"	version	Print version."
		"	create-order <name> [string]	Create an Order, if \"string\" added as parameter, then the Order takes strings rather than files."
		"	add-target-lang <orderID> <targetLang>	Adds a target language to an Order."
		"	post-string <orderID> <sourceString> <sourceLang> <targertLang>	Post a string."
		"	send-file <orderID> <sourceLang> <targertLang> <path_to_file>	Sends a source file."
		"	send-reference-file <orderID> <sourceLang> <targertLang> <path_to_reference_file>	Sends a reference file (e.g. a styleguide) for a particular language."
		"	get-order-details <orderID>	Gets Order details."
		"	get-all-order-details	Gets All Order details."
		"	set-order-comment <orderID> <comment>	Sets a Comment for the Order"
		"	get-order-comments <orderID>	Gets the Order Comments"
		"	submit-order <orderID>	Submits the Order for preparation and then translation."
		"	get-string-info <orderID> <stringID>	Gets the String information and the translated string once completed."
		"	get-file <orderID> <fileID>	Gets a file based on its ID."
		"	get-file-info <orderID> <fileID>	Gets the information of a file based on its ID."
		"	request-quote <orderID>	Requests a quote for the Order."
		"	get-quote-details <orderID>	Gets the Quote status for the Order."
		"	quote-decision <orderID> [--approve,-a/--decline,-d]	Approves/declines the quoted price for the Order."
		""
		"Example:"
		"MyAcclaro> send-file 15554 en-us de-de ./mySourceFile.docx"
		""
		"Shell commands:"
		"	The following shell commands are available: ls, cd, pwd, grep, find, cat, less"
		""
	)
	printf "%s\n" "${txt[@]}"
} #usage

########################################
# Message to display when wrong usage. #
########################################
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
	echo "command '${line}' not found"
} #wrongUsage

###################################
# Message to display for version. #
###################################
function version
{
	local txt=(
		"$SCRIPT version $VERSION"
	)

	printf "%s\n" "${txt[@]}"
} #version

function versionDisp()
{
	echo "MyAcclaro Console ${VERSION}"
} #versionDisp

function console()
{
	unset line #clean before using, for sanity purposes! :)
	if [[ -z ${baseUrl} || -z ${apiKey} ]]; then
		echo -e -n "\e[33mMyAcclaro@DISCONNECTED\e[39m> "
		read -e input
		history -s "${input}"
		eval line=(${input})
	else
		echo -e -n "\e[92mMyAcclaro@${baseUrl}\e[39m> "
		read -e input
		history -s "${input}"
		eval line=(${input})
	fi
}

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
		if [ $? -eq 0 ] && [ "$(grep -oE '\"success\":[a-z]*' <<< \"${response}\" | sed 's@\"success\":@@')" = "true" ]; then
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
}

function logOut()
{
	baseUrl=""
	apiKey=""
	execSuccess "You have been successfully logged out."
}

function headerGreeting()
{
	versionDisp
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
}

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
	if [ $? -eq 0 ] && [ "$(grep -oE '\"success\":[a-z]*' <<< \"${response}\" | sed 's@\"success\":@@')" = "true" ]; then
		#getting the Order ID using bash methods only (python strongly recommended for JSON parsing)
		orderId=$(grep -oE '"orderid":[0-9]*' <<< "${response}" | sed 's@"orderid":@@')
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
	if [ $? -eq 0 ] && [ "$(grep -oE '\"success\":[a-z]*' <<< \"${response}\" | sed 's@\"success\":@@')" = "true" ]; then
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
	if [ $? -eq 0 ] && [ "$(grep -oE '\"success\":[a-z]*' <<< \"${response}\" | sed 's@\"success\":@@')" = "true" ]; then
		#getting the file ID using bash methods only (python strongly recommended for JSON parsing)
		fileId=$(grep -oE '"fileid":[0-9]*' <<< "${response}" | sed 's@"fileid":@@')
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
	if [ $? -eq 0 ] && [ "$(grep -oE '\"success\":[a-z]*' <<< \"${response}\" | sed 's@\"success\":@@')" = "true" ]; then
		#getting the attributes using bash methods only (python strongly recommended for JSON parsing)
		orderName=$(grep -oE '"name":"[^"]*"' <<< "${response}" | sed 's@"name":@@')
		orderStatus=$(grep -oE '"status":"[^"]*"' <<< "${response}" | sed 's@"status":@@')
		processType=$(grep -oE '"process_type":"[^"]*"' <<< "${response}" | sed 's@"process_type":@@')
		dueDate=$(grep -oE '"duedate":"[^"]*"' <<< "${response}" | sed 's@"duedate":@@') #does not work, check it!
		execSuccess "Your Order [${orderId}] has the following attributes:" 
		printf "\n\t* Order ID: ${orderId}\n\t* Order Name: ${orderName}\n\t* Status: ${orderStatus}\n\t* Process Type: ${processType}\n\t* Due date: ${dueDate}\n\n"
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
	if [ $? -eq 0 ] && [ "$(grep -oE '\"success\":[a-z]*' <<< \"${response}\" | sed 's@\"success\":@@')" = "true" ]; then
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
} #getOrderDetails

function submitOrder ()
{
	orderId=$1
	checkNotEmpty "${orderId}" "<OrderID>"
	response=$(
		curl --silent --location --request POST "https://${baseUrl}/api/v2/orders/${orderId}/submit"  \
		--header "Authorization: Bearer ${apiKey}" \
	)
	if [ $? -eq 0 ] && [ "$(grep -oE '\"success\":[a-z]*' <<< \"${response}\" | sed 's@\"success\":@@')" = "true" ]; then
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
	if [ $? -eq 0 ] && [ "$(grep -oE '\"success\":[a-z]*' <<< \"${response}\" | sed 's@\"success\":@@')" = "true" ]; then
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
		writeFileTest=$(echo ${fileName} >${fileName}.test && rm ${fileName}.test)
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
	if [ $? -eq 0 ] && [ "$(grep -oE '\"success\":[a-z]*' <<< \"${response}\" | sed 's@\"success\":@@')" = "true" ]; then
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
	if [ $? -eq 0 ] && [ "$(grep -oE '\"success\":[a-z]*' <<< \"${response}\" | sed 's@\"success\":@@')" = "true" ]; then
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
	if [ $? -eq 0 ] && [ "$(grep -oE '\"success\":[a-z]*' <<< \"${response}\" | sed 's@\"success\":@@')" = "true" ]; then
		execSuccess "Your Order [${orderId}] has been added the following comment:"
		echo "	****** Comment Start ******"
		echo "	*    ${commentLine}"
		echo "	****** Comment End ******"
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
	if [ $? -eq 0 ] && [ "$(grep -oE '\"success\":[a-z]*' <<< \"${response}\" | sed 's@\"success\":@@')" = "true" ]; then
		execSuccess "Quote succesfully requested for Order [${orderId}]" 
	else
		execFailed "There was a problem while requestiong your Quote for Order [${orderId}]"
		echo ${response} | jq
		handleExit 1
	fi
}

function getQuoteDetails()
{
	orderId=$1
	checkNotEmpty "${orderId}" "<OrderID>"
	response=$(
		curl --location --silent --request GET "https://${baseUrl}/api/v2/orders/${orderId}/quote-details" \
		--header "Authorization: Bearer ${apiKey}" \
	)
	if [ $? -eq 0 ] && [ "$(grep -oE '\"success\":[a-z]*' <<< \"${response}\" | sed 's@\"success\":@@')" = "true" ]; then
		totalQuote=$(echo ${response} | jq -r .data.total)
		#arrayLength=$(echo ${response} | jq -r '(.data.lines | length)')
		#echo ${arrayLength}
		execSuccess "Quote details for Order [${orderId}] are bellow:"
		echo ${response} | jq -r '["Description","Quantity","Unit Price","Subtotal"], ["-----------","--------","----------","--------"], (.data.lines[] | [.description, .quantity, "$"+.unitprice, "$"+.price])  | @tsv' | column -ts $'\t'
		echo "** TOTAL: \$${totalQuote}" 
	else
		execFailed "There was a problem while getting your Quote"
		echo ${response} | jq
		handleExit 1
	fi
}

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
		if [ $? -eq 0 ] && [ "$(grep -oE '\"success\":[a-z]*' <<< \"${response}\" | sed 's@\"success\":@@')" = "true" ]; then
			execSuccess "The Quote for Order [${orderId}] has been succesfully ${verbPast}"
		else
			execFailed "There was a problem while ${verbPresCont} your Quote for Order [${orderId}]"
			echo ${response} | jq
			handleExit 1
		fi	
}

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
	if [ $? -eq 0 ] && [ "$(grep -oE '\"success\":[a-z]*' <<< \"${response}\" | sed 's@\"success\":@@')" = "true" ]; then
		execSuccess "The following target language: [${targetLang}] has been succesfully added to the Order [${orderId}]"
	else
		execFailed "There was a problem while adding the target lang [${targetLang}] to Order [${orderId}]"
		echo ${response} | jq
		handleExit 1
	fi
}

#function addSourceAndTargetToOrder()
#{
#	#stuff
#}

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
	if [ $? -eq 0 ] && [ "$(grep -oE '\"success\":[a-z]*' <<< \"${response}\" | sed 's@\"success\":@@')" = "true" ]; then
		#getting the file ID using bash methods only (python strongly recommended for JSON parsing)
		fileId=$(grep -oE '"fileid":[0-9]*' <<< "${response}" | sed 's@"fileid":@@')
		execSuccess "Your reference file has been posted to Order [${orderId}] for the following target lang(s): [${targetLang}]" 
	else
		execFailed "There was a problem while sending your reference file, please see bellow the response:"
		echo ${response} | jq
		handleExit 1
	fi
}

function handleExit()
{
	if [[ "${consoleActivated}" != true ]]; then
		exit $1
	else
		echo $1 >/dev/null #just do something xD
	fi
}

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
				versionDisp
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
}


################
###			 ###
###   BODY   ###
###			 ###
################
#if no arguments defined, then print script usage
if [[ $# -eq 0 ]] ; then
	usage
	exit 1
fi
#read arguments and execute accordingly
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
	
	checkToolsInstalled
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
		
		*)
			wrongUsage "Option/command not recognized. Please use --help to see what arguments are valid."
			exit 1
		;;
	esac
done

