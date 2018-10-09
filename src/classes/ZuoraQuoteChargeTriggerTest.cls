/* 
<class>
  <name>ZuoraQuoteChargeTriggerTest</name>
  <purpose>For testing save/delete events on a Zuora QuoteCharge</purpose>
  <created>
    <by>Jonathan Satterfield</by>
    <date>7/22/2015</date>
    <ticket>SF-598, SF-599, SF-601</ticket>
  </created>
</class>
*/
@isTest
public class ZuoraQuoteChargeTriggerTest {
    /* 
    <method>
      <name>TestUpdateIDsForCommissionTracking</name>
      <purpose>Test the ZuoraQuoteChargeTriggerHandler.UpdateIDsForCommissionTracking method</purpose>
      <created>
        <by>Jonathan Satterfield</by>
        <date>7/22/2015</date>
        <ticket>SF-598, SF-599, SF-601</ticket>
      </created>
    </method>
    */
    static testMethod void TestUpdateIDsForCommissionTracking() {

    	Test.startTest();
        Map<String, SObject> testData =TestClassUtility.buildLocalData(false);
        Test.stopTest();
        Contact testContact = (Contact)testData.get('Contact');
        // first create and insert a zqu__Quote__c record
        zqu__Quote__c testQuote = new zqu__Quote__c();
        testQuote.Name = 'testQuote';
        testQuote.SalesRepId__c = '12345';
        testQuote.RenewalRepId__c = '12345';
        testQuote.RSD_Id__c = '11111';
        testQuote.zqu__BillToContact__c = testContact.Id;
        insert testQuote;

        // then create/attach/insert a zqu__QuoteCharge__c record
        zqu__QuoteCharge__c testQuoteCharge = new zqu__QuoteCharge__c();
        testQuoteCharge.zqu__Quote__c = testQuote.Id;
        insert testQuoteCharge;
        
        
        
        ZuoraQuoteChargeTriggerHandler2 zqcth2 = new ZuoraQuoteChargeTriggerHandler2();
        zqcth2.bulkAfter();
        //zqcth2.beforeInsert(testQuoteCharge);
        zqcth2.beforeUpdate(testQuoteCharge,testQuoteCharge);
        zqcth2.beforeDelete(testQuoteCharge);
        zqcth2.afterInsert(testQuoteCharge);
        zqcth2.afterUpdate(testQuoteCharge,testQuoteCharge);
        zqcth2.afterDelete(testQuoteCharge);
        
        zqcth2.andFinally();
    }
}