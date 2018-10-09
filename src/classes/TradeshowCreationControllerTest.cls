@isTest
private class TradeshowCreationControllerTest {
    
    static testMethod void createTradeShowDeal() {
      
      Map<String,SObject> testMap = TestClassUtility.buildLocalData(false);
      
      Campaign testCamp = new Campaign();
      testCamp.Name = label.TradeShow_Campaign_Name;
      insert testCamp;

      Test.startTest();
      Account testAcc = (Account)testMap.get('Account');

      test.setCurrentPageReference(Page.TradeshowCreation);
      System.currentPageReference().getParameters().put('id',testAcc.id);
      TradeshowCreationController testcase = new TradeshowCreationController();

      Contact newContact = new Contact();
      newContact.FirstName = 'test';
      newContact.LastName = 'test';
      testcase.newContact = newContact;

      testcase.save();
      testcase.cancel();
      testcase.getContactFields();
      testcase.getOppFields();
      Test.stopTest();

    }
}