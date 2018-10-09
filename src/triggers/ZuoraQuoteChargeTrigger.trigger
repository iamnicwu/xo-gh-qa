/* 
<trigger>
  <name>ZuoraQuoteChargeTrigger</name>
  <purpose>For handling save/update events on Zuora QuoteCharge records</purpose>
  <created>
    <by>Jonathan Satterfield</by>
    <date>7/22/2015</date>
    <ticket>SF-598, SF-599, SF-601</ticket>
  </created>
</trigger>
*/
trigger ZuoraQuoteChargeTrigger on zqu__QuoteCharge__c (before insert) {
	if (Trigger.isBefore) {
		if (Trigger.isInsert) {
			ZuoraQuoteChargeTriggerHandler.UpdateIDsForCommissionTracking(Trigger.new);
		}
	}
}