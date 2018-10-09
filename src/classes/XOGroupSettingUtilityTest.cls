@isTest
private class XOGroupSettingUtilityTest{
    @isTest static void test_method_one() {
        XO_Group_Settings__c xoSetting = XO_Group_Settings__c.getInstance();
        xoSetting.Turn_on_Fulfillment_Callouts__c = true;
        upsert xoSetting;
        
        XOGroupSettingUtility XOGSU = new XOGroupSettingUtility();
        Boolean PartnerCallout = XOGroupSettingUtility.getPartnerCalloutSetting();
        Boolean alwaysSetCreditHold = XOGroupSettingUtility.alwaysSetCreditHoldToFalse();
        Boolean alwaysSetGeocodeOverride = XOGroupSettingUtility.alwaysSetGeocodeOverrideToTrue();
        
        SF_LP_Market_Code_Map__c sf = new SF_LP_Market_Code_Map__c();
        sf.name = 'test';
        sf.Partners_Market_Code_Map__c = '123';
        sf.Salesforce_Market_Code__c = '223';
        insert sf;
        
        Map<String, String> sfLPMarketCodeMap = XOGroupSettingUtility.sfLPMarketCodeMap();
        Map<String, String> lpSFMarketCodeMap = XOGroupSettingUtility.lpSFMarketCodeMap();
    }
   
}