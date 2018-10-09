@isTest
private class ThoughtStarterRFPTriggerTest {

    private static Set<String> stringTypes = new Set<String>{'PICKLIST', 'STRING', 'MULTIPICKLIST', 'TEXTAREA'};
    private static Set<String> numberTypes = new Set<String>{'CURRENCY', 'DOUBLE', 'INTEGER'};
    private static Map<String,Schema.RecordTypeInfo> rtTSRFPMapByName = Schema.SObjectType.ThoughtStarter_RFP__c.getRecordTypeInfosByName();
    private static Map<String,Schema.RecordTypeInfo> rtMapByName = Schema.SObjectType.Account.getRecordTypeInfosByName();
    private static List<Schema.FieldSetMember> rfpFieldSetList = SObjectType.ThoughtStarter_RFP__c.FieldSets.Required_RFP_Fields.getFields();
    private static List<Schema.FieldSetMember> tsFieldSetList = SObjectType.ThoughtStarter_RFP__c.FieldSets.Required_ThoughtStarter_Fields.getFields();

    @isTest static void thoughtStarterWFInitial() {
       List<XO_Exception__c> exceptionList = new List<XO_Exception__c>();
        insert (List<National_TS_RFP_Task_Stage_Mapping__c>)JSON.deserialize([Select body from StaticResource where Name = 'NatTSRFPTaskStageMapJSON'].body.toString(), List<National_TS_RFP_Task_Stage_Mapping__c>.class);
        insert (List<National_Opp_Stage_Task_Email__c>)JSON.deserialize([Select body from StaticResource where Name = 'NatOppStageTaskEmailJSON'].body.toString(), List<National_Opp_Stage_Task_Email__c>.class);
        insert (List<Stage_Requires_Complete_TS_RFP__c>)JSON.deserialize([Select body from StaticResource where Name = 'StageRequireCompleteTSRFP'].body.toString(), List<Stage_Requires_Complete_TS_RFP__c>.class);

        Id pricebookId = Test.getStandardPricebookId();

        // Create Canada Market
        Market__c canada = new Market__c();
        canada.Name = 'CAN - Toronto - 222';
        canada.Short_Description__c = 'CAN - Toronto';
        canada.Market_ID__c = '222';
        insert canada;

        Generate_Quote_Pdf_Config__c newGQP = new Generate_Quote_Pdf_Config__c();
        newGQP.Name = 'Production';
        newGQP.URL__c = 'http://www.xogrpinc.com';
        insert newGQP;

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

        Account testAccount = new Account();
        testAccount.Name = 'Test thoughtStarterWFInitial';
        testAccount.RecordTypeId = rtMapByName.get('National').getRecordTypeId();
        testAccount.BU__c = 'National';
        testAccount.Website = 'www.thoughtStarterWFInitial.com';
        testAccount.Type = 'Advertiser';
        testAccount.BillingState = 'Texas';
        testAccount.BillingCountry = 'United States';
        testAccount.AccSource__c = 'Others';
        insert testAccount;

        Opportunity testOpportunity = new Opportunity();
        testOpportunity.Name = 'Test Opportunity';
        testOpportunity.AccountId = testAccount.Id;
        testOpportunity.StageName = 'Qualified';
        testOpportunity.CloseDate = date.today().addDays(5);
        testOpportunity.AccStrategist__c = [select Id from User where isActive = true and Id != :UserInfo.getUserId() limit 1].Id;
        testOpportunity.Amount = 50000;
        insert testOpportunity;

        testOpportunity.AccStrategist__c = UserInfo.getUserId();
        update testOpportunity;

        Test.startTest();

        ThoughtStarter_RFP__c newThoughtStarter = new ThoughtStarter_RFP__c();
        newThoughtStarter.Opportunity__c = testOpportunity.Id;
        newThoughtStarter.RecordTypeId = rtTSRFPMapByName.get('ThoughtStarter').getRecordTypeId();
        newThoughtStarter.Account_Strategist__c = UserInfo.getUserId();
        newThoughtStarter.Clicks__c = true;
        newThoughtStarter.CTR__c = 2;

        newThoughtStarter.Submitted_for_Production__c = true;

        try{
            insert newThoughtStarter;
        }catch(Exception E){
            XO_Exception__c xoException = ExceptionUtility.consumeException(E, false);
            xoException.Severity__c = 'Critical';
            xoException.Failure_Area__c = 'Lead Assignment Workflow Exception';
            exceptionList.add(xoException);
        }

        for(Schema.FieldSetMember record : tsFieldSetList){
            String typeValue = String.valueof(record.getType());
            String fieldPathValue = String.valueof(record.getFieldPath());

            if(stringTypes.contains(typeValue) == true){
                newThoughtStarter.put(fieldPathValue, 'Test Value');
            }else if(numberTypes.contains(typeValue) == true){
                newThoughtStarter.put(fieldPathValue, 500);
            }else if(typeValue == 'DATE'){
                newThoughtStarter.put(fieldPathValue, Date.today().addDays(5));
            }
        }
        
        if(String.isBlank(newThoughtStarter.Id)){

            insert newThoughtStarter;
    
            List<Task> closeTaskList = new List<Task>();
            for(Task record : [Select Status from Task where WhatId =: newThoughtStarter.Id]){
                record.Status = 'Completed';
                closeTaskList.add(record);
            }
            if(!closeTaskList.isEmpty()){
                update closeTaskList[0];
            }
    
            closeTaskList.clear();
    
            for(Task record : [Select Status from Task where WhatId =: newThoughtStarter.Id]){
                record.Status = 'Completed';
                closeTaskList.add(record);
            }
            update closeTaskList;
    
            testOpportunity.StageName = [select MasterLabel from OpportunityStage where IsClosed = true and isWon = false limit 1].MasterLabel;
            testOpportunity.Lost_Reason__c = 'Bad Pay';
            update testOpportunity;
        
        }

        Test.stopTest();
    }

    @isTest static void thoughtStarterWFUpdate() {
       List<XO_Exception__c> exceptionList = new List<XO_Exception__c>();
        Id pricebookId = Test.getStandardPricebookId();

        // Create Canada Market
        Market__c canada = new Market__c();
        canada.Name = 'CAN - Toronto - 222';
        canada.Short_Description__c = 'CAN - Toronto';
        canada.Market_ID__c = '222';
        insert canada;

        Generate_Quote_Pdf_Config__c newGQP = new Generate_Quote_Pdf_Config__c();
        newGQP.Name = 'Production';
        newGQP.URL__c = 'http://www.xogrpinc.com';
        insert newGQP;

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
        
        Account testAccount = new Account();
        testAccount.Name = 'Test thoughtStarterWFUpdate';
        testAccount.RecordTypeId = rtMapByName.get('National').getRecordTypeId();
        testAccount.BU__c = 'National';
        testAccount.Website = 'www.thoughtStarterWFUpdate.com';
        testAccount.Type = 'Advertiser';
        testAccount.BillingState = 'Texas';
        testAccount.BillingCountry = 'United States';
        testAccount.AccSource__c = 'Others';
        insert testAccount;

        Opportunity testOpportunity = new Opportunity();
        testOpportunity.Name = 'Test Opportunity';
        testOpportunity.AccountId = testAccount.Id;
        testOpportunity.StageName = 'Qualified';
        testOpportunity.CloseDate = date.today().addDays(5);
        testOpportunity.AccStrategist__c = UserInfo.getUserId();
        testOpportunity.Amount = 50000;
        insert testOpportunity;

        Test.startTest();

        ThoughtStarter_RFP__c newThoughtStarter = new ThoughtStarter_RFP__c();
        newThoughtStarter.Opportunity__c = testOpportunity.Id;
        newThoughtStarter.RecordTypeId = rtTSRFPMapByName.get('ThoughtStarter').getRecordTypeId();
        newThoughtStarter.Clicks__c = true;
        newThoughtStarter.CTR__c = 2;
        insert newThoughtStarter;

        newThoughtStarter.Submitted_for_Production__c = true;

        try{
            update newThoughtStarter;
        }catch(Exception E){
            XO_Exception__c xoException = ExceptionUtility.consumeException(E, false);
            xoException.Severity__c = 'Critical';
            xoException.Failure_Area__c = 'Lead Assignment Workflow Exception';
            exceptionList.add(xoException);
        }

        for(Schema.FieldSetMember record : tsFieldSetList){
            String typeValue = String.valueof(record.getType());
            String fieldPathValue = String.valueof(record.getFieldPath());

            if(stringTypes.contains(typeValue) == true){
                newThoughtStarter.put(fieldPathValue, 'Test Value');
            }else if(numberTypes.contains(typeValue) == true){
                newThoughtStarter.put(fieldPathValue, 500);
            }else if(typeValue == 'DATE'){
                newThoughtStarter.put(fieldPathValue, Date.today().addDays(5));
            }
        }

        update newThoughtStarter;

        Test.stopTest();
    }

    @isTest static void RFPInitial() {
       List<XO_Exception__c> exceptionList = new List<XO_Exception__c>();
        insert (List<National_TS_RFP_Task_Stage_Mapping__c>)JSON.deserialize([Select body from StaticResource where Name = 'NatTSRFPTaskStageMapJSON'].body.toString(), List<National_TS_RFP_Task_Stage_Mapping__c>.class);
        insert (List<National_Opp_Stage_Task_Email__c>)JSON.deserialize([Select body from StaticResource where Name = 'NatOppStageTaskEmailJSON'].body.toString(), List<National_Opp_Stage_Task_Email__c>.class);

        // Create Canada Market
        Market__c canada = new Market__c();
        canada.Name = 'CAN - Toronto - 222';
        canada.Short_Description__c = 'CAN - Toronto';
        canada.Market_ID__c = '222';
        insert canada;

        Generate_Quote_Pdf_Config__c newGQP = new Generate_Quote_Pdf_Config__c();
        newGQP.Name = 'Production';
        newGQP.URL__c = 'http://www.xogrpinc.com';
        insert newGQP;

        Account testAccount = new Account();
        testAccount.Name = 'Test RFPInitial';
        testAccount.RecordTypeId = rtMapByName.get('National').getRecordTypeId();
        testAccount.BU__c = 'National';
        testAccount.Website = 'www.RFPInitial.com';
        testAccount.Type = 'Advertiser';
        testAccount.BillingState = 'Texas';
        testAccount.BillingCountry = 'United States';
        testAccount.AccSource__c = 'Others';
        insert testAccount;

        Opportunity testOpportunity = new Opportunity();
        testOpportunity.Name = 'Test Opportunity';
        testOpportunity.AccountId = testAccount.Id;
        testOpportunity.StageName = 'Qualified';
        testOpportunity.CloseDate = date.today().addDays(5);
        testOpportunity.AccStrategist__c = UserInfo.getUserId();
        testOpportunity.Amount = 50000;
        insert testOpportunity;

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

        Test.startTest();

        system.debug([select Id, RecordType.Name from Opportunity where Id = : testOpportunity.Id].recordtype.name);

        ThoughtStarter_RFP__c newThoughtStarter = new ThoughtStarter_RFP__c();
        newThoughtStarter.Opportunity__c = testOpportunity.Id;
        newThoughtStarter.RecordTypeId = rtTSRFPMapByName.get('RFP').getRecordTypeId();
        newThoughtStarter.Sales_Dev_Needed__c = true;
        newThoughtStarter.Account_Strategist__c = UserInfo.getUserId();
        newThoughtStarter.Clicks__c = true;
        newThoughtStarter.CTR__c = 2;

        newThoughtStarter.Submitted_for_Production__c = true;
        newThoughtStarter.Sales_Developer__c = [select Id from User where UserRole.DeveloperName = 'Sales_Development' limit 1].id;

        try{
            insert newThoughtStarter;
        }catch(Exception E){
            XO_Exception__c xoException = ExceptionUtility.consumeException(E, false);
            xoException.Severity__c = 'Critical';
            xoException.Failure_Area__c = 'Lead Assignment Workflow Exception';
            exceptionList.add(xoException);
        }

        newThoughtStarter.Sales_Dev_Needed__c = false;

        try{
            update newThoughtStarter;
        }catch(Exception EE){
            XO_Exception__c xoException = ExceptionUtility.consumeException(EE, false);
            xoException.Severity__c = 'Critical';
            xoException.Failure_Area__c = 'Lead Assignment Workflow Exception';
            exceptionList.add(xoException);
        }

        for(Schema.FieldSetMember record : rfpFieldSetList){
            String typeValue = String.valueof(record.getType());
            String fieldPathValue = String.valueof(record.getFieldPath());

            if(stringTypes.contains(typeValue) == true){
                newThoughtStarter.put(fieldPathValue, 'Test Value');
            }else if(numberTypes.contains(typeValue) == true){
                newThoughtStarter.put(fieldPathValue, 500);
            }else if(typeValue == 'DATE'){
                newThoughtStarter.put(fieldPathValue, Date.today().addDays(5));
            }
        }
        
        if(String.isBlank(newThoughtStarter.Id)){

            insert newThoughtStarter;
    
            List<Task> closeTaskList = new List<Task>();
            for(Task record : [Select Status from Task where WhatId =: newThoughtStarter.Id order by Purpose__c]){
                record.Status = 'Completed';
                closeTaskList.add(record);
            }
    
            update closeTaskList[0];
    
            closeTaskList.remove(0);
    
            update closeTaskList;
    
            testOpportunity.StageName = 'Stage 6: Approved to Pitch';
            update testOpportunity;
    
            closeTaskList.clear();
    
            for(Task record : [Select Status from Task where WhatId =: newThoughtStarter.Id]){
                record.Status = 'Completed';
                closeTaskList.add(record);
            }
            update closeTaskList;
    
            closeTaskList.clear();
    
            for(Task record : [Select Status from Task where WhatId =: newThoughtStarter.Id]){
                record.Status = 'Completed';
                closeTaskList.add(record);
            }
            update closeTaskList;
        
        }

        Test.stopTest();
    }
    
    @isTest static void RFPUpdate() {
        // Create Canada Market
       List<XO_Exception__c> exceptionList = new List<XO_Exception__c>();
        TestClassUtility.DISABLE_TRIGGERS = TRUE;
        Market__c canada = new Market__c();
        canada.Name = 'CAN - Toronto - 222';
        canada.Short_Description__c = 'CAN - Toronto';
        canada.Market_ID__c = '222';
        insert canada;

        Generate_Quote_Pdf_Config__c newGQP = new Generate_Quote_Pdf_Config__c();
        newGQP.Name = 'Production';
        newGQP.URL__c = 'http://www.xogrpinc.com';
        insert newGQP;

        Account testAccount = new Account();
        testAccount.Name = 'Test RFPUpdate';
        testAccount.RecordTypeId = rtMapByName.get('National').getRecordTypeId();
        testAccount.BU__c = 'National';
        testAccount.Website = 'www.RFPUpdate.com';
        testAccount.Type = 'Advertiser';
        testAccount.BillingState = 'Texas';
        testAccount.BillingCountry = 'United States';
        testAccount.AccSource__c = 'Others';
        insert testAccount;

        Opportunity testOpportunity = new Opportunity();
        testOpportunity.Name = 'Test Opportunity';
        testOpportunity.AccountId = testAccount.Id;
        testOpportunity.StageName = 'Qualified';
        testOpportunity.CloseDate = date.today().addDays(5);
        testOpportunity.AccStrategist__c = UserInfo.getUserId();
        testOpportunity.Amount = 50000;
        insert testOpportunity;

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
        TestClassUtility.DISABLE_TRIGGERS = FALSE;
        System.debug(LoggingLevel.INFO, '*** limits.getQueries(): ' + limits.getQueries());
        Test.startTest();

        
        System.debug(LoggingLevel.INFO, '*** limits.getQueries()2: ' + limits.getQueries());
        ThoughtStarter_RFP__c newThoughtStarter = new ThoughtStarter_RFP__c();
        newThoughtStarter.Opportunity__c = testOpportunity.Id;
        newThoughtStarter.RecordTypeId = rtTSRFPMapByName.get('RFP').getRecordTypeId();
        newThoughtStarter.Sales_Dev_Needed__c = false;
        newThoughtStarter.Clicks__c = true;
        newThoughtStarter.CTR__c = 2;
        insert newThoughtStarter;

        newThoughtStarter.Submitted_for_Production__c = true;
        System.debug(LoggingLevel.INFO, '*** limits.getQueries()3: ' + limits.getQueries());
        try{
            newThoughtStarter.RecordTypeId = rtTSRFPMapByName.get('ThoughtStarter').getRecordTypeId();
            update newThoughtStarter;
        }catch(Exception E){
            XO_Exception__c xoException = ExceptionUtility.consumeException(E, false);
            xoException.Severity__c = 'Critical';
            xoException.Failure_Area__c = 'ThoughtStarterRFPTriggerHandler';
            exceptionList.add(xoException);
        }
        System.debug(LoggingLevel.INFO, '*** limits.getQueries()4: ' + limits.getQueries());
        try{
            newThoughtStarter.RecordTypeId = rtTSRFPMapByName.get('RFP').getRecordTypeId();
            update newThoughtStarter;
        }catch(Exception E){
            XO_Exception__c xoException = ExceptionUtility.consumeException(E, false);
            xoException.Severity__c = 'Critical';
            xoException.Failure_Area__c = 'ThoughtStarterRFPTriggerHandler';
            exceptionList.add(xoException);
        }
        System.debug(LoggingLevel.INFO, '*** limits.getQueries()5: ' + limits.getQueries());
        for(Schema.FieldSetMember record : rfpFieldSetList){
            String typeValue = String.valueof(record.getType());
            String fieldPathValue = String.valueof(record.getFieldPath());

            if(stringTypes.contains(typeValue) == true){
                newThoughtStarter.put(fieldPathValue, 'Test Value');
            }else if(numberTypes.contains(typeValue) == true){
                newThoughtStarter.put(fieldPathValue, 500);
            }else if(typeValue == 'DATE'){
                newThoughtStarter.put(fieldPathValue, Date.today().addDays(5));
            }
        }
        System.debug(LoggingLevel.INFO, '*** limits.getQueries()6: ' + limits.getQueries());
        // update newThoughtStarter;

        List<Task> closeTaskList = new List<Task>();
        for(Task record : [Select Status from Task where WhatId =: newThoughtStarter.Id order by Purpose__c]){
            record.Status = 'Completed';
            closeTaskList.add(record);
        }
        update closeTaskList;
        System.debug(LoggingLevel.INFO, '*** limits.getQueries()7: ' + limits.getQueries());
        Test.stopTest();
    }
    
}