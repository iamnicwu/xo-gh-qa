public without sharing class EmailMessageTriggerHandler implements XOTrigger{
	// the related Case Id Set
	private Set<Id> caseIdSet = new Set<Id>();

	/**
	 * Method used to bulkify all data needed in any "before" action of a trigger. 
	 */
	public void bulkBefore() {}

	/**
	 *   Method used to bulkify all data needed in any "after" action of a trigger.
	 */
	public void bulkAfter() {}

	/**
	 *   All before insert logic should be done here. This method is called iteratively and as such
	 *   should contain no actions which could potentially hit limits or is considered bad practice 
	 *   in the Salesforce environment.
	 *   
	 *   @param  {SObject}   so Single SObject representation of the object being acted upon.
	 */
	public void beforeInsert(SObject so) {
	}

	/**
	*   All before update logic should be done here. This method is called iteratively and as such
	*   should contain no actions which could potentially hit limits or is considered bad practice
	*   in the Salesforce environment.
	*
	*   @param  {SObject}   oldSo Single SObject representation of the "old" copy of the current 
	*                             object being acted upon.
	*   @param  {SObject}   so    Single SObject representation of the object being acted upon.
	*/
	public void beforeUpdate(SObject oldSo, SObject so) {
	}

	/**
	*   All before delete logic should be done here. This method is called iteratively and as such
	*   should contain no actions which could potentilly hit limits or is considered bad practice
	*   in the Salesforce environment.
	*
	*   @param  {SObject}   so Single SObject representation of the object being acted upon.
	*/
	public void beforeDelete(SObject so) {}

	/**
	*   All after insert logic should be done here. This method is called iteratively and as such
	*   should contain no actions which could potentilly hit limits or is considered bad practice
	*   in the Salesforce environment. 
	*
	*   @param  {SObject}   so Single SObject representation of the object being acted upon.
	*/
	public void afterInsert(SObject so) {

			EmailMessage emaiMeassageObj = (EmailMessage)so;
			
			// Id relatedObiId = emaiMeassageObj.RelatedToId;
			if (String.isNotBlank(emaiMeassageObj.RelatedToId)) {
		    String objectType = String.valueOf(emaiMeassageObj.RelatedToId.getSobjectType());
				if (objectType == 'Case' && emaiMeassageObj.Status != 'Sent' && 
						String.isNotBlank(emaiMeassageObj.Subject) && 
						!String.valueOf(emaiMeassageObj.Subject).containsIgnoreCase('Outcome of cancel request') && 
						!String.valueOf(emaiMeassageObj.Subject).containsIgnoreCase('Customer Saved!')) {
					caseIdSet.add(emaiMeassageObj.RelatedToId);
				}
			}
	}

	/**
	*   All after update logic should be done here. This method is called iteratively and as such
	*   should contain no actions which could potentilly hit limits or is considered bad practice
	*   in the Salesforce environment.
	*   
	*   @param  {SObject}   oldSo Single SObject representation of the "old" copy of the current 
	*                             object being acted upon.
	*   @param  {SObject}   so    Single SObject representation of the object being acted upon.
	*/
	public void afterUpdate(SObject oldSo, SObject so) {}

	/**
	*   All after delete logic should be done here. This method is called iteratively and as such
	*   should contain no actions which could potentilly hit limits or is considered bad practice
	*   in the Salesforce environment. 
	*
	*   @param  {SObject}   so Single SObject representation of the object being acted upon.
	*/
	public void afterDelete(SObject so) {}

	/**
	*   All final logic in the "before" context should be done at this point such as modification to objects outside of
	*   the current object. At this point all updates to the current trigger transaction should be
	*   complete and all validation done.
	*/
	public void beforeAndFinally() {

	}

	/**
	*   All final logic in the "after" context should be done at this point such as modification to objects outside of
	*   the current object. At this point all updates to the current trigger transaction should be
	*   complete and all validation done.
	*/
	public void afterAndFinally() {
		List<XO_Exception__c> xoExceptionList = new List<XO_Exception__c>();

		if (!caseIdSet.isEmpty()) {
			List<Case> updateCaseList = [SELECT Id, CaseNumber, Status FROM Case WHERE Id in: caseIdSet AND IsClosed = TRUE];
			for (Case currentCase : updateCaseList) {
				currentCase.Status = 'Re-Opened';
			}
			if (!updateCaseList.isEmpty()) {
				List<Database.SaveResult> resultList = Database.update(updateCaseList);
				xoExceptionList.addAll(ExceptionUtility.consumeException(resultList));
			}
		}

		if (!xoExceptionList.isEmpty()) {
			insert xoExceptionList;
		}
	}
	
}