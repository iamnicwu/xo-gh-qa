/* 
<Class>
  <name>BatchConvertWaitlistToInventory</name>
  <purpose>Convert waitlist records to inventory records
  </purpose>
  <created>
    <by>Jonathan Satterfield</by>
    <date>03/07/2016</date>
    <ticket>CSP-576</ticket>
  </created>
</Class>
*/
global class BatchConvertWaitlistToInventory implements Database.Batchable<sObject> {

  public String query;
    public Date invHoldExpDate;

  global BatchConvertWaitlistToInventory() {

    // assign value to the public invHoldExpDate variable
      Inventory_Hold_Expiry_Date_Offsets__c invHoldExpDateOffsets = Inventory_Hold_Expiry_Date_Offsets__c.getOrgDefaults();
      DateTime myDateTime = (DateTime)Date.today();
      String dayOfWeek = myDateTime.format('EEEE');
      invHoldExpDate = DateUtility.AddBusinessDays(Date.Today(), (Integer)invHoldExpDateOffsets.Account_Day_Offset__c);

      // assign value to the public query variable
      // CSP-3013 Waitlist Audit
      // For the waitlist audit, we only query the active waitlist to convert to Inventory.
      query = ' SELECT '
                + 'Id, '
                + 'Name, '
                + 'Capacity__c, '
                + 'Available__c, '
                + 'Number_Available__c, '
                + 'Inventory_Held__c, '
                + 'Waitlist_Count__c, '
                + '(SELECT '
                    + 'Id, '
                    + 'Account__c, '
                    + 'Product_Rate_Plan__c, '
                    + 'Is_Active__c, '
                    + 'Inactive_Reason__c '
                  + 'FROM '
                    + 'Waitlists__r '
                  + 'WHERE '
                    + 'Is_Active__c = TRUE '
                    + 'ORDER BY Sort_Order__c) '
              + 'FROM '
                + 'zqu__ProductRatePlan__c '
              + 'WHERE ' 
                + 'Available__c = TRUE '
              + 'AND '
                + 'Waitlist_Count__c > 0';
  }

  global Database.QueryLocator start(Database.BatchableContext BC) {
    return Database.getQueryLocator(query);
  }

  global void execute(Database.BatchableContext BC, List<zqu__ProductRatePlan__c> scope) {

    List<Inventory__c> inventoryInsertList = new List<Inventory__c>();
    List<Waitlist__c> waitlistUpdateList = new List<Waitlist__c>();

    // this list is initially populated with waitlist records to delete
    // after the inventory records are created, the result objects are iterated through
    // and for successful inserts, the associated record in this temp list is added to the waitlistDeleteList
    List<Waitlist__c> tempWaitlistUpdateList = new List<Waitlist__c>();

    for (zqu__ProductRatePlan__c prpRec : scope) {
      for (Integer i = 0; i < prpRec.Waitlists__r.size(); i++) {
        if (i == (Integer)prpRec.Number_Available__c) {   // numAvailableSlots will always at least start at 1
          break;
        }
        else {
          // TODO: do we need to do anything with the remaining Waitlist records' sort order?
          Inventory__c inv = new Inventory__c();
          Waitlist__c w = prpRec.Waitlists__r[i];
          inv.Product_Rate_Plan__c = w.Product_Rate_Plan__c;
          inv.Waitlist_Account__c = w.Account__c;
          inv.Inventory_Hold_Expiry_Date__c = invHoldExpDate;
          inv.Date_Reserved__c = Date.today();

          inventoryInsertList.add(inv);
          // CSP-3013 Waitlist Audit
          // we marked the waitlist to inactive when it has been converted to inventory
          w.Is_Active__c = FALSE;
          w.InActive_Date__c = Date.today();
          w.Inactive_Reason__c = 'Converted to Inventory';
          tempWaitlistUpdateList.add(w);
        }
      }
    }

     // insert the inventory records, then populate the waitlistDeleteList
     List<Database.SaveResult> invSRList = Database.insert(inventoryInsertList, false);

     for (Integer i = 0; i < invSRList.size(); i++) {
       if (invSRList[i].isSuccess()) {
         waitlistUpdateList.add(tempWaitlistUpdateList[i]);
       }
     }
     // CSP-3013 Waitlist Audit
     // If the label Deleted_Converted_Waitlist set to "Yes", we delete the waitlist which has been converted to inventory
     String isDeleteWaitlist = Label.Deleted_Converted_Waitlist;
     if (isDeleteWaitlist.containsIgnoreCase('No')) {
       Database.Update(waitlistUpdateList, false);
     }
     // If the label Deleted_Converted_Waitlist set to "No", we delete the waitlist which has been converted to inventory
     else {
      Database.delete(waitlistUpdateList, false);
     }
     
    }
     
  global void finish(Database.BatchableContext BC) {
    // nothing for now
  }
}