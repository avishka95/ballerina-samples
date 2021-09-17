import ballerina/jwt;
import ballerina/cache;

configurable string DASHBOARDLISTING_JWT_ISSUER = ?;
configurable string DASHBOARDLISTING_JWT_AUDIENCE = ?;
configurable string DASHBOARDLISTING_JWKSENDPOINT = ?;
configurable int DASHBOARDLISTING_CACHE_CAPACITY = ?;
configurable float DASHBOARDLISTING_CACHE_EVICTIONFACTOR = ?;
decimal DASHBOARDLISTING_CACHE_DEFAULTMAXAGE = 3600;
decimal DASHBOARDLISTING_CACHE_CLEANUPINTERVAL = 1800;

public type JWTRecord record {|
    string email;
    string[] roles;
|};

public type JWTPayload record {
    string sub;
    string[] groups;
};

cache:Cache jwtCache = new({
        capacity: DASHBOARDLISTING_CACHE_CAPACITY,
        evictionFactor: DASHBOARDLISTING_CACHE_EVICTIONFACTOR,
        defaultMaxAge: DASHBOARDLISTING_CACHE_DEFAULTMAXAGE,
        cleanupInterval: DASHBOARDLISTING_CACHE_CLEANUPINTERVAL
    });

function setToJWTCache(string jwt, JWTRecord info) returns error?{
    check jwtCache.put(jwt, info);
}

function getFromJWTCache(string jwt) returns JWTRecord|error{
    return check <JWTRecord|error> jwtCache.get(jwt);
}

function jwtValidator(string jwt) returns JWTRecord|error {
    [jwt:Header, jwt:Payload] [header, payload] = check jwt:decode(jwt);
    JWTRecord|error fetchJWT = getFromJWTCache(jwt);
    if(fetchJWT is JWTRecord){
        return fetchJWT;
    } else {
        jwt:ValidatorConfig validatorConfig = {
            issuer: DASHBOARDLISTING_JWT_ISSUER,
            audience: DASHBOARDLISTING_JWT_AUDIENCE,
            clockSkew: 60,

            signatureConfig: {
                jwksConfig:  {url: DASHBOARDLISTING_JWKSENDPOINT}
            }
        };
        jwt:Payload validatedPayload = check jwt:validate(jwt, validatorConfig);
        JWTPayload|error jwtPayload = validatedPayload.cloneWithType(JWTPayload);
        string[] roles = [];
    
        string? email = validatedPayload?.sub;
        if(email is ()){
            return error("Could not fetch email from JWT");
        } else {
            JWTRecord returnInfo = {
                email: email,
                roles: roles
            };
            error? e = setToJWTCache(jwt,returnInfo);
            return returnInfo;
        }
    }
}