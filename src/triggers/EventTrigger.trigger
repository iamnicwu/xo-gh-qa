/* 
<trigger>
  <name>EventTrigger</name>
  <purpose>For handling save/delete events on an Event</purpose>
  <created>
    <by>Jonathan Satterfield</by>
    <date>6/17/2015</date>
    <ticket>SF-542</ticket>
  </created>
</trigger>
*/
trigger EventTrigger on Event (before insert) {
    
    // before insert
    if (Trigger.isBefore && Trigger.isInsert) {
        
        // populate a list of Event objects with Events related to Opportunities
        String opportunityObjectPrefix = Schema.SObjectType.Opportunity.getKeyPrefix();
        
        List<Event> newEventsForOpportunitiesList = new List<Event>();
        
        for (Event t : Trigger.new) {
            if (t.WhatId != null && ((String)t.WhatId).startsWith(opportunityObjectPrefix)) {
                newEventsForOpportunitiesList.add(t);
            }
        }
        
        if (!newEventsForOpportunitiesList.isEmpty()) {
            
            // populate a list of Opportunity objects related to the Events in the Event list from above
            Set<Id> opportunityIds = new Set<Id>();
            
            for (Event t : newEventsForOpportunitiesList) {
                opportunityIds.add(t.WhatId);
            }
            
            List<Opportunity> relatedOpportunitiesList = [SELECT Id, StageName FROM Opportunity WHERE Id in :opportunityIds];
            
            // populate a map of Opportunity Ids and the StageName for each Opportunity
            Map<Id, String> opportunityIdAndStageNameMap = new Map<Id, String>();
            
            for (Opportunity o : relatedOpportunitiesList) {
                opportunityIdAndStageNameMap.put(o.Id, o.StageName);
            }
            
            // lastly, assign the Opportunity StageName to the related Event's Opportunity Stage field
            for (Event t : newEventsForOpportunitiesList) {
                t.Opportunity_Stage__c = opportunityIdAndStageNameMap.get(t.WhatId);
            }
        }
    }
}