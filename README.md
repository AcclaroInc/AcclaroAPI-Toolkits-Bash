## Description
The purpose of this script is to facilitate our dev clients a seamless integration to [My Acclaro](https://www.acclaro.com/our-technology-platform/client-portal/) REST API.

The script is intended to be run on Bash 5.x or newer, older versions have not been tested, please bear this in mind when using it.

The script offers the possibility interacting with My Acclaro Portal and requesting Acclaro services without leaving your current environment.

**Got any questions?** Contact support@acclaro.com or file an [issue](https://github.com/AcclaroInc/AcclaroAPI-Toolkits-Bash/issues/new)

### My Acclaro API Features & Benefits
* RESTful endpoints to keep your content strings and files current across all locales
* Speed up market launches of new, multilingual content
* Replace manual workflows with automatic source content submission and target content imports via Webhooks
* Integrate with Acclaro's CMS plugins and connectors for WordPress, Drupal, Craft CMS, Contentful and Adobe Experience Manager (AEM)  - [learn more](https://www.acclaro.com/our-technology-platform/cms-connectors/)
* Access API order data in the My Acclaro portal
### Links & Downloads
* [Postman Acclaro API Endpoint Collection](https://documenter.getpostman.com/view/1843079/TzRUBT5g)
* SDKs for JavaScript & PHP coming soon
### Next Steps
* Read about our API [Case Studies](https://developers.acclaro.com/developers/devhub-case-studies)
* Review the [API Reference Guide](https://developers.acclaro.com/developers/apireference-restful)
* Watch our API Console Demo and other Technology [Videos](https://developers.acclaro.com/developers/devhub-videos)
* [Contact us](https://www.acclaro.com/solutions/content-connection-request/) for access to the My Acclaro sandbox and an API token

## Usage
### Instructions
1. Download the script from GitHub or clone our repository in your workstation/server
2. Run `./myacclaro.sh --help` for more info

Additionally, you may check the basic usage instructions in our wiki page [here](wiki/Basic-Usage).

### Dependencies
The script will check that `curl` and `jq` are installed. 
#### cURL
Necessary to hit the REST endpoint. More info about cURL [here](https://curl.se/)

##### Installing cURL in your server/workstation:

###### Debian/Ubuntu
```sudo apt install curl```
###### Redhat/CentOS/fedora 
```sudo yum install curl```

#### jq
Necessary to parse and format JSON payloads in Bash. More info about jq [here](https://stedolan.github.io/jq/)

##### Installing jq in your server/workstation:

###### Debian/Ubuntu
```sudo apt install jq```
###### Redhat/CentOS/fedora 
```sudo yum install jq```
