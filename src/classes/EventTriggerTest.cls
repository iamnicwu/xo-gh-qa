/* 
<class>
  <name>EventTriggerTest</name>
  <purpose>For testing save/delete events on a Event</purpose>
  <created>
    <by>Jonathan Satterfield</by>
    <date>6/4/2015</date>
    <ticket>SF-542</ticket>
  </created>
</class>
*/
@isTest
public class EventTriggerTest {
    
    /* 
    <method>
      <name>testBeforeInsert</name>
      <purpose>Test when a Event is created</purpose>
      <created>
        <by>Jonathan Satterfield</by>
        <date>6/4/2015</date>
        <ticket>SF-542</ticket>
      </created>
    </method>
    */
    static testMethod void testBeforeInsert() {
        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'Complete',
                                                 '{"companyName": "Test Account"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        

        Test.startTest();
        Map<String, SObject> testLocalData = TestClassUtility.buildLocalData(false);
        Test.stopTest();

        Opportunity testOpportunity = (Opportunity)testLocalData.get('Opportunity');
        
        List<Event> opportunityEvents = new List<Event>();
        
        for (Integer i=0; i<400; i++) {        
            Event t = new Event();
            t.OwnerId = UserInfo.getUserId();
            t.WhatId = testOpportunity.Id;
            t.Subject = 'Call';
            t.Type = 'Call';
            t.StartDateTime = Date.today();
            t.EndDateTime = Date.today();
            t.Event_Purpose__c = 'test';
            t.Opportunity_Stage__c = '';
            opportunityEvents.add(t);
        }
        
        insert opportunityEvents;
        
        Set<Id> opportunityEventIds = new Set<Id>();
        
        for (Event insertedEvent : opportunityEvents) {
            opportunityEventIds.add(insertedEvent.Id);
        }
        
        List<Event> insertedOpportunityEvents = [SELECT Id, Opportunity_Stage__c FROM Event WHERE Id in :opportunityEventIds];
        
        for (Event insertedEvent : insertedOpportunityEvents) {
            System.assert(insertedEvent.Opportunity_Stage__c == testOpportunity.StageName);
        }
    }
}