public without sharing class RestCalloutUtility {

  // CSP-2651 Partners FulFillment JSON Token Functionality
  // create a generic Rest callout class to centralize and handle different partners rest callout

  // generic callout method
  public static HttpRequest restCallout(String method, String endpoint, String body, Integer timeout){

    HttpRequest req = new HttpRequest();
    req.setTimeout(timeout);
    req.setEndpoint(endpoint);
    req.setMethod(method);
    req.setBody(body);

    req.setHeader('Content-Type','application/json');

    String token = Label.partnersToken;
    // Check if the partners token not exist, and we will not put the authorization into header
    if(String.isNotBlank(token)){
      req.setHeader('Authorization','Bearer '+ token.trim());
    }

    System.debug(LoggingLevel.INFO, '*** req: ' + req);
    return req;
  }

  // partners fulfillment callout with the same endpoint and specific path
  public static HttpRequest fulfillmentCallout(String body){
    return restCallout('POST','callout:Partners_new_endpoint', body, 12000);
  }

  // partners account update callout with the same endpoint and specific path
  public static HttpRequest accountUpdateCallout(String body){
    return restCallout('PUT','callout:partners_account_update', body, 12000);
  }
}