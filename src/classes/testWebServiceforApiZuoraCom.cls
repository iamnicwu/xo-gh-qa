@isTest
global class testWebServiceforApiZuoraCom{
    global class Webquery implements WebServiceMock {  
        apiZuoraCom.QueryResult QueryResult = new apiZuoraCom.QueryResult(); 
        global void doInvoke(  
            Object stub,  
            Object request,  
            Map<string, object> response,  
            String endpoint,  
            String soapAction,  
            String requestName,  
            String responseNS,  
            String responseName,  
            String responseType){  
        apiZuoraCom.queryResponse_element respElement = new apiZuoraCom.queryResponse_element();  
        respElement.result = QueryResult;  
        response.put('response_x', respElement);   
        }  
    }
    
    global class WebsubscriptionQuery implements WebServiceMock{  
        apiZuoraCom.SubscriptionQueryResult SubscriptionQueryResult = new apiZuoraCom.SubscriptionQueryResult();
        global void doInvoke(  
            Object stub,  
            Object request,  
            Map<string, object> response,  
            String endpoint,  
            String soapAction,  
            String requestName,  
            String responseNS,  
            String responseName,  
            String responseType){  
        apiZuoraCom.subscriptionQueryResponse_element respElement = new apiZuoraCom.subscriptionQueryResponse_element();  
        respElement.result = SubscriptionQueryResult ;  
        response.put('response_x', respElement);   
        }  
    } 
    
    global class WebamendmentQuery implements WebServiceMock{  
        apiZuoraCom.AmendmentQueryResult AmendmentQueryResult = new apiZuoraCom.AmendmentQueryResult();
        global void doInvoke(  
            Object stub,  
            Object request,  
            Map<string, object> response,  
            String endpoint,  
            String soapAction,  
            String requestName,  
            String responseNS,  
            String responseName,  
            String responseType){  
        apiZuoraCom.amendmentQueryResponse_element respElement = new apiZuoraCom.amendmentQueryResponse_element();  
        respElement.result = AmendmentQueryResult;  
        response.put('response_x', respElement);   
        }  
    }
    
    global class Webgenerate implements WebServiceMock{  
        List<apiZuoraCom.SaveResult> SaveResults = new List<apiZuoraCom.SaveResult>();
        global void doInvoke(  
            Object stub,  
            Object request,  
            Map<string, object> response,  
            String endpoint,  
            String soapAction,  
            String requestName,  
            String responseNS,  
            String responseName,  
            String responseType){  
        apiZuoraCom.generateResponse_element respElement = new apiZuoraCom.generateResponse_element();  
        respElement.result = SaveResults;  
        response.put('response_x', respElement);   
        }  
    }
    
    global class Websubscribe implements WebServiceMock{  
        List<apiZuoraCom.SubscribeResult> SubscribeResults = new List<apiZuoraCom.SubscribeResult>();
        global void doInvoke(  
            Object stub,  
            Object request,  
            Map<string, object> response,  
            String endpoint,  
            String soapAction,  
            String requestName,  
            String responseNS,  
            String responseName,  
            String responseType){  
        apiZuoraCom.subscribeResponse_element respElement = new apiZuoraCom.subscribeResponse_element();  
        respElement.result = SubscribeResults ;  
        response.put('response_x', respElement);   
        }  
    }
    
    global class WebqueryMore implements WebServiceMock{  
        apiZuoraCom.QueryResult QueryResult = new apiZuoraCom.QueryResult();
        global void doInvoke(  
            Object stub,  
            Object request,  
            Map<string, object> response,  
            String endpoint,  
            String soapAction,  
            String requestName,  
            String responseNS,  
            String responseName,  
            String responseType){  
        apiZuoraCom.queryMoreResponse_element respElement = new apiZuoraCom.queryMoreResponse_element();  
        respElement.result = QueryResult;  
        response.put('response_x', respElement);   
        }  
    }
    
    global class Webexecute implements WebServiceMock{  
        List<apiZuoraCom.ExecuteResult> ExecuteResults = new List<apiZuoraCom.ExecuteResult>();
        global void doInvoke(  
            Object stub,  
            Object request,  
            Map<string, object> response,  
            String endpoint,  
            String soapAction,  
            String requestName,  
            String responseNS,  
            String responseName,  
            String responseType){  
        apiZuoraCom.executeResponse_element respElement = new apiZuoraCom.executeResponse_element();  
        respElement.result = ExecuteResults ;  
        response.put('response_x', respElement);   
        }  
    }
    
    global class Webupdate_x implements WebServiceMock{  
        List<apiZuoraCom.SaveResult> SaveResults = new List<apiZuoraCom.SaveResult>();
        global void doInvoke(  
            Object stub,  
            Object request,  
            Map<string, object> response,  
            String endpoint,  
            String soapAction,  
            String requestName,  
            String responseNS,  
            String responseName,  
            String responseType){  
        apiZuoraCom.updateResponse_element respElement = new apiZuoraCom.updateResponse_element();  
        respElement.result = SaveResults ;  
        response.put('response_x', respElement);   
        }  
    }
    
    global class Webrasd implements WebServiceMock{  
        apiZuoraCom.rasdResponse_element respElement1 = new apiZuoraCom.rasdResponse_element();  
        global void doInvoke(  
            Object stub,  
            Object request,  
            Map<string, object> response,  
            String endpoint,  
            String soapAction,  
            String requestName,  
            String responseNS,  
            String responseName,  
            String responseType){  
        apiZuoraCom.rasdResponse_element respElement = new apiZuoraCom.rasdResponse_element();  
        respElement = respElement1 ;  
        response.put('response_x', respElement);   
        }  
    }
    
    global class Webamend implements WebServiceMock{  
        List<apiZuoraCom.AmendResult> AmendResults = new List<apiZuoraCom.AmendResult>();  
        global void doInvoke(  
            Object stub,  
            Object request,  
            Map<string, object> response,  
            String endpoint,  
            String soapAction,  
            String requestName,  
            String responseNS,  
            String responseName,  
            String responseType){  
        apiZuoraCom.amendResponse_element respElement = new apiZuoraCom.amendResponse_element();  
        respElement.results = AmendResults ;  
        response.put('response_x', respElement);   
        }  
    }
    
    global class Webcreate implements WebServiceMock{  
        List<apiZuoraCom.SaveResult> SaveResults = new List<apiZuoraCom.SaveResult>();  
        global void doInvoke(  
            Object stub,  
            Object request,  
            Map<string, object> response,  
            String endpoint,  
            String soapAction,  
            String requestName,  
            String responseNS,  
            String responseName,  
            String responseType){  
        apiZuoraCom.createResponse_element respElement = new apiZuoraCom.createResponse_element();  
        respElement.result = SaveResults;  
        response.put('response_x', respElement);   
        }  
    }
    
    global class Weblogin implements WebServiceMock{  
        apiZuoraCom.LoginResult LoginResult = new apiZuoraCom.LoginResult();  
        global void doInvoke(  
            Object stub,  
            Object request,  
            Map<string, object> response,  
            String endpoint,  
            String soapAction,  
            String requestName,  
            String responseNS,  
            String responseName,  
            String responseType){  
        apiZuoraCom.loginResponse_element respElement = new apiZuoraCom.loginResponse_element();  
        respElement.result = LoginResult;  
        response.put('response_x', respElement);   
        }  
    }
    
    global class WebgetUserInfo implements WebServiceMock{  
        apiZuoraCom.getUserInfoResponse_element respElement1 = new apiZuoraCom.getUserInfoResponse_element();  
        global void doInvoke(  
            Object stub,  
            Object request,  
            Map<string, object> response,  
            String endpoint,  
            String soapAction,  
            String requestName,  
            String responseNS,  
            String responseName,  
            String responseType){  
        apiZuoraCom.getUserInfoResponse_element respElement = new apiZuoraCom.getUserInfoResponse_element();  
        respElement = respElement1 ;  
        response.put('response_x', respElement);   
        }  
    }
    
    
    
    global class Webdelete_x implements WebServiceMock{  
        list<apiZuoraCom.DeleteResult> DeleteResults = new list<apiZuoraCom.DeleteResult>();  
        global void doInvoke(  
            Object stub,  
            Object request,  
            Map<string, object> response,  
            String endpoint,  
            String soapAction,  
            String requestName,  
            String responseNS,  
            String responseName,  
            String responseType){  
        apiZuoraCom.deleteResponse_element respElement = new apiZuoraCom.deleteResponse_element();  
        respElement.result = DeleteResults;  
        response.put('response_x', respElement);   
        }  
    }
}