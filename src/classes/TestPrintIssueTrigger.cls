/**
 This class will test all Print Issues and supporting objects (Editions and Publications)
 */
@isTest
private class TestPrintIssueTrigger {

    static testMethod void test_method_one() {
        Test.startTest();
        Print_Issue_Date_Offset__c pido = new Print_Issue_Date_Offset__c();
        pido.name = 'Selling_End_Date__c';
        pido.Offset_in_Days__c = 2;
        insert pido;
        
        Publication__c testPublication = new Publication__c();
        testPublication.name = 'testPublication';
        testPublication.Short_Name__c = 'test';
        insert testPublication;

        Edition__c testEdition = new Edition__c();
        testEdition.name = 'testEdition';
        testEdition.Publication__c = testPublication.id;
        insert testEdition;
        
        Market__c testMarket = new Market__c();
        testMarket.Name = 'Test Market';
        testMarket.Short_Description__c = 'Test Market';
        testMarket.Market_ID__c = '999';
        testMarket.Active__c = true;
        insert testMarket;
        
        Print_Issue__c pi1 =new Print_Issue__c();
        pi1.name = 'test name';
        pi1.Edition__c = testEdition.id;
        pi1.Print_Market__c = testMarket.id;
        pi1.Publish_1st_Cover_Ship__c = date.today();
        try{
        insert pi1;
        }catch(exception e){}
        
        pi1.Selling_Start_Date__c = date.today();
        insert pi1;
        
        Print_Issue__c pi =new Print_Issue__c();
        pi.name = 'test name';
        pi.Previous_Years_Issue__c = pi1.id;
        pi.Edition__c = testEdition.id;
        pi.Print_Market__c = testMarket.id;
        pi.Publish_1st_Cover_Ship__c = date.today();
        pi.Step_2__c = date.today().adddays(-1);
        pi.Step_3__c = date.today().adddays(-1);
        try{
        insert pi;
        }catch(exception e){}
        
        Test.stopTest();
    }
}