#!/bin/bash
##########################################
# Message to display for usage and help. #
##########################################
line=""
version="v0.0.1-alpha"
function usage()
{
	local txt=(
		""
		"myAcclaro Console for Querying myAcclaro's REST API."
		""
		"Commands:"
		"	login	Interactive login to myAcclaro API."
		"	logout	Clears the login information."
		"	help	Print help."
		"	version	Print version."
		"	create-order <name> [string]	Create an Order, if \"string\" added as parameter, then the Order takes strings rather than files."
		"	add-target-lang <orderID> <targetLang>	Adds a target language to an Order."
		"	post-string <orderID> <sourceString> <sourceLang> <targertLang>	Post a string."
		"	send-file <orderID> <sourceLang> <targertLang> <path_to_file>	Sends a source file."
		"	send-reference-file <orderID> <sourceLang> <targertLang> <path_to_reference_file>	Sends a reference file (e.g. a styleguide) for a particular language."
		"	get-order-details <orderID>	Gets Order details."
		"	get-all-order-details <orderID>	Gets All Order details."
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
		"myAcclaro>send-file 15554 en-us de-de ./mySourceFile.docx"
		""
		"Shell commands:"
		"	The following shell commands are available: ls, cd, pwd, grep, find, cat, less"
		""
	)
	printf "%s\n" "${txt[@]}"
} #usage

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

########################################
# Message to display when wrong usage. #
########################################
function wrongUsage()
{
	echo "command '${line}' not found"
} #wrongUsage

function checkNotEmpty()
{
	if [[ -z $1 ]]; then
		execFailed "The following mandatory argument [$2] is empty."
	fi
}
###################################
# Message to display for version. #
###################################
function versionDisp()
{
	echo "myAcclaro Console ${version}"
} #version

##################
# Checks if CSV output is requested
##################
function outputCsv()
{
	if [[ "$1" == "-csv" ]]; then
		csvOutput=true
	fi
}

function console()
{
	if [[ -z ${baseUrl} || -z ${apiKey} ]]; then
		echo -e -n "\e[33mmyAcclaro@${baseUrl}\e[39m> "
		read input
		eval line=(${input})
	else
		echo -e -n "\e[92mmyAcclaro@${baseUrl}\e[39m> "
		read input
		eval line=(${input})
	fi
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
	response=$(curl --silent --location --request POST "https://${baseUrl}/api/v2/orders" \
			--header 'Content-Type: multipart/form-data' \
			--header "Authorization: Bearer ${apiKey}" \
			--form "name=\"${orderName}\"" \
			${processType}
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
		echo ${response}
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
	response=$(curl --silent --location --request POST "https://${baseUrl}/api/v2/orders/${orderId}/strings" \
			--header "Authorization: Bearer ${apiKey}" \
			--header 'Content-Type: application/json' \
			--data-raw "{\"strings\":[{\"value\":\"${sourceString}\",\"target_lang\":[\"${targertLang}\"],\"source_lang\": \"${sourceLang}\"}]}")
	if [ $? -eq 0 ] && [ "$(grep -oE '\"success\":[a-z]*' <<< \"${response}\" | sed 's@\"success\":@@')" = "true" ]; then
		#getting the string ID using bash methods only (python strongly recommended for JSON parsing)
		stringId=$(grep -oE '"string_id":[0-9]*' <<< "${response}" | sed 's@"string_id":@@')
		execSuccess "Your string has been posted to Order [${orderId}] and has String ID: [${stringId}]" 
	else
		execFailed "There was a problem while posting your string, please see bellow the response:"
		echo ${response}
		
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
	response=$(curl --silent --location --request POST "https://${baseUrl}/api/v2/orders/${orderId}/files" \
		--header 'Content-Type: multipart/form-data' \
		--header "Authorization: Bearer ${apiKey}" \
		--form "sourcelang=\"${sourceLang}\"" \
		--form "targetlang=\"${targetLang}\"" \
		--form "file=@\"${pathToSourceFile}\"")
	if [ $? -eq 0 ] && [ "$(grep -oE '\"success\":[a-z]*' <<< \"${response}\" | sed 's@\"success\":@@')" = "true" ]; then
		#getting the file ID using bash methods only (python strongly recommended for JSON parsing)
		fileId=$(grep -oE '"fileid":[0-9]*' <<< "${response}" | sed 's@"fileid":@@')
		execSuccess "Your file has been posted to Order [${orderId}] and has File ID: [${fileId}]" 
	else
		execFailed "There was a problem while sending your file, please see bellow the response:"
		echo ${response}
		
	fi
	resultFileId=${fileId}
} #sendFile

function getOrderDetails ()
{
	orderId=$1
	checkNotEmpty "${orderId}" "<OrderID>"
	response=$(curl --silent --location --request GET "https://${baseUrl}/api/v2/orders/${orderId}"  \
		--header "Authorization: Bearer ${apiKey}")
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
		echo ${response}
		
	fi
} #getOrderDetails

function getAllOrderDetails ()
{
	outputCsv $1
	response=$(curl --silent --location --request GET "https://${baseUrl}/api/v2/orders"  \
		--header "Authorization: Bearer ${apiKey}")
	if [ $? -eq 0 ] && [ "$(grep -oE '\"success\":[a-z]*' <<< \"${response}\" | sed 's@\"success\":@@')" = "true" ]; then
		if [ "${csvOutput}" = true ]; then
			echo ${response} | jq -r '.data[] | [.orderid, .name, .status, .process_type, .user.email, .duedate] | @csv' | awk -v FS="\t" 'BEGIN{print "\"Order ID\",\"Order Name\",\"Status\",\"Type\",\"Creator\",\"Due Date\""}{printf "%s\t%s\t%s%s\t%s\t%s\t%s",${line[0]},$1,$2,$3,$4,$5,ORS}'
		else
			execSuccess "Please see a list of Orders bellow" 
			echo ${response} | jq -r '["Order ID","Order Name","Status","Process Type","Creator","Due Date"], ["--------","----------","------","------------","-------","--------"], (.data[] | [.orderid, .name, .status, .process_type, .user.email, .duedate]) | @tsv' | column -ts $'\t'
		fi
	else
		execFailed "There was a problem while getting your Order, please see the response below:"
		echo ${response}
		
	fi
} #getOrderDetails

function submitOrder ()
{
	orderId=$1
	checkNotEmpty "${orderId}" "<OrderID>"
	response=$(curl --silent --location --request POST "https://${baseUrl}/api/v2/orders/${orderId}/submit"  \
		--header "Authorization: Bearer ${apiKey}")
	if [ $? -eq 0 ] && [ "$(grep -oE '\"success\":[a-z]*' <<< \"${response}\" | sed 's@\"success\":@@')" = "true" ]; then
		execSuccess "Your Order [${orderId}] has beeen submitted" 
	else
		execFailed "There was a problem while submitting your Order, please see the response below:"
		echo ${response}
		
	fi
} #submitOrder

function getStringInfo ()
{
	orderId=$1
	checkNotEmpty "${orderId}" "<OrderID>"
	stringId=$2
	checkNotEmpty "${stringId}" "<stringID>"
	response=$(curl --silent --location --request GET "https://${baseUrl}/api/v2/orders/${orderId}/strings/${stringId}"  \
		--header "Authorization: Bearer ${apiKey}")
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
		echo ${response}
		
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
		response=$(curl --silent --location --request GET -w "%{http_code}" "https://${baseUrl}/api/v2/orders/${orderId}/files/${fileId}" -o ${fileName}  \
		--header "Authorization: Bearer ${apiKey}")
	if [ ${response} -eq 200 ]; then
		writeFileTest=$(echo ${fileName} >${fileName}.test && rm ${fileName}.test)
		if [ $? -eq 0 ]; then
			execSuccess "Your file with ID [${fileId}] has been downloaded here: ${fileName}" 
		else
			execFailed "The system failed while trying to save the file, please check the error message"
			echo ${writeFile}
			
		fi
	else
		execFailed "There was a problem while getting your file, the status code is [${response}]"
		
	fi
} #getFile

function getFileInfo ()
{
	orderId=$1
	checkNotEmpty "${orderId}" "<OrderID>"
	fileId=$2
	checkNotEmpty "${fileId}" "<FileID>"
	response=$(curl --silent --location --request GET "https://${baseUrl}/api/v2/orders/${orderId}/files/${fileId}/status"  \
		--header "Authorization: Bearer ${apiKey}")
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
		echo ${response}
		
	fi
} #getFileInfo

function getComments ()
{
	orderId=$1
	checkNotEmpty "${orderId}" "<OrderID>"
	outputCsv $2
	response=$(curl --location --silent --request GET "https://${baseUrl}/api/v2/orders/${orderId}/comments" \
	--header "Authorization: Bearer ${apiKey}")
	if [ $? -eq 0 ] && [ "$(grep -oE '\"success\":[a-z]*' <<< \"${response}\" | sed 's@\"success\":@@')" = "true" ]; then
		if [ "${csvOutput}" = true ]; then
			echo ${response} | jq -r '.data[] | [.author, .timestamp, .comment] | @csv' | awk -v FS="\t" 'BEGIN{print "\"Author\",\"Creation Date\",\"Comment\""}{printf "%s\t%s\t%s%s",${line[0]},$1,$2,ORS}'	
		else
			execSuccess "Your Order [${orderId}] has comments, please see comments bellow:" 
			echo ${response} | jq -r '["Author","Timestamp","Comment"], ["------","---------","-------"], (.data[] | [.author, .timestamp, .comment] ) | @tsv' | column -ts $'\t'
		fi
	else
		execFailed "There was a problem while getting your comments"
		echo ${response}
		
	fi
} #getComments	

function setComment ()
{
	orderId=$1
	checkNotEmpty "${orderId}" "<OrderID>"
	commentLine=$2
	checkNotEmpty "${commentLine}" "<Comment>"
	response=$(curl --location --silent --request POST "https://${baseUrl}/api/v2/orders/${orderId}/comment" \
	--header "Authorization: Bearer ${apiKey}" \
	--data-urlencode "comment=${commentLine}")
	if [ $? -eq 0 ] && [ "$(grep -oE '\"success\":[a-z]*' <<< \"${response}\" | sed 's@\"success\":@@')" = "true" ]; then
		execSuccess "Your Order [${orderId}] has been added the following comment:"
		echo "	****** Comment Start ******"
		echo "	*    ${commentLine}"
		echo "	****** Comment End ******"
	else
		execFailed "There was a problem while posting your comment"
		echo ${response}
		
	fi
} #setComment

function requestQuote()
{
	orderId=$1
	checkNotEmpty "${orderId}" "<OrderID>"
	response=$(curl --location --silent --request GET "https://${baseUrl}/api/v2/orders/${orderId}/quote" \
	--header "Authorization: Bearer ${apiKey}")
	if [ $? -eq 0 ] && [ "$(grep -oE '\"success\":[a-z]*' <<< \"${response}\" | sed 's@\"success\":@@')" = "true" ]; then
		execSuccess "Quote succesfully requested for Order [${orderId}]" 
	else
		execFailed "There was a problem while requestiong your Quote for Order [${orderId}]"
		echo ${response}
		
	fi
}

function getQuoteDetails()
{
	orderId=$1
	checkNotEmpty "${orderId}" "<OrderID>"
	response=$(curl --location --silent --request GET "https://${baseUrl}/api/v2/orders/${orderId}/quote-details" \
	--header "Authorization: Bearer ${apiKey}")
	if [ $? -eq 0 ] && [ "$(grep -oE '\"success\":[a-z]*' <<< \"${response}\" | sed 's@\"success\":@@')" = "true" ]; then
		totalQuote=$(echo ${response} | jq -r .data.total)
		#arrayLength=$(echo ${response} | jq -r '(.data.lines | length)')
		#echo ${arrayLength}
		execSuccess "Quote details for Order [${orderId}] are bellow:"
		echo ${response} | jq -r '["Description","Quantity","Unit Price","Subtotal"], ["-----------","--------","----------","--------"], (.data.lines[] | [.description, .quantity, "$"+.unitprice, "$"+.price])  | @tsv' | column -ts $'\t'
		echo "** TOTAL: \$${totalQuote}" 
	else
		execFailed "There was a problem while getting your Quote"
		echo ${response}
		
	fi
}

function quoteWorkflow()
{
	orderId=$1
	checkNotEmpty "${orderId}" "<OrderID>"
	checkNotEmpty "$1" "<--approve/--decline>"
	case "$1" in
		--approve | -a)
			quoteDecision="quote-approve"
			verbPresCont="approving"
			verbPast="approved"
			#response=$(curl --location --silent --request POST "https://${baseUrl}/api/v2/orders/${orderId}/quote-approve" \
			#--header "Authorization: Bearer ${apiKey}")
			#if [ $? -eq 0 ] && [ "$(grep -oE '\"success\":[a-z]*' <<< \"${response}\" | sed 's@\"success\":@@')" = "true" ]; then
			#	execSuccess "The Quote for Order [${orderId}] has been succesfully approved"
			#else
			#	execFailed "There was a problem while approving your Quote for Order [${orderId}]"
			#	echo ${response}
			#	
			#fi
		;;

		--decline | -d)
			quoteDecision="quote-decline"
			verbPresCont="declining"
			verbPast="declined"
			#response=$(curl --location --silent --request POST "https://${baseUrl}/api/v2/orders/${orderId}/quote-decline" \
			#--header "Authorization: Bearer ${apiKey}")
			#if [ $? -eq 0 ] && [ "$(grep -oE '\"success\":[a-z]*' <<< \"${response}\" | sed 's@\"success\":@@')" = "true" ]; then
			#	execSuccess "The Quote for Order [${orderId}] has been succesfully declined"
			#else
			#	execFailed "There was a problem while declining your Quote for Order [${orderId}]"
			#	echo ${response}
			#	
			#fi
		;;
		
		*)
			execFailed "You should either decline or approve the quote [--approve/--decline]"
			
		;;

	esac

		response=$(curl --location --silent --request POST "https://${baseUrl}/api/v2/orders/${orderId}/${quoteDecision}" \
		--header "Authorization: Bearer ${apiKey}")
		if [ $? -eq 0 ] && [ "$(grep -oE '\"success\":[a-z]*' <<< \"${response}\" | sed 's@\"success\":@@')" = "true" ]; then
			execSuccess "The Quote for Order [${orderId}] has been succesfully ${verbPast}"
		else
			execFailed "There was a problem while ${verbPresCont} your Quote for Order [${orderId}]"
			echo ${response}
			
		fi
		
#	if [[ quoteApprovalStatus == "--approve" || quoteApprovalStatus == "-a" ]]
#		response=$(curl --location --silent --request GET "https://${baseUrl}/api/v2/orders/${orderId}/quote-approve" \
#		--header "Authorization: Bearer ${apiKey}")
#	elif [[ quoteApprovalStatus == "--decline" || quoteApprovalStatus == "-d" ]]
#		response=$(curl --location --silent --request GET "https://${baseUrl}/api/v2/orders/${orderId}/quote-decline" \
#		--header "Authorization: Bearer ${apiKey}")
	
}

function addTargetToOrder()
{
	orderId=${line[0]}
	checkNotEmpty "${orderId}" "<OrderID>"
	targetLang=$1
	checkNotEmpty "${targetLang}" "<targetLang>"
	response=$(curl --location --silent --request POST "https://${baseUrl}/api/v2/orders/${orderId}/language" \
	--header "Authorization: Bearer ${apiKey}" \
	--data-urlencode "targetlang=${targetLang}")
	if [ $? -eq 0 ] && [ "$(grep -oE '\"success\":[a-z]*' <<< \"${response}\" | sed 's@\"success\":@@')" = "true" ]; then
		execSuccess "The following target language: [${targetLang}] has been succesfully added to the Order [${orderId}]"
	else
		execFailed "There was a problem while adding the target lang [${targetLang}] to Order [${orderId}]"
		echo ${response}
		
	fi
}

#function addSourceAndTargetToOrder()
#{
#	#stuff
#}

function sendReferenceFile()
{
	orderId=${line[0]}
	checkNotEmpty "${orderId}" "<OrderID>"
	sourceLang=$1
	checkNotEmpty "${sourceLang}" "<sourceLang>"
	targetLang=$2
	checkNotEmpty "${targetLang}" "<targertLang>"
	pathToReferenceFile=$3
	checkNotEmpty "${pathToReferenceFile}" "<path_to_reference_file>"
	response=$(curl --silent --location --request POST "https://${baseUrl}/api/v2/orders/${orderId}/reference-file" \
	--header 'Content-Type: multipart/form-data' \
	--header "Authorization: Bearer ${apiKey}" \
	--form "sourcelang=\"${sourceLang}\"" \
	--form "targetlang=\"${targetLang}\"" \
	--form "file=@\"${pathToReferenceFile}\"")
	if [ $? -eq 0 ] && [ "$(grep -oE '\"success\":[a-z]*' <<< \"${response}\" | sed 's@\"success\":@@')" = "true" ]; then
		#getting the file ID using bash methods only (python strongly recommended for JSON parsing)
		fileId=$(grep -oE '"fileid":[0-9]*' <<< "${response}" | sed 's@"fileid":@@')
		execSuccess "Your reference file has been posted to Order [${orderId}] for the following target lang(s): [${targetLang}]" 
	else
		execFailed "There was a problem while sending your reference file, please see bellow the response:"
		echo ${response}
		
	fi
}

function logIn()
{
	if [[ -z ${baseUrl} || -z ${apiKey} ]]; then
		echo -e -n "Please enter the myAcclaro domain: "
		read -a domain
		baseUrl=${domain}
		echo -e -n "Please paste your API key here: "
		read -a key
		apiKey=${key}
#		read -p "Shall I set these as environmental variables? [Y/n] " -n 1 -r
#		if [[ $REPLY =~ ^[Yy]$ ]]; then
#			set -a
#			baseUrl=${domain}
#			apiKey=${key}
#			echo ""
#			echo "Your API key and your domain have been set as environmental variables."
#			set +a
#		fi
	else
		echo "you are already logged in into [${baseUrl}] using the following API key:"
		echo "[${apiKey}]"
	fi
}

function logOut()
{
	baseUrl=""
	apiKey=""
	echo "You have been successfully logged out."
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

################
###          ###
###   BODY   ###
###          ###
################
#localBin=$(find /bin -type f | awk -F/ '{print $NF}' | tr "\n" "|" | sed 's@|$@@')
headerGreeting
console
while [ "${line[0]}" != "exit" ]
do 
	case "${line[0]}" in
	
		ls)
			${line[@]}
		;;
		cd)
			${line[@]}
		;;
		
		pwd)
			${line[@]}
		;;
		
		grep)
			${line[@]}
		;;
		
		find)
			${line[@]}
		;;
		
		cat)
			${line[@]}
		;;
		
		less)
			${line[@]}
		;;
		
		help)
			usage
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
			wrongUsage
		;;
		
		
	esac
	console
done
exit 0
