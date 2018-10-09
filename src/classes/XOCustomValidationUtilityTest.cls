@isTest
private class XOCustomValidationUtilityTest{
    @isTest static void test_method_one() {
        CountryZipREGEX__c czr = new CountryZipREGEX__c();
        czr.Active__c = true;
        czr.Name = 'United States';
        czr.CountryCode__c = 'US';
        czr.RegExPattern__c = '^\\d{5}(-\\d{4})?$';
        insert czr;
        
        account acc = new account();
        
        XOCustomValidationUtility.assignCountryBasedOnZip(acc, 'billingCountryCode', '99999');
        XOCustomValidationUtility.validZip('US', '99999');
        XOCustomValidationUtility.validZip('US', 'ad9sd 9999');
  }
  @isTest static void test_method_Two() {
        CountryZipREGEX__c czr = new CountryZipREGEX__c();
        czr.Active__c = false;
        czr.Name = 'United States';
        czr.CountryCode__c = 'US';
        czr.RegExPattern__c = '^\\d{5}(-\\d{4})?$';
        insert czr;
        
        account acc = new account();
        
        XOCustomValidationUtility.assignCountryBasedOnZip(acc, 'billingCountryCode', '99999');
        XOCustomValidationUtility.validZip('US', '99999');
        
  }

  @isTest static void testCanadianPostalCode() {
        CountryZipREGEX__c czr = new CountryZipREGEX__c();
        czr.Active__c = true;
        czr.Name = 'Canada';
        czr.CountryCode__c = 'CA';
        czr.RegExPattern__c = '^[ABCEGHJKLMNPRSTVXYabceghjklmnprstvxy]{1}\\d{1}[A-Za-z]{1} *(\\d{1}[A-Za-z]{1}\\d{1})?$';
        insert czr;

        String validCanadianPostalCode = 'A1A 1A1';
        String incompleteCanadianPostalCode = 'A1A';
        String invalidCanadianPostalCode = '11A AA1';

        System.assert(XOCustomValidationUtility.validZip('CA', validCanadianPostalCode));
        System.assert(XOCustomValidationUtility.validZip('CA', incompleteCanadianPostalCode));
        System.assert(!XOCustomValidationUtility.validZip('CA', invalidCanadianPostalCode));

        System.assert(XOCustomValidationUtility.hasCompleteCanadianZip('CA', validCanadianPostalCode));
        System.assert(!XOCustomValidationUtility.hasCompleteCanadianZip('CA', incompleteCanadianPostalCode));
        System.assert(XOCustomValidationUtility.hasCompleteCanadianZip('CA', invalidCanadianPostalCode));

  }

}