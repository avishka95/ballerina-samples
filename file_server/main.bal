import ballerina/http;
import ballerina/io;
import ballerina/mime;
import ballerina/file;
// import ballerina/lang.array;
import ballerina/uuid;

http:Unauthorized unauthorized = {
    body:{
        success: "false",
        message: "Invalid request"
    }
};

map<string|string[]> headers = {
    "Access-Control-Allow-Headers": "authorization,Access-Control-Allow-Origin,Content-Type,SOAPAction,Authorization",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET"
};

configurable string baseDirectory = ?;
configurable int PORT = ?;

@http:ServiceConfig {cors: {
        allowOrigins: ["*"],
        allowCredentials: false,
        allowHeaders: ["*"],
        maxAge: 84900
    }}
service /files on new http:Listener(PORT) {
    resource function get image/[string fileName](@http:Header string apiKey) returns http:Response| http:Unauthorized | http:NotFound |error {
        JWTRecord|error validation = jwtValidator(apiKey);
        if(validation is JWTRecord){
            boolean|error fileExists = file:test(baseDirectory + fileName, file:EXISTS);
            if(fileExists is error || !fileExists){
                http:NotFound notFoundResponse = {body: "Image not found!"};
                return notFoundResponse;
            }

            //validate request here, return if unahthorized.
            http:Response outResponse = new;
            outResponse.setETag(fileName);
            outResponse.setHeader("Cache-Control", "max-age=86400, public");
            outResponse.setFileAsPayload(baseDirectory + fileName, mime:IMAGE_JPEG);
            return outResponse;
        } else {
            return unauthorized;
        }
    }

    resource function post imageUpload(@http:Header string apiKey, http:Request request) returns http:Ok| http:Unauthorized |error? {
        JWTRecord|error validation = jwtValidator(apiKey);
        if(validation is JWTRecord){
            string uuidString = uuid:createType4AsString();
            stream<byte[], io:Error?> streamer = check request.getByteStream();
            string fileName = uuidString + ".jpg";
            check io:fileWriteBlocksFromStream(baseDirectory + fileName, streamer);
            http:Ok okResponse = {
                body: {
                    "success": true,
                    "message": "Successfully uploaded!",
                    "data": fileName
                },
                headers: headers
            };

            return okResponse;
        } else {
            return unauthorized;
        }
    }

    resource function delete imageDelete(@http:Header string apiKey, http:Request request) returns 
        http:Ok| http:Unauthorized |http:BadRequest|http:InternalServerError|error? {
        JWTRecord|error validation = jwtValidator(apiKey);
        if(validation is JWTRecord){
            string? fileName = request.getQueryParamValue("fileName");
            if (fileName is ()) {
                http:BadRequest badRequest = {body: "File name is missing in request body."};
                return badRequest;
            } else {
                error? err = file:remove(baseDirectory+fileName);
                if (err is error) {
                    http:InternalServerError errorResponse = {body: {
                        "success": false,
                        "message": "Error while deleting image.",
                        "error": err.message()
                    }};
                return errorResponse;
            } else {
                http:Ok errorResponse = {body: {
                        "success": true,
                        "message": "Successfully deleted image!"
                    }};
                    return errorResponse;
                }
            }
        } else {
            return unauthorized;
        }
    }
}
