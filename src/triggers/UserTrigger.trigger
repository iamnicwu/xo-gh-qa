trigger UserTrigger on User (after update) {
    
    if (Trigger.isAfter && Trigger.isUpdate) {
        // CSP-596 | for all user's who had their ARR updated,
        // update the CBSS lookup on Local Account's they own (when applicable
        Set<Id> updatedARRUserIdSet = new Set<Id>();
        // Set<Id> arrIdSet = new Set<Id>();
        for (User newUserRec : Trigger.new) {
            // CSP-2315 Update CBSS Information on Account and Billing Account
            User oldUserRecord = Trigger.oldMap.get(newUserRec.Id);
            if (newUserRec.ARR__c != oldUserRecord.ARR__c || newUserRec.Phone != oldUserRecord.Phone || 
                !(newUserRec.FirstName + newUserRec.LastName).equals(oldUserRecord.FirstName + oldUserRecord.LastName) ) {
                updatedARRUserIdSet.add(newUserRec.Id);
                // arrIdSet.add(newUserRec.ARR__c);
            }
        }
		if (!updatedARRUserIdSet.isEmpty()) {
            System.debug(LoggingLevel.INFO, '*** updatedARRUserIdSet: ' + updatedARRUserIdSet);
			BatchUpdateLocalAccountCBSS accountCBSSBatchJob = new BatchUpdateLocalAccountCBSS(updatedARRUserIdSet);
			Database.ExecuteBatch(accountCBSSBatchJob, 200);
		}
    }
}