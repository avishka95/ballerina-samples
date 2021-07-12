import ballerina/http;
import ballerina/io;
import ballerina/mime;
import ballerina/file;
import ballerina/uuid;

map<string|string[]> headers = {
    "Access-Control-Allow-Headers": "authorization,Access-Control-Allow-Origin,Content-Type,SOAPAction,Authorization",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET"
};

http:Client clientEndpoint = check new ("http://localhost:9090");
string baseDirectory = "/Users/avishkaariyaratne/Desktop/github/ballerina-samples/file_server/tests/files/";

// service /'stream on new http:Listener(9090) {
// string uuid4String = uuid:createType4AsString();

//     resource function get fileupload() returns http:Response|error? {
//         http:Request request = new;

//         request.setFileAsPayload("./files/BallerinaLang.pdf",
//             contentType = mime:APPLICATION_PDF);

//         http:Response clientResponse =
//             check clientEndpoint->post("/stream/receiver", request);

//         return clientResponse;
//     }

//     resource function post receiver(http:Caller caller,
//                                     http:Request request) returns error? {

//         stream<byte[], io:Error?> streamer = check request.getByteStream();

//         check io:fileWriteBlocksFromStream(
//                                     "./files/ReceivedFile.pdf", streamer);
//         check streamer.close();
//         check caller->respond("File Received!");
//     }
// }
@http:ServiceConfig {cors: {
        allowOrigins: ["*"],
        allowCredentials: false,
        allowHeaders: ["*"],
        maxAge: 84900
    }}
service /files on new http:Listener(9090) {
    resource function get image/[string fileName]() returns http:Response|error {

        //validate request here, return if unahthorized.
        http:Response outResponse = new;
        // file:MetaData[] readDirResults = check file:readDir(baseDirectory);
        outResponse.setHeader(http:CACHE_CONTROL, "max-age=86400");
        // outResponse.setFileAsPayload("/Users/avishkaariyaratne/Desktop/github/ballerina-samples/file_server/tests/fileDownload/img.png", mime:IMAGE_PNG);
        outResponse.setFileAsPayload(baseDirectory + fileName, mime:IMAGE_JPEG);
        return outResponse;
    }

    resource function post fileUpload(http:Caller caller, http:Request request) returns http:Ok|error? {
        http:Request clientRequest = new;
        string uuidString = uuid:createType4AsString();
        stream<byte[], io:Error?> streamer = check request.getByteStream();
        string fileName = uuidString + ".jpg";

        check io:fileWriteBlocksFromStream("./files/" + fileName, streamer);
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

    resource function delete fileDelete(http:Caller caller, http:Request request, @http:Payload json payload) returns 
    http:Ok|http:BadRequest|http:InternalServerError|error? {
        string|error fileName = <string|error>payload.fileName;
        if (fileName is error) {
            http:BadRequest badRequest = {body: "File name is missing in request body."};
            return badRequest;
        } else {
            error? err = file:remove(fileName);
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

            }
        }

    }
}
