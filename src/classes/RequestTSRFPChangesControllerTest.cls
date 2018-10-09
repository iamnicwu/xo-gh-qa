@isTest
private class RequestTSRFPChangesControllerTest {

    private static Set<String> stringTypes = new Set<String>{'PICKLIST', 'STRING', 'MULTIPICKLIST', 'TEXTAREA'};
    private static Set<String> numberTypes = new Set<String>{'CURRENCY', 'DOUBLE', 'INTEGER'};
    private static Map<String,Schema.RecordTypeInfo> rtTSRFPMapByName = Schema.SObjectType.ThoughtStarter_RFP__c.getRecordTypeInfosByName();
    private static Map<String,Schema.RecordTypeInfo> rtMapByName = Schema.SObjectType.Account.getRecordTypeInfosByName();
    private static Map<String,Schema.RecordTypeInfo> rtOppMapByName = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();
    private static List<Schema.FieldSetMember> rfpFieldSetList = SObjectType.ThoughtStarter_RFP__c.FieldSets.Required_RFP_Fields.getFields();
    private static List<Schema.FieldSetMember> tsFieldSetList = SObjectType.ThoughtStarter_RFP__c.FieldSets.Required_ThoughtStarter_Fields.getFields();
    
    @isTest static void test_method_one() {
        TestClassUtility.generateQuotePdfConfig(true);

        Account testAccount = TestClassUtility.createAccount(false);
        testAccount.RecordTypeId = rtMapByName.get('National').getRecordTypeId();
        testAccount.AccSource__c = 'Others';
        insert testAccount;

        Opportunity testOpportunity = TestClassUtility.createOpportunity(false, testAccount);
        testOpportunity.RecordTypeId = rtOppMapByName.get('National').getRecordTypeId();
        testOpportunity.Description = 'Test data for test class';
        insert testOpportunity;

        Test.startTest();
        Id pricebookId = Test.getStandardPricebookId();

        //Create your product
        Product2 prod = new Product2(
            Name = 'Uncategorized Revenue',
            ProductCode = 'Pro-X',
            isActive = true
        );
        insert prod;

        //Create your pricebook entry
        PricebookEntry pbEntry = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = prod.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert pbEntry;

        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = testOpportunity.Id,
            Quantity = 5,
            PricebookEntryId = pbEntry.Id,
            TotalPrice = 5 * pbEntry.UnitPrice
        );
        insert oli;

        ThoughtStarter_RFP__c newRFP = new ThoughtStarter_RFP__c();
        newRFP.Opportunity__c = testOpportunity.Id;
        newRFP.RecordTypeId = rtTSRFPMapByName.get('RFP').getRecordTypeId();
        newRFP.Account_Strategist__c = UserInfo.getUserId();
        newRFP.Sales_Dev_Needed__c = False;
        newRFP.Clicks__c = true;
        newRFP.CTR__c = 2;

        for(Schema.FieldSetMember record : rfpFieldSetList){
            String typeValue = String.valueof(record.getType());
            String fieldPathValue = String.valueof(record.getFieldPath());

            if(stringTypes.contains(typeValue) == true){
                newRFP.put(fieldPathValue, 'Test Value');
            }else if(numberTypes.contains(typeValue) == true){
                newRFP.put(fieldPathValue, 500);
            }else if(typeValue == 'DATE'){
                newRFP.put(fieldPathValue, Date.today().addDays(5));
            }
        }

        insert newRFP;

        //Test.startTest();

        PageReference pageRef = Page.RequestTSRFPChanges;
        Test.setCurrentPage(pageRef);

        ApexPages.currentPage().getParameters().put('whatId', newRFP.Id);

        RequestTSRFPChangesController controller = new RequestTSRFPChangesController();

        controller.save();

        Test.stopTest();
    }
    
    @isTest static void test_method_two() {
        TestClassUtility.generateQuotePdfConfig(true);

        Account testAccount = TestClassUtility.createAccount(false);
        testAccount.RecordTypeId = rtMapByName.get('National').getRecordTypeId();
        testAccount.AccSource__c = 'Others';
        insert testAccount;

        Opportunity testOpportunity = TestClassUtility.createOpportunity(false, testAccount);
        testOpportunity.RecordTypeId = rtOppMapByName.get('National').getRecordTypeId();
        testOpportunity.Description = 'Test data for test class';
        insert testOpportunity;

        Id pricebookId = Test.getStandardPricebookId();
        Test.startTest();
        //Create your product
        Product2 prod = new Product2(
            Name = 'Uncategorized Revenue',
            ProductCode = 'Pro-X',
            isActive = true
        );
        insert prod;

        //Create your pricebook entry
        PricebookEntry pbEntry = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = prod.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert pbEntry;

        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = testOpportunity.Id,
            Quantity = 5,
            PricebookEntryId = pbEntry.Id,
            TotalPrice = 5 * pbEntry.UnitPrice
        );
        insert oli;

        ThoughtStarter_RFP__c newRFP = new ThoughtStarter_RFP__c();
        newRFP.Opportunity__c = testOpportunity.Id;
        newRFP.RecordTypeId = rtTSRFPMapByName.get('ThoughtStarter').getRecordTypeId();
        newRFP.Account_Strategist__c = UserInfo.getUserId();
        newRFP.Sales_Dev_Needed__c = true;
        newRFP.Clicks__c = true;
        newRFP.CTR__c = 2;

        for(Schema.FieldSetMember record : rfpFieldSetList){
            String typeValue = String.valueof(record.getType());
            String fieldPathValue = String.valueof(record.getFieldPath());

            if(stringTypes.contains(typeValue) == true){
                newRFP.put(fieldPathValue, 'Test Value');
            }else if(numberTypes.contains(typeValue) == true){
                newRFP.put(fieldPathValue, 500);
            }else if(typeValue == 'DATE'){
                newRFP.put(fieldPathValue, Date.today().addDays(5));
            }
        }

        insert newRFP;

        //Test.startTest();

        PageReference pageRef = Page.RequestTSRFPChanges;
        Test.setCurrentPage(pageRef);

        ApexPages.currentPage().getParameters().put('whatId', newRFP.Id);

        RequestTSRFPChangesController controller = new RequestTSRFPChangesController();

        controller.save();
        
        ThoughtStarter_RFP__c newRFP1 = new ThoughtStarter_RFP__c();
        newRFP1.Opportunity__c = testOpportunity.Id;
        newRFP1.RecordTypeId = rtTSRFPMapByName.get('ThoughtStarter').getRecordTypeId();
        newRFP1.Account_Strategist__c = UserInfo.getUserId();
        newRFP1.Sales_Dev_Needed__c = true;
        newRFP1.Clicks__c = true;
        newRFP1.CTR__c = 2;
        
        controller.relatedTSRFP = newRFP1 ;
        controller.salesDevNeeded = true;
        controller.save();
        controller.cancel();

        Test.stopTest();
    }
    
    @isTest static void test_method_three() {
        TestClassUtility.generateQuotePdfConfig(true);

        Account testAccount = TestClassUtility.createAccount(false);
        testAccount.RecordTypeId = rtMapByName.get('National').getRecordTypeId();
        testAccount.AccSource__c = 'Others';
        insert testAccount;

        Opportunity testOpportunity = TestClassUtility.createOpportunity(false, testAccount);
        testOpportunity.RecordTypeId = rtOppMapByName.get('National').getRecordTypeId();
        testOpportunity.Description = 'Test data for test class';
        insert testOpportunity;

        Id pricebookId = Test.getStandardPricebookId();
        Test.startTest();
        //Create your product
        Product2 prod = new Product2(
            Name = 'Uncategorized Revenue',
            ProductCode = 'Pro-X',
            isActive = true
        );
        insert prod;

        //Create your pricebook entry
        PricebookEntry pbEntry = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = prod.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert pbEntry;

        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = testOpportunity.Id,
            Quantity = 5,
            PricebookEntryId = pbEntry.Id,
            TotalPrice = 5 * pbEntry.UnitPrice
        );
        insert oli;

        ThoughtStarter_RFP__c newRFP = new ThoughtStarter_RFP__c();
        newRFP.Opportunity__c = testOpportunity.Id;
        newRFP.RecordTypeId = rtTSRFPMapByName.get('ThoughtStarter').getRecordTypeId();
        newRFP.Account_Strategist__c = UserInfo.getUserId();
        newRFP.Sales_Dev_Needed__c = true;
        newRFP.Clicks__c = true;
        newRFP.CTR__c = 2;
        newRFP.Sales_Developer__c = [select id from user where userrole.name = 'Sales Development' limit 1].id;
        for(Schema.FieldSetMember record : rfpFieldSetList){
            String typeValue = String.valueof(record.getType());
            String fieldPathValue = String.valueof(record.getFieldPath());

            if(stringTypes.contains(typeValue) == true){
                newRFP.put(fieldPathValue, 'Test Value');
            }else if(numberTypes.contains(typeValue) == true){
                newRFP.put(fieldPathValue, 500);
            }else if(typeValue == 'DATE'){
                newRFP.put(fieldPathValue, Date.today().addDays(5));
            }
        }

        insert newRFP;

        //Test.startTest();

        PageReference pageRef = Page.RequestTSRFPChanges;
        Test.setCurrentPage(pageRef);

        ApexPages.currentPage().getParameters().put('whatId', newRFP.Id);

        RequestTSRFPChangesController controller = new RequestTSRFPChangesController();

        controller.save();

        Test.stopTest();
    }
    
}