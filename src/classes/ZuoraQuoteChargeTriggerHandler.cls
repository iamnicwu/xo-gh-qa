/* 
<class>
  <name>ZuoraQuoteChargeTriggerHandler</name>
  <purpose>For handling save/update events on Zuora QuoteCharge records</purpose>
  <created>
    <by>Jonathan Satterfield</by>
    <date>7/22/2015</date>
    <ticket>SF-598, SF-599, SF-601</ticket>
  </created>
</class>
*/
public class ZuoraQuoteChargeTriggerHandler {
    /* 
    <method>
      <name>UpdateIDsForCommissionTracking</name>
      <purpose>When QuoteCharge records are created (when a Quote for new products is saved), record the
      SalesRepId, RenewalRepId, and the RSD_Id from the Quote on each QuoteCharge record</purpose>
	  <created>
	    <by>Jonathan Satterfield</by>
	    <date>7/22/2015</date>
	    <ticket>SF-598, SF-599, SF-601</ticket>
	  </created>
    </method>
    */
	public static void UpdateIDsForCommissionTracking(List<zqu__QuoteCharge__c> newQuoteChargeList) {
		Set<Id> parentQuoteIdSet = new Set<Id>();
		for (zqu__QuoteCharge__c newQC : newQuoteChargeList) {
			parentQuoteIdSet.add(newQC.zqu__Quote__c);
		}

		Map<Id,zqu__Quote__c> parentQuoteMap = new Map<Id,zqu__Quote__c>([SELECT Id, SalesRepId__c, RenewalRepId__c, RSD_Id__c FROM zqu__Quote__c WHERE Id IN :parentQuoteIdSet]);

		for (zqu__QuoteCharge__c qc : newQuoteChargeList) {
			if (qc.zqu__Quote__c != null) {
				zqu__Quote__c tempQuote = parentQuoteMap.get(qc.zqu__Quote__c);
				qc.SalesRepId__c = tempQuote.SalesRepId__c;
				qc.RenewalRepId__c = tempQuote.RenewalRepId__c;
				qc.RSD_Id__c = tempQuote.RSD_Id__c;
			}
		}
	}
}