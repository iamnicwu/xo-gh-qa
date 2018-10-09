@isTest
private class TestLocalSalesRepAssignmentTrigger{
    @isTest static void test_method_one() {
        MetroArea__c ma = new MetroArea__c();
        ma.name = 'test';
        insert ma;
        
        Zip__c zip = new Zip__c();
        zip.MetroArea__c = ma.id;
        zip.ZipCode__c = '12121';
        Zip.name = '12121';
        insert zip;
        
        Local_Sales_Rep_Assignment__c testlsra = new Local_Sales_Rep_Assignment__c();
        testlsra.Name = 'test name';
        testlsra.Zip_Code__c = zip.id;
        insert testlsra;
    }
}