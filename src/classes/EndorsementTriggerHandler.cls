public without sharing class EndorsementTriggerHandler implements XOTrigger{
	
	Set<Id> endorsementIdset = new Set<Id>();
	/**
     * Method used to bulkify all data needed in any "before" action of a trigger.
     */
    public void bulkBefore() {
        
    }
    
    /**
     *   Method used to bulkify all data needed in any "after" action of a trigger.
     */
    public void bulkAfter() {
		
    }
    
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
    public void beforeDelete(SObject so) {

    }

    /**
    *   All after insert logic should be done here. This method is called iteratively and as such
    *   should contain no actions which could potentilly hit limits or is considered bad practice
    *   in the Salesforce environment. 
    *
    *   @param  {SObject}   so Single SObject representation of the object being acted upon.
    */
    public void afterInsert(SObject so) {
    	Endorsement__c endObj = (Endorsement__c) so;
		if(String.isBlank(endObj.EndorsementId__c) && String.isNotBlank(endObj.Account__c)){
            endorsementIdset.add(endObj.id);
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
    public void afterUpdate(SObject oldSo, SObject so) {

    }

    /**
    *   All after delete logic should be done here. This method is called iteratively and as such
    *   should contain no actions which could potentilly hit limits or is considered bad practice
    *   in the Salesforce environment. 
    *
    *   @param  {SObject}   so Single SObject representation of the object being acted upon.
    */
    public void afterDelete(SObject so) {

    }

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
		if(!endorsementIdset.isEmpty() && !System.isBatch() && !System.isFuture()){
			createOppAndUpdateEndorsement(endorsementIdset);
		}
    }

    //////////////////////////
    // CUSTOM METHODS BELOW //
    //////////////////////////
    
    /**
     * CSP-1374 : method helps to create Opportunity and update Endorsement with the related opportunity Id.
     *
     */
    @future
    private static void createOppAndUpdateEndorsement(Set<Id> endorsementIdset){
    	List<Endorsement__c> endorsementList = [SELECT Id, Name, Type__c, RecordTypeId, RecordType.Name, Account__c, Account__r.OwnerId, Opportunity__c
    											FROM Endorsement__c WHERE Id IN: endorsementIdset];
    											
    	//Create Opportunity for All the new Endorsement.
    	Map<String, Opportunity> opportunityInsertMap = createOpportunityForEndorsement(endorsementList);
    	if(opportunityInsertMap.size() > 0){
    		insert opportunityInsertMap.values();
    		
    		for(Endorsement__c endObj : endorsementList){
    			//String mapKey = endObj.Type__c+endObj.RecordTypeId+endObj.Account__c;
    			endObj.Opportunity__c = opportunityInsertMap.get(endObj.id).id;
    		}
    		
    		update endorsementList;
    	}
    }
    
    /**
     * Create an opportunity for the respective Endorsement.
     *
     */
    private static Map<String, Opportunity> createOpportunityForEndorsement(List<Endorsement__c> newEndorsementList){
    	Map<String, Opportunity> opportunityInsertMap = new Map<String, Opportunity>();
    	for(Endorsement__c endorsementObj : newEndorsementList){
    		Opportunity oppObj = new Opportunity();
    		String marketName = endorsementObj.RecordType.Name;
			oppObj.Name = endorsementObj.Type__c != null? endorsementObj.Type__c+ ' '+marketName : marketName;
			oppObj.AccountId = endorsementObj.Account__c;
			oppObj.CloseDate = findCurrentQuarterEndDate();
			oppObj.Stagename = 'Prospecting';
			oppObj.Type = 'Upsell';
			oppObj.OwnerId = endorsementObj.Account__r.OwnerId;
			opportunityInsertMap.put(endorsementObj.Id, oppObj);
    	}
    	return opportunityInsertMap;
    }
    
    /**
     * method helps to find the current Quarter End Date.
     *
     */
    private static date findCurrentQuarterEndDate(){
    	Date dt = date.today();
		Integer currentMnt =dt.month();
		Integer currentQ =((currentMnt-1)/3) + 1;
		Date endOfQDate = date.newInstance(dt.year(),currentMnt + (4 - (currentMnt - ((currentQ -1)*3))) , 1).addDays(-1);
		return endOfQDate;
    }
}