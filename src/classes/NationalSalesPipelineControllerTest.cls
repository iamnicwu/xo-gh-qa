@isTest
private class NationalSalesPipelineControllerTest {
  
    @isTest static void test_method_one() {
        Map<String,Schema.RecordTypeInfo> rtMapByName = Schema.SObjectType.Account.getRecordTypeInfosByName();
        Map<String,Schema.RecordTypeInfo> rtOppMapByName = Schema.SObjectType.Opportunity.getRecordTypeInfosByName();
        
        User otherUser = [select Id from User where isActive = true and Profile.Name = 'National Users' and UserRole.Name = 'Account Executive' limit 1];
        Id otherUserId = otherUser.Id;

        otherUser.ManagerId = UserInfo.getUserId();

        update otherUser;

        Market__c testMarket = new Market__c();
        testMarket.Name = 'Test Market';
        testMarket.Short_Description__c = 'Test Market';
        testMarket.Market_ID__c = '222';
        testMarket.Active__c = true;
        upsert testMarket Market_ID__c ;
        
        Account testAccount = new Account();
        testAccount.Name = 'Test Account';
        testAccount.RecordTypeId = rtMapByName.get('National').getRecordTypeId();
        testAccount.BU__c = 'National';
        testAccount.Website = 'www.google.com';
        testAccount.Type = 'Advertiser';
        testAccount.BillingState = 'Texas';
        testAccount.BillingCountry = 'United States';
        testAccount.AccountSource = 'Other';
        testAccount.AccSource__c = 'Other';
        insert testAccount;
        
        Generate_Quote_Pdf_Config__c GQPF = new Generate_Quote_Pdf_Config__c();
        GQPF.name = 'Production';
        GQPF.URL__c = 'www.baidu.com';
        insert GQPF;
        
        List<Opportunity> newOpportunityList = new List<Opportunity>();
        for(Integer i = 0; i < 50; i++){
            Opportunity testOpportunity = new Opportunity();
            testOpportunity.Name = 'Test Opportunity';
            testOpportunity.RecordTypeId = rtOppMapByName.get('National').getRecordTypeId();
            testOpportunity.AccountId = testAccount.Id;
            testOpportunity.Description = 'test test';
            testOpportunity.CloseDate = date.today().addDays(5);
            testOpportunity.AccStrategist__c = UserInfo.getUserId();
            testOpportunity.Amount = 50000;
            if(i > 25){
                testOpportunity.OwnerId = otherUserId;
                testOpportunity.StageName = 'Prospecting';
            }else{
                testOpportunity.StageName = 'Pitched';
            }
            newOpportunityList.add(testOpportunity);
        }

        newOpportunityList[newOpportunityList.size() - 1].SplitRep__c = UserInfo.getUserId();
        insert newOpportunityList;

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
        
        List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
        for(Integer i = 0; i < newOpportunityList.size(); i++){
            OpportunityLineItem oli = new OpportunityLineItem(
                OpportunityId = newOpportunityList[i].Id,
                Quantity = 5,
                PricebookEntryId = pbEntry.Id,
                TotalPrice = 5 * pbEntry.UnitPrice,
                Start_Date__c = date.today().addDays(i),
                End_Date__c = date.today().addMonths(i)
            );
            oliList.add(oli);
        }

        insert oliList;
        
        NationalSalesPipelineController nonAEPipelineController = new NationalSalesPipelineController();
        nonAEPipelineController.getViewTypes();
        nonAEPipelineController.getSelectYears();
        nonAEPipelineController.getProductFamilyTypes();

        nonAEPipelineController.viewType = 'product';
        nonAEPipelineController.buildPipelineData();

        nonAEPipelineController.selectedProdFamily = 'Online';
        nonAEPipelineController.buildPipelineData();

        nonAEPipelineController.viewType = 'stage';
        nonAEPipelineController.buildPipelineData();

        System.runAs(otherUser) {
            NationalSalesPipelineController aePipelineController = new NationalSalesPipelineController();
            aePipelineController.getViewTypes();
            aePipelineController.getSelectYears();
            aePipelineController.getProductFamilyTypes();

            aePipelineController.viewType = 'product';
            aePipelineController.selectCampaign = 'all';
            aePipelineController.buildPipelineData();

            aePipelineController.selectedProdFamily = 'Online';
            aePipelineController.selectCampaign = 'all';
            aePipelineController.buildPipelineData();

            aePipelineController.selectedProdFamily = 'Print';
            aePipelineController.selectCampaign = 'all';
            aePipelineController.buildPipelineData();

            aePipelineController.viewType = 'stage';
            aePipelineController.selectCampaign = 'all';
            aePipelineController.buildPipelineData();

            aePipelineController.viewType = 'product';
            aePipelineController.selectCampaign = 'only';
            aePipelineController.buildPipelineData();

            aePipelineController.selectedProdFamily = 'Online';
            aePipelineController.selectCampaign = 'only';
            aePipelineController.buildPipelineData();

            aePipelineController.selectedProdFamily = 'Print';
            aePipelineController.selectCampaign = 'only';
            aePipelineController.buildPipelineData();

            aePipelineController.viewType = 'stage';
            aePipelineController.selectCampaign = 'only';
            aePipelineController.buildPipelineData();

        }
    }
}