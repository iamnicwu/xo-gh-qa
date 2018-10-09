@isTest
private class TestEditionTrigger {
    private static testmethod void test_method_one(){
        Publication__c p = new Publication__c();
        p.Short_Name__c = 'testP';
        insert p;
        
        Edition__c e = new Edition__c();
        e.Allow_Custom_Name__c = false;
        e.Short_Name__c = 'TestE';
        e.Season__c = 'Spring/Summer';
        e.Year__c = '2015';
        e.Volume__c = 10;
        e.Publication__c = p.id;
        insert e;
        
        e.Season__c =null;
        update e;
        
        e.Season__c = 'q';
        update e;
        
        e.Season__c = 'Spring';
        update e;
    }
}