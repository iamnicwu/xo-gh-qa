@isTest
private class faultApiZuoraComTest {
    
    @isTest static void test_method_one() {
        // Implement test code
        Test.startTest();
        
        faultApiZuoraCom.ApiFault ApiFault = new faultApiZuoraCom.ApiFault();
        faultApiZuoraCom.MalformedQueryFault MalformedQueryFault = new faultApiZuoraCom.MalformedQueryFault();
        faultApiZuoraCom.InvalidValueFault InvalidValueFault = new faultApiZuoraCom.InvalidValueFault();
        faultApiZuoraCom.UnexpectedErrorFault UnexpectedErrorFault = new faultApiZuoraCom.UnexpectedErrorFault();
        faultApiZuoraCom.InvalidQueryLocatorFault InvalidQueryLocatorFault = new faultApiZuoraCom.InvalidQueryLocatorFault();
        faultApiZuoraCom.InvalidTypeFault InvalidTypeFault = new faultApiZuoraCom.InvalidTypeFault();
        faultApiZuoraCom.LoginFault LoginFault = new faultApiZuoraCom.LoginFault();
        Test.stopTest();
        
    }
   
}