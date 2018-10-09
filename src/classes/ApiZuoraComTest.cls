/**
Date: 12/7/2015
Author: Tony Liu
Purpose: test apiZuoraCom class
 */
@isTest
private class ApiZuoraComTest{ 
    private static testMethod void myUnitTest() {
        apiZuoraCom.ChargeMetricsData ChargeMetricsData = new apiZuoraCom.ChargeMetricsData(); 
        apiZuoraCom.subscribe_element subscribe_element = new apiZuoraCom.subscribe_element(); 
        apiZuoraCom.create_element create_element = new apiZuoraCom.create_element(); 
        apiZuoraCom.getUserInfo_element getUserInfo_element = new apiZuoraCom.getUserInfo_element(); 
        apiZuoraCom.rasdResponse_element rasdResponse_element = new apiZuoraCom.rasdResponse_element(); 
        apiZuoraCom.LoginResult LoginResult= new apiZuoraCom.LoginResult(); 
        apiZuoraCom.createResponse_element createResponse_element = new apiZuoraCom.createResponse_element(); 
        apiZuoraCom.InvoiceData InvoiceData = new apiZuoraCom.InvoiceData(); 
        apiZuoraCom.queryMore_element queryMore_element = new apiZuoraCom.queryMore_element(); 
        apiZuoraCom.query_element query_element = new apiZuoraCom.query_element(); 
        apiZuoraCom.amend_element amend_element = new apiZuoraCom.amend_element(); 
        apiZuoraCom.InvoiceProcessingOptions InvoiceProcessingOptions = new apiZuoraCom.InvoiceProcessingOptions(); 
        apiZuoraCom.ExternalPaymentOptions ExternalPaymentOptions = new apiZuoraCom.ExternalPaymentOptions(); 
        apiZuoraCom.queryResponse_element queryResponse_element = new apiZuoraCom.queryResponse_element(); 
        apiZuoraCom.subscriptionQueryResponse_element subscriptionQueryResponse_element = new apiZuoraCom.subscriptionQueryResponse_element(); 
        apiZuoraCom.DummyHeader_element DummyHeader_element = new apiZuoraCom.DummyHeader_element(); 
        apiZuoraCom.loginResponse_element loginResponse_element = new apiZuoraCom.loginResponse_element(); 
        apiZuoraCom.login_element login_element = new apiZuoraCom.login_element(); 
        apiZuoraCom.InvoiceResult InvoiceResult = new apiZuoraCom.InvoiceResult(); 
        apiZuoraCom.SubscribeInvoiceProcessingOptions SubscribeInvoiceProcessingOptions = new apiZuoraCom.SubscribeInvoiceProcessingOptions(); 
        apiZuoraCom.RatePlanData RatePlanData = new apiZuoraCom.RatePlanData(); 
        apiZuoraCom.QueryResult QueryResult = new apiZuoraCom.QueryResult(); 
        apiZuoraCom.SubscriptionQueryResult SubscriptionQueryResult = new apiZuoraCom.SubscriptionQueryResult();
        apiZuoraCom.AmendmentQueryResult AmendmentQueryResult = new apiZuoraCom.AmendmentQueryResult();
        apiZuoraCom.QueryOptions_element QueryOptions_element = new apiZuoraCom.QueryOptions_element();
        apiZuoraCom.CallOptions_element CallOptions_element = new apiZuoraCom.CallOptions_element();
        apiZuoraCom.GatewayOptionData GatewayOptionData = new apiZuoraCom.GatewayOptionData();
        apiZuoraCom.getUserInfoResponse_element getUserInfoResponse_element = new apiZuoraCom.getUserInfoResponse_element();
        apiZuoraCom.AmendOptions AmendOptions = new apiZuoraCom.AmendOptions();
        apiZuoraCom.ExecuteResult ExecuteResult = new apiZuoraCom.ExecuteResult();
        apiZuoraCom.SessionHeader_element SessionHeader_element = new apiZuoraCom.SessionHeader_element();
        apiZuoraCom.PreviewOptions PreviewOptions = new apiZuoraCom.PreviewOptions();
        apiZuoraCom.SubscribeRequest SubscribeRequest = new apiZuoraCom.SubscribeRequest();
        apiZuoraCom.executeResponse_element executeResponse_element = new apiZuoraCom.executeResponse_element();
        apiZuoraCom.rasdRequest_element rasdRequest_element = new apiZuoraCom.rasdRequest_element();
        apiZuoraCom.AmendResult AmendResult = new apiZuoraCom.AmendResult();
        apiZuoraCom.SaveResult SaveResult = new apiZuoraCom.SaveResult();
        apiZuoraCom.SubscribeResult SubscribeResult = new apiZuoraCom.SubscribeResult();
        apiZuoraCom.RatePlanChargeData RatePlanChargeData = new apiZuoraCom.RatePlanChargeData();
        apiZuoraCom.DeleteResult DeleteResult = new apiZuoraCom.DeleteResult();
        apiZuoraCom.NewChargeMetrics NewChargeMetrics = new apiZuoraCom.NewChargeMetrics();
        apiZuoraCom.deleteResponse_element deleteResponse_element = new apiZuoraCom.deleteResponse_element();
        apiZuoraCom.queryMoreResponse_element queryMoreResponse_element = new apiZuoraCom.queryMoreResponse_element();
        apiZuoraCom.AmendRequest AmendRequest = new apiZuoraCom.AmendRequest();
        apiZuoraCom.update_element update_element = new apiZuoraCom.update_element();
        apiZuoraCom.SubscribeOptions SubscribeOptions = new apiZuoraCom.SubscribeOptions();
        apiZuoraCom.Error Error = new apiZuoraCom.Error();
        apiZuoraCom.RefundInvoicePaymentData RefundInvoicePaymentData = new apiZuoraCom.RefundInvoicePaymentData();
        apiZuoraCom.amendResponse_element amendResponse_element = new apiZuoraCom.amendResponse_element();
        apiZuoraCom.subscribeResponse_element subscribeResponse_element = new apiZuoraCom.subscribeResponse_element();
        apiZuoraCom.generateResponse_element generateResponse_element = new apiZuoraCom.generateResponse_element();
        apiZuoraCom.ProductRatePlanChargeTierData ProductRatePlanChargeTierData = new apiZuoraCom.ProductRatePlanChargeTierData();
        apiZuoraCom.generate_element generate_element = new apiZuoraCom.generate_element();
        apiZuoraCom.delete_element delete_element = new apiZuoraCom.delete_element();
        apiZuoraCom.SubscriptionData SubscriptionData = new apiZuoraCom.SubscriptionData();
        apiZuoraCom.updateResponse_element updateResponse_element = new apiZuoraCom.updateResponse_element();
        apiZuoraCom.execute_element execute_element = new apiZuoraCom.execute_element();
        apiZuoraCom.InvoicePaymentData InvoicePaymentData = new apiZuoraCom.InvoicePaymentData();
        
        

        apiZuoraCom.Soap Soap = new apiZuoraCom.Soap();
        
        List<objectApiZuoraCom.zObject> zObjects = new List<objectApiZuoraCom.zObject>();
        String qString = '';
        String type_x = '';
        Boolean synchronous = false;
        List<String> ids = new List<string>(); 
        String username = '';
        String password = '';
        
        
        Test.setMock(WebServiceMock.class, new testWebServiceforApiZuoraCom.Webquery());
        QueryResult = Soap.query(qString);
        
        Test.setMock(WebServiceMock.class, new testWebServiceforApiZuoraCom.WebsubscriptionQuery());
        SubscriptionQueryResult = Soap.subscriptionQuery(qString );
        
        Test.setMock(WebServiceMock.class, new testWebServiceforApiZuoraCom.WebamendmentQuery());
        AmendmentQueryResult = Soap.amendmentQuery(qString );
        
        Test.setMock(WebServiceMock.class, new testWebServiceforApiZuoraCom.Webgenerate());
        List<apiZuoraCom.SaveResult> SaveResults = new List<apiZuoraCom.SaveResult>();
        SaveResults = Soap.generate(zObjects);
        
        Test.setMock(WebServiceMock.class, new testWebServiceforApiZuoraCom.Websubscribe());
        List<apiZuoraCom.SubscribeResult> SubscribeResults = new List<apiZuoraCom.SubscribeResult>();
        List<apiZuoraCom.SubscribeRequest> SubscribeRequests = new List<apiZuoraCom.SubscribeRequest>();
        SubscribeResults = Soap.subscribe(SubscribeRequests );
        
        Test.setMock(WebServiceMock.class, new testWebServiceforApiZuoraCom.WebqueryMore());
        QueryResult = Soap.queryMore(qString);
        
        Test.setMock(WebServiceMock.class, new testWebServiceforApiZuoraCom.Webexecute());
        List<apiZuoraCom.ExecuteResult> ExecuteResults = new List<apiZuoraCom.ExecuteResult>();
        ExecuteResults = Soap.execute(type_x, synchronous, ids );
        
        Test.setMock(WebServiceMock.class, new testWebServiceforApiZuoraCom.Webupdate_x());
        SaveResults = Soap.update_x(zObjects);
        
        Test.setMock(WebServiceMock.class, new testWebServiceforApiZuoraCom.Webrasd());
        rasdResponse_element = Soap.rasd();
        
        Test.setMock(WebServiceMock.class, new testWebServiceforApiZuoraCom.Webamend());
        List<apiZuoraCom.AmendResult> AmendResults = new List<apiZuoraCom.AmendResult>();  
        List<apiZuoraCom.AmendRequest> AmendRequests = new List<apiZuoraCom.AmendRequest>();
        AmendResults = Soap.amend(AmendRequests );
        
        Test.setMock(WebServiceMock.class, new testWebServiceforApiZuoraCom.Webcreate());
        SaveResults = Soap.create(zObjects);
        
        Test.setMock(WebServiceMock.class, new testWebServiceforApiZuoraCom.Weblogin());
        LoginResult = Soap.login(username, password);
        
        Test.setMock(WebServiceMock.class, new testWebServiceforApiZuoraCom.WebgetUserInfo());
        getUserInfoResponse_element = Soap.getUserInfo();
        
        Test.setMock(WebServiceMock.class, new testWebServiceforApiZuoraCom.Webdelete_x());
        list<apiZuoraCom.DeleteResult> DeleteResults = new list<apiZuoraCom.DeleteResult>();  
        DeleteResults = Soap.delete_x(type_x, ids);
        
    }
}