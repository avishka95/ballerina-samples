import ballerina/http;
import ballerina/io;
import ballerina/mime;
import ballerina/file;
// import ballerina/lang.array;
import ballerina/uuid;

map<string|string[]> headers = {
    "Access-Control-Allow-Headers": "authorization,Access-Control-Allow-Origin,Content-Type,SOAPAction,Authorization",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET"
};

http:Client clientEndpoint = check new ("http://localhost:9090");
string baseDirectory = "/Users/avishkaariyaratne/Desktop/github/ballerina-samples/file_server/tests/files/";

@http:ServiceConfig {cors: {
        allowOrigins: ["*"],
        allowCredentials: false,
        allowHeaders: ["*"],
        maxAge: 84900
    }}
service /files on new http:Listener(9090) {
    resource function get image/[string fileName]() returns http:Response| http:NotFound |error {
        boolean|error fileExists = file:test(baseDirectory + fileName, file:EXISTS);
        if(fileExists is error || !fileExists){
            http:NotFound notFoundResponse = {body: "Image not found!"};
            return notFoundResponse;
        }

        //validate request here, return if unahthorized.
        http:Response outResponse = new;
        // file:MetaData[] readDirResults = check file:readDir(baseDirectory);
        outResponse.setHeader("access-control-allow-", "*");
        outResponse.setHeader(http:CACHE_CONTROL, "max-age=86400");
        // outResponse.setFileAsPayload("/Users/avishkaariyaratne/Desktop/github/ballerina-samples/file_server/tests/fileDownload/img.png", mime:IMAGE_PNG);
        outResponse.setFileAsPayload(baseDirectory + fileName, mime:IMAGE_JPEG);
        return outResponse;
    }

    resource function post imageUpload(http:Request request) returns http:Ok|error? {
        http:Request clientRequest = new;
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

    }

    resource function delete imageDelete(http:Request request) returns 
    http:Ok|http:BadRequest|http:InternalServerError|error? {
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

    }
}
