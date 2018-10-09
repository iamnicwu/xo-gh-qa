@isTest
global class PartnerAccountUpdateCalloutMock implements HttpCalloutMock {
 
    global HTTPResponse respond(HTTPRequest request) {
      HttpResponse response = new HttpResponse();
      response.setHeader('Content-Type', 'application/json');
      response.setBody('{"accountId":"2192345c-d0db-4bec-8bc1-a56e0173e0de","companyId":"08cf5c27-d577-4e1f-85a5-6c673032208d","errors":"testerrors"}');
      response.setStatusCode(200);
      return response; 
    }
}