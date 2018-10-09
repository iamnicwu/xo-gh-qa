/* 
<class>
    <name>test_OpportunityCloseController</name>
    <purpose>Tests functionality in OpportunityCloseController</purpose>
    <created>
        <by>Steve O'Neal</by>
        <date>5/29/2015</date>
        <ticket>SF-457</ticket>
        <ticket>SF-470</ticket>
    </created>
</class>
*/
@isTest
private class OpportunityCloseControllerTest {
    /* 
    <method>
        <name>testController</name>
        <purpose>Test the OpportunityCloseController methods</purpose>
        <created>
            <by>Steve O'Neal</by>
            <date>5/29/2015</date>
            <ticket>SF-457</ticket>
            <ticket>SF-470</ticket>
        </created>
    </method>
    */
    static testMethod void test_method_one() {


        Test.startTest();
        Map<String,SObject> sObjectMap  = TestClassUtility.buildLocalData(FALSE);
        Account testAccount = (Account)sObjectMap.get('Account');
        Opportunity testOpportunity = (Opportunity)sObjectMap.get('Opportunity');
        Contact testContact = (Contact)sObjectMap.get('Contact');
        Contract testContract = TestClassUtility.createContract(TRUE, testOpportunity, testAccount, testContact);
        Test.stopTest();

        // create the page controller
        ApexPages.StandardController oppStandardController = new ApexPages.StandardController(testOpportunity);
        OpportunityCloseController oppCloseController = new OpportunityCloseController(oppStandardController);
        
        // test public methods in the controller
        List<SelectOption> closeOptions = oppCloseController.getStageCloseOptions();
        List<OpportunityCloseController.FieldSetMemberExtended> fmeList =  oppCloseController.getCloseOpportunityAdditionalFields();
        
        // test the FieldMemberExtended class public methods
        for (OpportunityCloseController.FieldSetMemberExtended fme : fmeList)
        {
            boolean isRequired = fme.getIsRequired();
            boolean isReadOnly = fme.IsReadOnly;
            fme.IsReadOnly = isReadOnly;
            Schema.FieldSetMember fsm = fme.getFieldSetMember();
        }
        
        Opportunity testOpp = oppCloseController.getOpp();

        // update the opportunity with an error
        testOpp.StageName = 'Closed Won';
        testOpp.Lost_Reason__c = 'Something';
        oppCloseController.Save();
        
        // update the opportunity and save
        testOpp.Lost_Reason__c = '';
        testOpp.ContractId = testContract.Id;
        testOpp.StageName = 'Closed Won';
        oppCloseController.Save();
    
    }
}