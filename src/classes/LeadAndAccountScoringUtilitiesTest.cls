@isTest
private class LeadAndAccountScoringUtilitiesTest {
    
    @isTest
    static void test_method_one() {
        // for this custom setting it doesn't make sense to add it to the TestClassUtility
        // since (A) incorrect data can potentially break other tests, and (B) other test 
        // classes won't need Lead_and_Account_Scoring__c custom setting records
        List<Lead_and_Account_Scoring__c> leadAndAccountScoringInsertList = new List<Lead_and_Account_Scoring__c>();
        
        // Not Blank
        Lead_and_Account_Scoring__c notBlankRule = new Lead_and_Account_Scoring__c();
        notBlankRule.Name = 'Name Not Blank';
        notBlankRule.Apply_to_Lead_Score__c = true;
        notBlankRule.Apply_to_Account_Score__c = true;
        notBlankRule.Comparison_Type__c = 'Not Blank';
        notBlankRule.Points__c = 5;
        notBlankRule.Field_API_Name__c = 'Name';
        leadAndAccountScoringInsertList.add(notBlankRule);

        // Regex
        Lead_and_Account_Scoring__c regexRule = new Lead_and_Account_Scoring__c();
        regexRule.Name = 'Phone Regex 10-11 Numbers';
        regexRule.Apply_to_Lead_Score__c = true;
        regexRule.Apply_to_Account_Score__c = false;
        regexRule.Comparison_Type__c = 'Regex';
        regexRule.Comparison_Value__c = '\\D*?(\\d\\D*?){10,11}';
        regexRule.Points__c = 5;
        regexRule.Field_API_Name__c = 'Phone';
        leadAndAccountScoringInsertList.add(regexRule);

        // Contains
        Lead_and_Account_Scoring__c containsRule = new Lead_and_Account_Scoring__c();
        containsRule.Name = 'Email Contains "@mailinator.com"';
        containsRule.Apply_to_Lead_Score__c = true;
        containsRule.Apply_to_Account_Score__c = false;
        containsRule.Comparison_Type__c = 'Contains';
        containsRule.Comparison_Value__c = '@mailinator.com';
        containsRule.Points__c = 5;
        containsRule.Field_API_Name__c = 'Email';
        leadAndAccountScoringInsertList.add(containsRule);

        // Does Not Contain
        Lead_and_Account_Scoring__c doesNotContainRule = new Lead_and_Account_Scoring__c();
        doesNotContainRule.Name = 'FirstName Does Not Contain "Name"';
        doesNotContainRule.Apply_to_Lead_Score__c = true;
        doesNotContainRule.Apply_to_Account_Score__c = false;
        doesNotContainRule.Comparison_Type__c = 'Does Not Contain';
        doesNotContainRule.Comparison_Value__c = 'Name';
        doesNotContainRule.Points__c = 5;
        doesNotContainRule.Field_API_Name__c = 'FirstName';
        leadAndAccountScoringInsertList.add(doesNotContainRule);

        // Does Not Equal
        Lead_and_Account_Scoring__c doesNotEqualRule = new Lead_and_Account_Scoring__c();
        doesNotEqualRule.Name = 'FirstName Does Not Equal "Name"';
        doesNotEqualRule.Apply_to_Lead_Score__c = true;
        doesNotEqualRule.Apply_to_Account_Score__c = false;
        doesNotEqualRule.Comparison_Type__c = 'Does Not Equal';
        doesNotEqualRule.Comparison_Value__c = 'Name';
        doesNotEqualRule.Points__c = 5;
        doesNotEqualRule.Field_API_Name__c = 'FirstName';
        leadAndAccountScoringInsertList.add(doesNotEqualRule);

        // Equals
        Lead_and_Account_Scoring__c equalsRule = new Lead_and_Account_Scoring__c();
        equalsRule.Name = 'FirstName Equals "Jimmy"';
        equalsRule.Apply_to_Lead_Score__c = true;
        equalsRule.Apply_to_Account_Score__c = false;
        equalsRule.Comparison_Type__c = 'Equals';
        equalsRule.Comparison_Value__c = 'Jimmy';
        equalsRule.Points__c = 100;
        equalsRule.Field_API_Name__c = 'FirstName';
        leadAndAccountScoringInsertList.add(equalsRule);

        Database.insert(leadAndAccountScoringInsertList, false);


        Market__c testMarket = TestClassUtility.createMarket(false);
        testMarket.Market_ID__c = '222'; //Shashish: Market Id 222 is hardcoded in LeadLocalTriggerhandler
        testMarket.Active__c = true;
        insert testMarket;

        Map<String,Schema.RecordTypeInfo> rtCategoryMapByName = Schema.SObjectType.Category__c.getRecordTypeInfosByName();
        Category__c testCategory = TestClassUtility.createCategory(false);
        testCategory.RecordTypeId = rtCategoryMapByName.get('Local').getRecordTypeId();
        testCategory.Category_Group__c = 'Primary';
        insert testCategory;
        
        // Create Lead
        Lead leadRecord = TestClassUtility.createLead(false,testMarket,testCategory);
        leadRecord.Phone = '916-247-2244';
        insert leadRecord;

        // Create Account
        Account accountRecord = TestClassUtility.createAccount(true);        

        Test.startTest();
        LeadAndAccountScoringUtilities.getLeadScoringFieldsNameSet();
        LeadAndAccountScoringUtilities.getAccountScoringFieldsNameSet();
        LeadAndAccountScoringUtilities.scoreLeadsFutureJob(new Set<Id>{leadRecord.Id});
        LeadAndAccountScoringUtilities.scoreAccountsFutureJob(new Set<Id>{accountRecord.Id});
        Database.executeBatch(new BatchScoreLeadsAndAccounts(true, true));
        Test.stopTest();
    }
}