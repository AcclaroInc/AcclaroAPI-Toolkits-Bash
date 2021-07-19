#!/bin/bash

### "Global" variables to work with
SCRIPT=$( basename "$0" )
VERSION="0.0.1 alpha 1"
orderId=""
stringId=""
fileId=""
# Environment and auth - apiKey should be set as an environmental variable for security reasons
baseUrl=""
apiKey=""

#######################################
# Function to handle success messages #
# call as:						 	  #
#   execSuccess ${message}			  #
#######################################
function execSuccess()
{
	echo "$(date +%F\ %T) :: [SUCCESS] - $1"
} #execSuccess

######################################
# Function to handle failed messages #
# call as:						     #
#   execFailed ${message}			 #
######################################
function execFailed()
{
	echo "$(date +%F\ %T) :: [FAIL] - $1"
} #execFailed

##################
# Checks that necesary arguments are sent before launching the function
##################
function checkNotEmpty()
{
	if [[ -z $1 ]]; then
		execFailed "the following argument [$2] is empty, this argument is mandatory!"
		exit 1
	fi
}

##########################################
# Message to display for usage and help. #
##########################################
function usage()
{
	local txt=(
		"Utility ${SCRIPT} for Querying myAcclaro's REST API."
		"Usage: $SCRIPT <base URL> <API key> [options] <command> [arguments]"
		""
		"Command:"
		"	<base URL>	e.g. \"https://apisandbox.acclaro.com\""
		"	<api Key>	e.g. \"pYXQiOjE2MjYyODYxOTIsInN1YiI6...\""
		""
		"Options:"
		"	--help, -h	Print help."
		"	--version, -v	Print version."
		"	--create-order, -co <name>	Create an Order."
		"	--post-string, -ps <orderID> <sourceString> <sourceLang> <targertLang>	Post a string."
		"	--send-file, -sf <orderID> <sourceLang> <targertLang> <Path_to_file>	Sends a source file."
		"	--get-order-details, -god <orderID>	Gets Order details."
		"	--submit-order, -so <orderID>	Submits the Order for preparation."
		"	--get-file, -gf <orderID> <fileID>	Gets a file based on its ID."
		"	--get-file-info, -gfi <orderID> <fileID>	Gets the information of a file based on its ID."
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

	[[ $message ]] && printf "$message\n"

	printf "%s\n" "${txt[@]}"
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

function createAnOrder()
{
	orderName=$1
	checkNotEmpty "${orderName}" "<name>"
	response=$(curl --location --request POST "https://${baseUrl}/api/v2/orders" 2>&1\
			--header 'Content-Type: multipart/form-data' \
			--header "Authorization: Bearer ${apiKey}" \
			--form "name=\"${orderName}\"" \
			#--form "process_type=\"${processType}\""
			)
	if [ $? -eq 0 ]; then
		#getting the Order ID using bash methods only (python strongly recommended for JSON parsing)
		orderId=$(grep -oE '"orderid":[0-9]*' <<< "${response}" | sed 's@"orderid":@@')
		execSuccess "Your order has been created and has id [${orderId}]" 
	else
		execFailed "There was a problem while creating your Order, please see bellow the response:"
		printf "\n\t\t" ${response}
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
#	response=$(curl --location --request POST "https://${baseUrl}/api/v2/orders/${orderId}/strings" 2>&1\
#			--header "Authorization: Bearer ${apiKey}" \
#			--header 'Content-Type: application/json' \
#			--data-raw "{
#				\"strings\": [
#					{
#					\"value\": \"${sourceString}\",
#					"target_lang": [
#						\"${targertLang}\"
#						],
#					\"source_lang\": \"${sourceLang}\",
#					\"key\": \"${sourceStringKey}\",
#					\"callback\": \"${stringCallbackUrl}\"
#					}
#				]
#			}")
	response=$(curl --location --request POST "https://${baseUrl}/api/v2/orders/${orderId}/strings" 2>&1\
			--header "Authorization: Bearer ${apiKey}" \
			--header 'Content-Type: application/json' \
			--data-raw "{
				\"strings\": [
					{
					\"value\": \"${sourceString}\",
					"target_lang": [
						\"${targertLang}\"
						],
					\"source_lang\": \"${sourceLang}\"
					}
				]
			}")
	if [ $? -eq 0 ]; then
		#getting the string ID using bash methods only (python strongly recommended for JSON parsing)
		stringId=$(grep -oE '"string_id":[0-9]*' <<< "${response}" | sed 's@"string_id":@@')
		execSuccess "Your string has been posted to Order [${orderId}] and has String ID: [${stringId}]" 
	else
		execFailed "There was a problem while posting your string, please see bellow the response:"
		printf "\n\t\t${response}\n\n"
	fi
	resultStringId=${stringId}
}

function sendFile ()
{
	orderId=$1
	checkNotEmpty "${orderId}" "<OrderID>"
	sourceLang=$2
	checkNotEmpty "${sourceLang}" "<Source-Lang>"
	targetLang=$3
	checkNotEmpty "${targetLang}" "<Target-Lang>"
	pathToSourceFile=$4
	checkNotEmpty "${pathToSourceFile}" "<Path to Source File>"
	response=$(curl --location --request POST "https://${baseUrl}/api/v2/orders/${orderId}/files" 2>&1\
		--header 'Content-Type: multipart/form-data' \
		--header "Authorization: Bearer ${apiKey}" \
		--form "sourcelang=\"${sourceLang}\"" \
		--form "targetlang=\"${targetLang}\"" \
		--form "file=@\"${pathToSourceFile}\"")
	if [ $? -eq 0 ]; then
		#getting the file ID using bash methods only (python strongly recommended for JSON parsing)
		fileId=$(grep -oE '"fileid":[0-9]*' <<< "${response}" | sed 's@"fileid":@@')
		execSuccess "Your string has been posted to Order [${orderId}] and has File ID: [${fileId}]" 
	else
		execFailed "There was a problem while sending your file, please see bellow the response:"
		printf "\n\t${response}\n\n"
	fi
	resultFileId=${fileId}
}

function getOrderDetails ()
{
	orderId=$1
	checkNotEmpty "${orderId}" "<OrderID>"
	response=$(curl --location --request GET "https://${baseUrl}/api/v2/orders/${orderId}" 2>&1 \
		--header "Authorization: Bearer ${apiKey}")
	if [ $? -eq 0 ]; then
		#getting the attributes using bash methods only (python strongly recommended for JSON parsing)
		orderName=$(grep -oE '"name":"[^"]*"' <<< "${response}" | sed 's@"name":@@')
		orderStatus=$(grep -oE '"status":"[^"]*"' <<< "${response}" | sed 's@"status":@@')
		processType=$(grep -oE '"process_type":"[^"]*"' <<< "${response}" | sed 's@"process_type":@@')
		dueDate=$(grep -oE '"duedate":"[^"]*"' <<< "${response}" | sed 's@"duedate":@@') #does not work, check it!
		execSuccess "Your Order [${orderId}] has the following attributes:" 
		printf "\n\t* Order ID: ${orderId}\n\t* Order Name: ${orderName}\n\t* Status: ${orderStatus}\n\t* Process Type: ${processType}\n\t* Due date: ${dueDate}\n\n"
	else
		execFailed "There was a problem while getting your Order, please see bellow the response:"
		printf "\n\t${response}\n\n"
	fi
}

function submitOrder ()
{
	orderId=$1
	checkNotEmpty "${orderId}" "<OrderID>"
	response=$(curl --location --request POST "https://${baseUrl}/api/v2/orders/${orderId}/submit" 2>&1 \
		--header "Authorization: Bearer ${apiKey}")
	if [ $? -eq 0 ]; then
		execSuccess "Your Order [${orderId}] has beeen submitted" 
	else
		execFailed "There was a problem while submitting your Order, please see bellow the response:"
		printf "\n\t\t${response}\n\n"
	fi
}

function getStringInfo ()
{
	orderId=$1
	checkNotEmpty "${orderId}" "<OrderID>"
	stringId=$2
	checkNotEmpty "${stringId}" "<stringID>"
	reponse=$(curl --location --request GET "https://${baseUrl}/api/v2/orders/${orderId}/strings/${stringId}" 2>&1 \
		--header "Authorization: Bearer ${apiKey}")
	if [ $? -eq 0 ]; then
		#getting the attributes using bash methods only (python strongly recommended for JSON parsing)
		execSuccess "Your Order [${orderId}] has the following strings submitted" 
		translatedString=$(grep -oE '"translated_value":[^,]*,' <<< "${response}" | sed 's@"translated_value":@@')
		stringStatus=$(grep -oE '"status":"[^"]*"' <<< "${response}" | sed 's@"status":@@')
		#using the string status to evaluate if it was completed or not, can also be done the other way arround, if "complete" do this, else is not complete...
		if [[ "$stringStatus" == "\"in progress\"" || "$stringStatus" == "\"new\"" ]]; then
			execSuccess "The requested string [${stringId}] has not yet been translated, and its status is [${stringStatus}]."
		else
			execSuccess "The requested string [${stringId}] has been translated."
			printf "\n\t* Translated String: ${translatedString}\n"
		fi
	else
		execFailed "There was a problem while getting your string, please see bellow the response:"
		printf "\n\t\t${response}\n\n"
	fi
}

function getFile ()
{
	orderId=$1
	checkNotEmpty "${orderId}" "<OrderID>"
	fileId=$2
	checkNotEmpty "${fileId}" "<fileID>"
	#set a filename if needed, you can also use the "fileName" variable form the function "getFileInfo"
	fileName="$(pwd)/output.myacclaro"
	response=$(curl --location --request GET "https://${baseUrl}/api/v2/orders/${orderId}/files/${fileId}" -o ${fileName} 2>&1 \
		--header "Authorization: Bearer ${apiKey}")
	if [ $? -eq 0 ]; then
		
		if [ $? -eq 0 ]; then
			execSuccess "Your file with ID [${fileId}] has been downloaded here: ${fileName}" 
		else
			execFailed "failed while trying to save the file to the filesystem, please check output"
		fi
	else
		execFailed "There was a problem while getting your file, please see bellow the response:"
		echo ${response}
	fi
}

function getFileInfo ()
{
	orderId=$1
	checkNotEmpty "${orderId}" "<OrderID>"
	fileId=$2
	checkNotEmpty "${fileId}" "<fileID>"
	response=$(curl --location --request GET "https://${baseUrl}/api/v2/orders/${orderId}/files/${fileId}/status" 2>&1 \
		--header "Authorization: Bearer ${apiKey}")
	if [ $? -eq 0 ]; then
		#getting the attributes using bash methods only (python strongly recommended for JSON parsing)
		fileName=$(grep -oE '"filename":"[^"]*"' <<< "${response}" | sed 's@"filename":@@')
		fileStatus=$(grep -oE '"status":"[^"]*"' <<< "${response}" | sed 's@"status":@@')
		targetFileId=$(grep -oE '"targetfile":[0-9]*' <<< "${response}" | sed 's@"targetfile":@@')
		if [[ "$fileStatus" == "\"complete\"" ]]; then
			execSuccess "Your file [${fileName}] has been translated and has status: [${fileStatus}], please proceed to download the file using this ID: [${targetFileId}]" 
		else
			execSuccess "Your file [${fileName}] has yet not been translated and has status: [${fileStatus}]" 
		fi
	else
		execFailed "There was a problem while getting your file info, please see bellow the response:"
		echo ${response}
	fi
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
	baseUrl="$1"
	checkNotEmpty "${baseUrl}" "base URL"
	apiKey="$2"
	checkNotEmpty "${apiKey}" "API key"
	case "$3" in

		--help | -h)
			usage
			exit 0
		;;

		--version | -v)
			version
			exit 0
		;;

		--create-order | -co)
			createAnOrder "$4"
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
		
		--get-order-details | -god)
			getOrderDetails "$4"
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
		
		*)
			wrongUsage "Option/command not recognized. Please use --help to see what arguments are valid."
			exit 1
		;;
	esac
done

### List of functions
#createAnOrder
#postString
#sendFile
#getOrderDetails
#submitOrder
#getStringInfo
#getFile
#getFileInfo
