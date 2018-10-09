/**
Date: 12/7/2015
Author: Tony Liu
Purpose: test apiZuoraCom class
 */
@isTest
private class AsyncApiZuoraComTest{ 
    private static testMethod void test_method_one() {
        Test.startTest();
        
        System.Continuation continuation = new System.Continuation(360);
        AsyncApiZuoraCom.AsyncSoap AsyncSoap = new AsyncApiZuoraCom.AsyncSoap();
        
        
        Test.setMock(WebServiceMock.class, new testWebServiceforApiZuoraCom.Webquery());
        AsyncApiZuoraCom.queryResponse_elementFuture queryResponse_elementFuture;
        try{
            queryResponse_elementFuture = AsyncSoap.beginQuery(continuation,'test');
        }catch(exception e){}
        
        
        Test.setMock(WebServiceMock.class, new testWebServiceforApiZuoraCom.Webgenerate());
        AsyncApiZuoraCom.generateResponse_elementFuture generateResponse_elementFuture;
        List<objectApiZuoraCom.zObject> zObjects = new List<objectApiZuoraCom.zObject>();
        try{
            generateResponse_elementFuture = AsyncSoap.beginGenerate(continuation,zObjects );
        }catch(exception e){}
        
        
        Test.setMock(WebServiceMock.class, new testWebServiceforApiZuoraCom.Websubscribe());
        AsyncApiZuoraCom.subscribeResponse_elementFuture subscribeResponse_elementFuture;
        List<apiZuoraCom.SubscribeRequest> SubscribeRequests  = new List<apiZuoraCom.SubscribeRequest>();
        try{
            subscribeResponse_elementFuture = AsyncSoap.beginSubscribe(continuation,SubscribeRequests);
        }catch(exception e){}
        
        
        Test.setMock(WebServiceMock.class, new testWebServiceforApiZuoraCom.WebqueryMore());
        AsyncApiZuoraCom.queryMoreResponse_elementFuture queryMoreResponse_elementFuture;
        try{
            queryMoreResponse_elementFuture = AsyncSoap.beginQueryMore(continuation,'test');
        }catch(exception e){}
        
        
        Test.setMock(WebServiceMock.class, new testWebServiceforApiZuoraCom.WebqueryMore());
        AsyncApiZuoraCom.executeResponse_elementFuture  executeResponse_elementFuture;
        Boolean synchronous = true;
        List<String> ids = new List<String>();
        try{
            executeResponse_elementFuture = AsyncSoap.beginExecute(continuation,'test',synchronous, ids);
        }catch(exception e){}
        
        Test.setMock(WebServiceMock.class, new testWebServiceforApiZuoraCom.Webupdate_x());
        AsyncApiZuoraCom.updateResponse_elementFuture updateResponse_elementFuture;
        try{
            updateResponse_elementFuture = AsyncSoap.beginUpdate_x(continuation,zObjects );
        }catch(exception e){}
        
        
        Test.setMock(WebServiceMock.class, new testWebServiceforApiZuoraCom.Webrasd());
        AsyncApiZuoraCom.rasdResponse_elementFuture rasdResponse_elementFuture;
        try{
            rasdResponse_elementFuture = AsyncSoap.beginRasd(continuation);
        }catch(exception e){}
        
        
        Test.setMock(WebServiceMock.class, new testWebServiceforApiZuoraCom.Webamend());
        AsyncApiZuoraCom.amendResponse_elementFuture amendResponse_elementFuture;
        List<apiZuoraCom.AmendRequest> requests = new List<apiZuoraCom.AmendRequest>();
        try{
            amendResponse_elementFuture = AsyncSoap.beginAmend(continuation,requests );
        }catch(exception e){}
        
        Test.setMock(WebServiceMock.class, new testWebServiceforApiZuoraCom.Webcreate());
        AsyncApiZuoraCom.createResponse_elementFuture createResponse_elementFuture;
        try{
            createResponse_elementFuture = AsyncSoap.beginCreate(continuation,zObjects );
        }catch(exception e){}
        
        
        Test.setMock(WebServiceMock.class, new testWebServiceforApiZuoraCom.Weblogin());
        AsyncApiZuoraCom.loginResponse_elementFuture loginResponse_elementFuture;
        try{
            loginResponse_elementFuture = AsyncSoap.beginLogin(continuation,'test','test');
        }catch(exception e){}
        
        
        Test.setMock(WebServiceMock.class, new testWebServiceforApiZuoraCom.WebgetUserInfo());
        AsyncApiZuoraCom.getUserInfoResponse_elementFuture getUserInfoResponse_elementFuture;
        try{
            getUserInfoResponse_elementFuture = AsyncSoap.beginGetUserInfo(continuation);
        }catch(exception e){}
        
        
        Test.setMock(WebServiceMock.class, new testWebServiceforApiZuoraCom.Webdelete_x());
        AsyncApiZuoraCom.deleteResponse_elementFuture deleteResponse_elementFuture;
        try{
            deleteResponse_elementFuture = AsyncSoap.beginDelete_x(continuation,'test',ids);
        }catch(exception e){}
        
        Test.stopTest();
    }
    
    private static testMethod void test_method_two() {
        Test.startTest();
        apiZuoraCom.QueryResult QueryResult =  new apiZuoraCom.QueryResult();
        AsyncApiZuoraCom.queryResponse_elementFuture queryResponse_elementFuture = new AsyncApiZuoraCom.queryResponse_elementFuture();
        try{
            QueryResult = queryResponse_elementFuture.getValue();
        }catch(exception e){}
        
        
        List<apiZuoraCom.SaveResult> SaveResults =  new List<apiZuoraCom.SaveResult>();
        AsyncApiZuoraCom.generateResponse_elementFuture generateResponse_elementFuture = new AsyncApiZuoraCom.generateResponse_elementFuture();
        try{
            SaveResults = generateResponse_elementFuture.getValue();
        }catch(exception e){}
        
        
        List<apiZuoraCom.SubscribeResult> SubscribeResults =  new List<apiZuoraCom.SubscribeResult>();
        AsyncApiZuoraCom.subscribeResponse_elementFuture subscribeResponse_elementFuture = new AsyncApiZuoraCom.subscribeResponse_elementFuture();
        try{
            SubscribeResults = subscribeResponse_elementFuture.getValue();
        }catch(exception e){}
        
        
        AsyncApiZuoraCom.queryMoreResponse_elementFuture queryMoreResponse_elementFuture = new AsyncApiZuoraCom.queryMoreResponse_elementFuture();
        try{
            QueryResult = queryMoreResponse_elementFuture.getValue();
        }catch(exception e){}
        
        List<apiZuoraCom.ExecuteResult> ExecuteResults =  new List<apiZuoraCom.ExecuteResult>();
        AsyncApiZuoraCom.executeResponse_elementFuture executeResponse_elementFuture = new AsyncApiZuoraCom.executeResponse_elementFuture();
        try{
            ExecuteResults = executeResponse_elementFuture.getValue();
        }catch(exception e){}
        
        AsyncApiZuoraCom.updateResponse_elementFuture updateResponse_elementFuture = new AsyncApiZuoraCom.updateResponse_elementFuture();
        try{
            SaveResults = updateResponse_elementFuture.getValue();
        }catch(exception e){}
        
        apiZuoraCom.rasdResponse_element rasdResponse_element =  new apiZuoraCom.rasdResponse_element();
        AsyncApiZuoraCom.rasdResponse_elementFuture rasdResponse_elementFuture = new AsyncApiZuoraCom.rasdResponse_elementFuture();
        try{
            rasdResponse_element = rasdResponse_elementFuture.getValue();
        }catch(exception e){}
        
        List<apiZuoraCom.AmendResult > AmendResults =  new List<apiZuoraCom.AmendResult>();
        AsyncApiZuoraCom.amendResponse_elementFuture amendResponse_elementFuture = new AsyncApiZuoraCom.amendResponse_elementFuture();
        try{
            AmendResults = amendResponse_elementFuture.getValue();
        }catch(exception e){}
        
        AsyncApiZuoraCom.createResponse_elementFuture createResponse_elementFuture = new AsyncApiZuoraCom.createResponse_elementFuture();
        try{
            SaveResults = createResponse_elementFuture.getValue();
        }catch(exception e){}
        
        apiZuoraCom.LoginResult  LoginResult=  new apiZuoraCom.LoginResult();
        AsyncApiZuoraCom.loginResponse_elementFuture loginResponse_elementFuture = new AsyncApiZuoraCom.loginResponse_elementFuture();
        try{
            LoginResult= loginResponse_elementFuture.getValue();
        }catch(exception e){}
        
        apiZuoraCom.getUserInfoResponse_element getUserInfoResponse_element =  new apiZuoraCom.getUserInfoResponse_element();
        AsyncApiZuoraCom.getUserInfoResponse_elementFuture getUserInfoResponse_elementFuture = new AsyncApiZuoraCom.getUserInfoResponse_elementFuture();
        try{
            getUserInfoResponse_element = getUserInfoResponse_elementFuture.getValue();
        }catch(exception e){}
        
        
        List<apiZuoraCom.DeleteResult> DeleteResults =  new List<apiZuoraCom.DeleteResult>();
        AsyncApiZuoraCom.deleteResponse_elementFuture deleteResponse_elementFuture = new AsyncApiZuoraCom.deleteResponse_elementFuture();
        try{
            DeleteResults = deleteResponse_elementFuture.getValue();
        }catch(exception e){}
        Test.stopTest();
    }
}