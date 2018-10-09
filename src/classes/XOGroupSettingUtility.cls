public with sharing class XOGroupSettingUtility {
	private static XO_Group_Settings__c xoSetting = XO_Group_Settings__c.getInstance();

	public XOGroupSettingUtility() {
		
	}

	public static Boolean getPartnerCalloutSetting(){
		if(xoSetting == null){
			return false;
		}
		return xoSetting.Turn_on_Fulfillment_Callouts__c;
	}

	public static Map<String, String> lpSFMarketCodeMap(){
		Map<String, String> codeMap = new Map<String, String>();
		for(SF_LP_Market_Code_Map__c record : SF_LP_Market_Code_Map__c.getAll().values()){
            codeMap.put(record.Partners_Market_Code_Map__c, record.Salesforce_Market_Code__c);
        }
        return codeMap;
	}

	public static Map<String, String> sfLPMarketCodeMap(){
		Map<String, String> codeMap = new Map<String, String>();
		for(SF_LP_Market_Code_Map__c record : SF_LP_Market_Code_Map__c.getAll().values()){
            codeMap.put(record.Salesforce_Market_Code__c, record.Partners_Market_Code_Map__c);
        }
        return codeMap;
	}

	public static Boolean alwaysSetCreditHoldToFalse() {
		return xoSetting.Always_Set_Credit_Hold_To_False__c;
	}

	public static Boolean alwaysSetGeocodeOverrideToTrue() {
		return xoSetting.Always_Set_Geocode_Override_To_True__c;
	}
}