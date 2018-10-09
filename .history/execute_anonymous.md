2018-09-29 14:56:29
```java
Http http = new Http();
HttpRequest req = new HttpRequest();
req.setTimeout(120000); 
req.setMethod('GET');
req.setHeader('Content-Type', 'application/json');
req.setHeader('Accept', 'application/json');
req.setEndpoint('callout:Zuora_REST_API' + '/rest' + '/v1/connections');

try {   
    HTTPResponse res = http.send(req);
    System.debug(res.toString());
    System.debug('STATUS:'+res.getStatus());
    System.debug('STATUS_CODE:'+res.getStatusCode());
    System.debug(res.getBody());
}
// this catches both callout exceptions and process exceptions
catch (Exception e) {
	if (!Test.isRunningTest()) {
		// throw new tcvException(e.getMessage(), e);
	}
}


```

2018-09-29 14:58:54
```java
Http http = new Http();
HttpRequest req = new HttpRequest();
req.setTimeout(1200); 
req.setMethod('GET');
req.setHeader('Content-Type', 'application/json');
req.setHeader('Accept', 'application/json');
req.setEndpoint('callout:Zuora_REST_API');

try {   
    HTTPResponse res = http.send(req);
    System.debug(res.toString());
    System.debug('STATUS:'+res.getStatus());
    System.debug('STATUS_CODE:'+res.getStatusCode());
    System.debug(res.getBody());
}
// this catches both callout exceptions and process exceptions
catch (Exception e) {
	if (!Test.isRunningTest()) {
		// throw new tcvException(e.getMessage(), e);
	}
}


```

2018-09-29 14:59:50
```java
Http http = new Http();
HttpRequest req = new HttpRequest();
req.setTimeout(1200); 
req.setMethod('GET');
req.setHeader('Content-Type', 'application/json');
req.setHeader('Accept', 'application/json');
req.setEndpoint('callout:Zuora_REST_API'+'/apps');

try {   
    HTTPResponse res = http.send(req);
    System.debug(res.toString());
    System.debug('STATUS:'+res.getStatus());
    System.debug('STATUS_CODE:'+res.getStatusCode());
    System.debug(res.getBody());
}
// this catches both callout exceptions and process exceptions
catch (Exception e) {
	if (!Test.isRunningTest()) {
		// throw new tcvException(e.getMessage(), e);
	}
}


```

2018-10-02 07:49:48
```java
Zuora.ZApi zApiInstance = new Zuora.ZApi();
Zuora.zApi.LoginResult loginResult;
loginResult = zApiInstance.zlogin();

System.debug(LoggingLevel.INFO, '*** loginResult: ' + loginResult);
```

