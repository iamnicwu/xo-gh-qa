@isTest
private class DataUtilityTest {
		@testSetup static void createTestData(){
			TestClassUtility.generateQuotePdfConfig(true);
		}

		static testMethod void testBuildPicklistEntryMap() {  

			Test.startTest();

			Map<String,String> resultPositive = DataUtility.buildPicklistEntryMap('Account', 'BillingCountryCode');

			Map<String,String> resultNegative = DataUtility.buildPicklistEntryMap('Account', 'BillingCountryCode');

			Test.stopTest();

			system.assert(resultPositive.size() > 0);
			system.assert(resultNegative.size() > 0);
		}

		static testMethod void testValidateWebsite() {  

			Test.startTest();

			DataUtility.ValidationResult resultPositive = DataUtility.validateWebsite('www.test.com');

			DataUtility.ValidationResult resultNegative = DataUtility.validateWebsite('testInvalidWebsite');

			DataUtility.ValidationResult resultNegative2 = DataUtility.validateWebsite('');

			Test.stopTest();

			system.assert(resultPositive.valid == true);
			system.assert(resultNegative.valid == false);
			system.assert(resultNegative2.valid == false);
		}

		static testMethod void testGetOnlyNumbers() {  

			Test.startTest();

			String resultPositive = DataUtility.getOnlyNumbers('123456789');

			String resultNegative = DataUtility.getOnlyNumbers('test123');

			String resultNegative2 = DataUtility.getOnlyNumbers('');

			Test.stopTest();

			system.assert(resultPositive == '123456789');
			system.assert(resultNegative == '123');
			system.assert(resultNegative2 == '');
		}

		static testMethod void testFormatExt() {  

			Test.startTest();

			DataUtility.ValidationResult resultPositive = DataUtility.formatExt('123456789');

			DataUtility.ValidationResult resultNegative = DataUtility.formatExt('test123');

			Test.stopTest();

			system.assert(resultPositive.valid == true);
			system.assert(resultNegative.valid == false);
		}

		static testMethod void testFormatPhoneNumber() {  

			Test.startTest();

			DataUtility.ValidationResult resultPositive = DataUtility.formatPhoneNumber('1234567890');

			DataUtility.ValidationResult resultNegative = DataUtility.formatPhoneNumber('test123');

			DataUtility.ValidationResult resultNegative2 = DataUtility.formatPhoneNumber('');

			Test.stopTest();

			system.assert(resultPositive.valid == true);
			system.assert(resultNegative.valid == false);
			system.assert(resultNegative2.valid == false);
		}

		static testMethod void testGetDefaultCanadaMarket() {  
			Map<String, Market__c> marketIdObjMap = new Map<String, Market__c>();

			Map<String, Canadian_Postal_Code_Market_Mapping__c> canadaMarketMap = new Map<String, Canadian_Postal_Code_Market_Mapping__c>();

			Map<String, String> stateCodeMarketIdMap = new Map<String, String>();
			
			Market__c testCAMarketQC = TestClassUtility.createMarket(false);
      testCAMarketQC.Name = 'QC-303';
      testCAMarketQC.Market_ID__c = '303';
      testCAMarketQC.Active__c = true;
      testCAMarketQC.Country__c = 'CA';

      Market__c testCAMarketNB = TestClassUtility.createMarket(false);
      testCAMarketNB.Name = 'NB-308';
      testCAMarketNB.Market_ID__c = '308';
      testCAMarketNB.Active__c = true;
      testCAMarketNB.Country__c = 'CA';
      insert new List<Market__c>{testCAMarketQC, testCAMarketNB};

      Canadian_Postal_Code_Market_Mapping__c testJ1Setting = new Canadian_Postal_Code_Market_Mapping__c();
      testJ1Setting.Canadian_Postal_Code__c = 'J1';
      testJ1Setting.Name = 'J1-QC-303';
      testJ1Setting.Market_Id__c = '303';
      testJ1Setting.Default_State_Code__c = 'QC';

      Canadian_Postal_Code_Market_Mapping__c testESetting = new Canadian_Postal_Code_Market_Mapping__c();
      testESetting.Canadian_Postal_Code__c = 'E';
      testESetting.Name = 'E-NB-308';
      testESetting.Market_Id__c = '308';
      testESetting.Default_State_Code__c = 'NB';
      insert new List<Canadian_Postal_Code_Market_Mapping__c>{testJ1Setting, testESetting};

			for(Market__c canadianMarket : [SELECT Id, Market_Id__c FROM Market__c WHERE Country__c = 'CA']){
				marketIdObjMap.put(canadianMarket.Market_ID__c, canadianMarket);
			}

      for(Canadian_Postal_Code_Market_Mapping__c canadaMarket : Canadian_Postal_Code_Market_Mapping__c.getAll().values()) {
         canadaMarketMap.put(canadaMarket.Canadian_Postal_Code__c, canadaMarket);
         if(String.isNotBlank(canadaMarket.Default_State_Code__c)) {
             stateCodeMarketIdMap.put(canadaMarket.Default_State_Code__c, canadaMarket.Market_Id__c);
         }
      }

			Test.startTest();

			Market__c resultPositive = DataUtility.getDefaultCanadaMarket('J1J','QC', marketIdObjMap, canadaMarketMap, stateCodeMarketIdMap);

			Market__c resultPositive2 = DataUtility.getDefaultCanadaMarket('E1E','NB', marketIdObjMap, canadaMarketMap, stateCodeMarketIdMap);

			Market__c resultPositive3 = DataUtility.getDefaultCanadaMarket('','QC', marketIdObjMap, canadaMarketMap, stateCodeMarketIdMap);

			Market__c resultNegative = DataUtility.getDefaultCanadaMarket('','', marketIdObjMap, canadaMarketMap, stateCodeMarketIdMap);

			Test.stopTest();

			system.assert(resultPositive.Market_ID__c == '303');
			system.assert(resultPositive2.Market_ID__c == '308');
			system.assert(resultPositive3.Market_ID__c == '303');
			system.assert(resultNegative == null);
		}
}