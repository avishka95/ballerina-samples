# ballerina-samples
Ballerina samples


Validating JWT using JWKS endpoint

```
import ballerina/http;

import ballerina/jwt;

  

configurable  string jwtIssuer =  ?;

configurable  string jwtAudience =  ?;

configurable  string jwksEndpoint =  ?;

  

service  /  on  new http:Listener(8090) {

	resource  function  get  validate(@http:Header {name: "jwt"} string jwt) returns  http:Ok  |  http:InternalServerError  |  error? {

		[jwt:Header, jwt:Payload] [header, payload] =  check jwt:decode(jwt);

		jwt:ValidatorConfig validatorConfig = {
			issuer: jwtIssuer,
			audience: jwtAudience,
			clockSkew: 60,
  
			signatureConfig: {
				jwksConfig: {url: jwksEndpoint}
			}
		};

		jwt:Payload|error validatedPayload = jwt:validate(jwt, validatorConfig);

		string|error stringHeader = header.toString();
		string|error stringPayload = payload.toString();

		if(stringPayload is  string  && stringHeader is  string  && validatedPayload is jwt:Payload){

			http:Ok okResponse = {body: {
				"success": true,
				"message": {
					"header": stringHeader,
					"payload": stringPayload,
					"isValid": true
				}
			}};

			return okResponse;

		} else  if(stringPayload is  error  || stringHeader is  error) {
			http:InternalServerError|error errorResponse = {body: {
				"success": false,
				"message": "Error while decoding payload"
			}};

			return errorResponse;

		} else  if(validatedPayload is  error) {
			http:InternalServerError|error errorResponse = {body: {
				"success": false,
				"message": "Error while validating payload",
				"error" : validatedPayload.message()

		}};

		return errorResponse;

		} else {
			//Should not come here
			
			http:InternalServerError|error errorResponse = {body: {
				"success": false,
				"message": "Unexpected error",

			}};

			return errorResponse;
		}
	}
}
```