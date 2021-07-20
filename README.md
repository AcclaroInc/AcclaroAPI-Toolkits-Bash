# AcclaroAPI-Toolkits-Bash
## Scripts
### List
* `myAcclaro-API-sample.sh` - API wrapped up in bash functions using cURL.
### How To
The script is designed to create a translation Order, add files/strings to it, submit the order and then retrieve the translated strings/files once complete. To do so, the Orders, Files and Strings are assigned IDs that are used during the process.
### Files
#### 1. Creating an Order for Files
The first thing we need to do is to create an Order so that we have a container which will later be used to bill for the services provided. Once the Order is created the script will respond with the Order ID which will be needed for the following steps.
##### Option
```
--create-order, -co <name> [string]     Create an Order, if "string" added as parameter, then the Order takes strings rather than files.
```
##### Example
```
myAcclaro-API-sample.sh "apisandbox.acclaro.com" "pYXQiOjE2MjYyODYxOTIsInN1YiI6..." --create-order "My Order Name goes here"
```
#### 2. Uploading files to the Order
Once we have an Order opened, we will start uploading files to the Order, determining to which Order, and Source and Target language(s) for each file uploaded. We will use 4-letter ISO codes for the languages, e.g. English (United States) = en-us. Each uploaded file will be assigned a File ID which will be needed on later steps. 
##### Option
```
--send-file, -sf <orderID> <sourceLang> <targertLang> <Path_to_file>    Sends a source file.
```
##### Example
```
myAcclaro-API-sample.sh "apisandbox.acclaro.com" "pYXQiOjE2MjYyODYxOTIsInN1YiI6..." --send-file 75469 "en-us" "de-de" ../source/myfile.docx
```
#### 3. Submitting the Order for preparation
As soon as we have finished uploading all the files that require translation, we will proceed to submit the Order for preparation. At this point Acclaro will analyze the content and will prepare it for localization. 
##### Option
```
--submit-order, -so <orderID>   Submits the Order for preparation.
```
##### Example
```
myAcclaro-API-sample.sh "apisandbox.acclaro.com" "pYXQiOjE2MjYyODYxOTIsInN1YiI6..." --submit-order 75469
```
#### 4. Checking the Order status
We will need to monitor the Order until it gets status complete, in which case we will be able to obtain the translated files. 
##### Option
```
--get-order-details, -god <orderID>     Gets Order details.
```
##### Example
```
myAcclaro-API-sample.sh "apisandbox.acclaro.com" "pYXQiOjE2MjYyODYxOTIsInN1YiI6..." --get-order-details 75469
```
#### 5. Checking the File status
We will need to monitor the File status. Once the file is translated, we will be offered a translated File ID which will be used to download it. 
##### Option
```
--get-file-info, -gfi <orderID> <fileID>        Gets the information of a file based on its ID.
```
##### Example
```
myAcclaro-API-sample.sh "apisandbox.acclaro.com" "pYXQiOjE2MjYyODYxOTIsInN1YiI6..." --get-file-info 75469 659852
```
#### 6. Downloading the Translated File
Once the source file status is complete or the Order is complete (which means all source files are completed), we will obtain from the step above a translated file ID which will be used in this step to download the translated file.
##### Option
```
--get-file, -gf <orderID> <fileID>      Gets a file based on its ID.
```
##### Example
```
myAcclaro-API-sample.sh "apisandbox.acclaro.com" "pYXQiOjE2MjYyODYxOTIsInN1YiI6..." --get-file 75469 659858
```
### Strings
#### 1. Creating an Order for Strings
##### Option
`--create-order, -co <name> [string]     Create an Order, if "string" added as parameter, then the Order takes strings rather than files.`
##### Sample
`myAcclaro-API-sample.sh "apisandbox.acclaro.com" "pYXQiOjE2MjYyODYxOTIsInN1YiI6..." --create-order "My Order Name goes here" string`
#### 2. Uploading Strings to the Order
Once we have an Order opened, we will start uploading Strings to the Order, determining to which Order, and Source and Target language(s) for each file uploaded. We will use 4-letter ISO codes for the languages, e.g. English (United States) = en-us. Each uploaded String will be assigned a String ID which will be needed on later steps. 
##### Option
```
--post-string, -ps <orderID> <sourceString> <sourceLang> <targertLang>  Post a string.
```
##### Example
```
myAcclaro-API-sample.sh "apisandbox.acclaro.com" "pYXQiOjE2MjYyODYxOTIsInN1YiI6..." --post-string 75469 "This is my test string" en-us de-de
```
#### 3. Submitting the Order for preparation
As soon as we have finished uploading all the files that require translation, we will proceed to submit the Order for preparation. At this point Acclaro will analyze the content and will prepare it for localization. 
##### Option
```
--submit-order, -so <orderID>   Submits the Order for preparation.
```
##### Example
```
myAcclaro-API-sample.sh "apisandbox.acclaro.com" "pYXQiOjE2MjYyODYxOTIsInN1YiI6..." --submit-order 75469
```
#### 4. Checking the Order status
We will need to monitor the Order until it gets status complete, in which case we will be able to obtain the translated files. 
##### Option
```
--get-order-details, -god <orderID>     Gets Order details.
```
##### Example
```
myAcclaro-API-sample.sh "apisandbox.acclaro.com" "pYXQiOjE2MjYyODYxOTIsInN1YiI6..." --get-order-details 75469
```
#### 5. Checking the String status
We will need to monitor the String status. Once the string is translated, the response will carry the translated string in the output. 
##### Option
```
--get-string-info, -gsi <orderID> <stringID>	Gets the String information and the translated string once completed.
```
##### Example
```
myAcclaro-API-sample.sh "apisandbox.acclaro.com" "pYXQiOjE2MjYyODYxOTIsInN1YiI6..." --get-string-info 75469 245
```
