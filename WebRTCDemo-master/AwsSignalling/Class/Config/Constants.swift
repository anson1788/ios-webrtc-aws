import Foundation
import AWSCognitoIdentityProvider
// Cognito constants
let awsCognitoUserPoolsSignInProviderKey = "UserPool"

let cognitoIdentityUserPoolRegion = AWSRegionType.APSoutheast1 //  <- REPLACE ME!
let cognitoIdentityUserPoolId = "ap-southeast-1_KfGarDRik"
let cognitoIdentityUserPoolAppClientId = "5s4btk1k24c5dn83i28b597v30"
let cognitoIdentityUserPoolAppClientSecret = "165kbvkgokd4keeemm2vhamhjg1le550qhdglkh7s6cfpetkm69q"
let cognitoIdentityPoolId = "ap-southeast-1:b86fdfc3-6e62-4306-9b01-2f7faa8a5a28"

// KinesisVideo constants
let awsKinesisVideoKey = "kinesisvideo"
let videoProtocols =  ["WSS", "HTTPS"]

// Connection constants
let connectAsMasterKey = "connect-as-master"
let connectAsViewerKey = "connect-as-viewer"

let masterRole = "MASTER"
let viewerRole = "VIEWER"
let connectAsViewClientId = "ConsumerViewer"

// AWSv4 signer constants
let signerAlgorithm = "AWS4-HMAC-SHA256"
let awsRequestTypeKey = "aws4_request"
let xAmzAlgorithm = "X-Amz-Algorithm"
let xAmzCredential = "X-Amz-Credential"
let xAmzDate = "X-Amz-Date"
let xAmzExpiresKey = "X-Amz-Expires"
let xAmzExpiresValue = "299"
let xAmzSecurityToken = "X-Amz-Security-Token"
let xAmzSignature = "X-Amz-Signature"
let xAmzSignedHeaders = "X-Amz-SignedHeaders"
let newlineDelimiter = "\n"
let slashDelimiter = "/"
let colonDelimiter = ":"
let plusDelimiter = "+"
let equalsDelimiter = "="
let ampersandDelimiter = "&"
let restMethod = "GET"
let utcDateFormatter = "yyyyMMdd'T'HHmmss'Z'"
let utcTimezone = "UTC"

let hostKey = "host"
let wssKey = "wss"

let plusEncoding = "%2B"
let equalsEncoding = "%3D"

