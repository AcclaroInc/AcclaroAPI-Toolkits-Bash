#!/bin/bash

#######################################
# Function to handle success messages #
# call as:                            #
#   execSuccess ${message}            #
#######################################
function execSuccess()
{
	echo "$(date +%F\ %T) :: [SUCCESS] - $1"
} #execSuccess


######################################
# Function to handle failed messages #
# call as:                           #
#   execFailed ${message}            #
######################################
function execFailed()
{
	echo "$(date +%F\ %T) :: [FAIL] - $1"
} #execFailed


function createAnOrder()
{
	response=$(curl --location --request POST "https://${baseUrl}/api/v2/orders" 2>&1\
			--header 'Content-Type: multipart/form-data' \
			--header "Authorization: Bearer ${apiKey}" \
			--form "name=\"${orderName}\"" \
			--form "duedate=\"${dueDate}\"" \
			--form "process_type=\"${processType}\"")
	if [ $? -eq 0 ]; then
		#getting the Order ID using bash methods only (python strongly recommended for JSON parsing)
		orderId=$(grep -oE '"orderid":[0-9]*' <<< "${response}" | sed 's@"orderid":@@')
		execSuccess "Your order has been created and has id [${orderId}]" 
	else
		execFailed "There was a problem while creating your Order, please see bellow the response:"
		printf "\n\t\t${response}"
	fi
	return ${orderId}
} #createAnOrder

function postString ()
{
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
					\"source_lang\": \"${sourceLang}\",
					\"key\": \"${sourceStringKey}\",
					\"callback\": \"${stringCallbackUrl}\"
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
	return ${stringId}
}

function sendFile ()
{
	response=$(curl --location --request POST "https://${baseUrl}/api/v2/orders/${orderId}/files" 2>&1\
		--header 'Content-Type: multipart/form-data' \
		--header "Authorization: Bearer ${apiKey}" \
		--form "sourcelang=\"${sourceLang}\"" \
		--form "targetlang=\"${targetLang}\"" \
		--form "file=@\"${pathToSourceFile}\"")
	if [ $? -eq 0 ]; then
		#getting the file ID using bash methods only (python strongly recommended for JSON parsing)
		fileId=$(grep -oE '"fileid":[0-9]*' <<< "${response}" | sed 's@"fileid":@@')
		execSuccess "Your string has been posted to Order [${orderId}] and has String ID: [${stringId}]" 
	else
		execFailed "There was a problem while sending your file, please see bellow the response:"
		printf "\n\t\t${response}\n\n"
	fi
	return ${fileId}
}

function getOrderDetails ()
{
	response=$(curl --location --request GET "https://${baseUrl}/api/v2/orders/${orderId}" 2>&1 \
		--header "Authorization: Bearer ${apiKey}")
	if [ $? -eq 0 ]; then
		#getting the attributes using bash methods only (python strongly recommended for JSON parsing)
		orderName=$(grep -oE '"name":"[^"]*"' <<< "${response}" | sed 's@"name":@@')
		orderStatus=$(grep -oE '"status":"[^"]*"' <<< "${response}" | sed 's@"status":@@')
		processType=$(grep -oE '"process_type":"[^"]*"' <<< "${response}" | sed 's@"process_type":@@')
		dueDate=$(grep -oE '"duedate":"[^"]*"' <<< "${response}" | sed 's@"duedate":@@') #does not work, check it!
		execSuccess "Your Order [${orderId}] has the following attributes:" 
		printf "\n\t\t* Order ID: ${orderId}\n\t\t* Order Name: ${orderName}\n\t\t* Status: ${orderStatus}\n\t\t* Process Type: ${processType}\n\t\t* Due date: ${dueDate}\n\n"
	else
		execFailed "There was a problem while getting your Order, please see bellow the response:"
		printf "\n\t\t${response}\n\n"
	fi
}

function submitOrder ()
{
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
	response=$(curl --location --request GET "https://${baseUrl}/api/v2/orders/${orderId}/files/${fileId}" \
		--header "Authorization: Bearer ${apiKey}")
	if [ $? -eq 0 ]; then
		#set a filename if needed, you can also use the fileName form the function "getFileInfo"
		fileName=output.myacclaro
		echo ${response} > ./${fileName}
		if [ $? -eq 0 ]; then
			execSuccess "Your file with ID [${fileId}] has been downloaded here" 
		else
			execFailed "failed while trying to save the file to the filesystem, please check output"
		fi
	else
		execFailed "There was a problem while getting your file, please see bellow the response:"
		printf "\n\t\t${response}\n\n"
	fi
}

function getFileInfo ()
{
	response=$(curl --location --request GET "https://${baseUrl}/api/v2/orders/${orderId}/files/${fileId}/status" 2>&1 \
		--header 'Authorization: Bearer ${apiKey}')
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
		printf "\n\t\t${response}\n\n"
	fi
}


### List of functions
#createAnOrder
#postString
#sendFile
#getOrderDetails
#submitOrder
#getStringInfo
#getFile
#getFileInfo
