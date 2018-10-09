/* 
<class>
  <name>NotesTriggerHandler</name>
  <purpose>For handling save/update and delete events on an Notes</purpose>
  <created>
    <by>Harikrishnan Mohan</by>
    <date>8/7/2015</date>
    <ticket>SF-791</ticket>
  </created>
</class>
*/

/*
public without sharing class NotesTriggerHandler implements ITrigger{

    private Map<Id,Schema.RecordTypeInfo> rtMapById = Schema.SObjectType.Opportunity.getRecordTypeInfosById();
    private Map<Id, Id> salesRepAccStratMap = new Map<Id, Id>();
    private Id pbId;
    private List<EntitySubscription> followOpportunityList = new List<EntitySubscription>();
    private Map<Id, Id> closedOppAccStratMap = new Map<Id, Id>();
    private Map<Id, Set<Id>> oppFollowersMap = new Map<Id, Set<Id>>();

    private List<National_Opp_Stage_Task_Email__c> nationalTaskOppStageMap = National_Opp_Stage_Task_Email__c.getAll().values();
    private Map<Id, National_Opp_Stage_Task_Email__c> oppIdStageTaskEmailMap = new Map<Id, National_Opp_Stage_Task_Email__c>();
    private List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();

    //Map with Opportunity and Created ThoughtStarter and RFP IDs for validation
    private Map<Id, Set<String>> oppIdTsRfpMap = new Map<Id, Set<String>>();

    //Map with Opportunity and Created ThoughtStarter and RFP IDs for validation
    private Map<Id, Set<String>> oppIdTsRfpCompletedMap = new Map<Id, Set<String>>();

    //Map of Stagae requiring full RFP or TS
    private Map<String, Stage_Requires_Complete_TS_RFP__c> stageRequireMap = Stage_Requires_Complete_TS_RFP__c.getAll();

    public Set<String> pList = new Set<String>();

    //String to hold the current users profile name
    public String cUsrPfl;
 
    // Constructor
    public NotesTriggerHandler(){

    }

    public void bulkBefore(){
      //cUsrPfl holds the current users profile name
      cUsrPfl = [Select id, Name from Profile where id=: userinfo.getProfileId()].Name;

      // Populate the SET "pList" with the list of profiles that are exempt from deleting Notes & Attachment
      for(ProfilesExemptDeletingNotesNAttachment__c p : ProfilesExemptDeletingNotesNAttachment__c.getAll().values()){
          pList.add(p.Name);
      }
    }
 
    public void bulkAfter(){
      
    }
 
    public void beforeInsert(SObject so){
      
    }
 
    public void beforeUpdate(SObject oldSo, SObject so){       
        Note record = (Note)so;
        Note oldRecord = (Note)oldSo;
        //Check if the SET contains the current users profile
        if(!pList.contains(cUsrPfl) && record.ownerid <> userinfo.getuserid()){
          record.addError('You do not have permission to modify the record. Please contact the owner of the record!');          
        }        
    }
 
    
    public void beforeDelete(SObject so){
    
    }
 
    public void afterInsert(SObject so){
      
    }
 
    public void afterUpdate(SObject oldSo, SObject so){
    
    }
 
    public void afterDelete(SObject so){
    
    }
 
    
    public void andFinally(){
        
    }
}

*/

public class NotesTriggerHandler implements XOTrigger{
  /* 
  <method>
    <name>modifyNotes</name>
    <purpose>If the Note on an object is modified by anybody other than the owner throw an error</purpose>
    <created>
      <by>Harikrishnan Mohan</by>
      <date>8/7/2015</date>
      <ticket>SF-791</ticket>
    </created>
  </method>
  */
  
  /*public static void modifyNotes(Note[] notes){
    Set<String> pList = new Set<String>();
    
    //retrieve and populate the current users profile name
    String cUsrPfl = [Select id, Name from Profile where id=: userinfo.getProfileId()].Name;
    
    // Populate the SET "pList" with the list of profiles that are exempt from not deleting Notes & Attachment
    for(ProfilesExemptDeletingNotesNAttachment__c p : ProfilesExemptDeletingNotesNAttachment__c.getAll().values()){
        pList.add(p.Name);
    }

    //Check if the SET contains the current users profile
    if(!pList.contains(cUsrPfl)){
      for(Note n : notes){
        if(n.ownerid <> userinfo.getuserid()){
            n.addError('You do not have permission to modify the record. Only the owner can modify the record!');
        }          
      }
    }
  }*/
  
  public NotesTriggerHandler() {
        
    }

    /**
    * bulkBefore
    *
    * This method is called prior to execution of a BEFORE trigger. Use this to cache
    * any data required into maps prior execution of the trigger.
    */
    
    public void bulkBefore(){

    }
    public void afterandfinally(){

    }
    public void beforeandfinally(){

    }

    public void bulkAfter(){

    }   
    
    public void beforeInsert(SObject so){

    }
 
    public void beforeUpdate(SObject oldSo, SObject so){

    }
    
    
    /**
    * beforeDelete
    *
    * This method is called iteratively for each record to be deleted during a BEFORE
    * trigger.
    */  
    
    
    public void beforeDelete(SObject so){
    
        Note notesRecords = (Note)so;
        
        Set<String> pList = new Set<String>();
        
        //retrieve and populate the current users profile name
        String cUsrPfl = [Select id, Name from Profile where id=: userinfo.getProfileId()].Name;
        
        // Populate the SET "pList" with the list of profiles that are exempt from not deleting Notes & Attachment
        for(ProfilesExemptDeletingNotesNAttachment__c p : ProfilesExemptDeletingNotesNAttachment__c.getAll().values()){
            pList.add(p.Name);
        }
    
        //Check if the SET contains the current users profile
        if(!pList.contains(cUsrPfl)){
            if(notesRecords.ownerid <> userinfo.getuserid()){
                notesRecords.addError('You do not have permission to modify the record. Only the owner can modify the record!');
            }          
        }
    
    }
 
    public void afterInsert(SObject so){
        
    }
    
    
    public void afterUpdate(SObject oldSo, SObject so){

    }
 
    public void afterDelete(SObject so){

    }   
    
    /**
    * andFinally
    *
    * This method is called once all records have been processed by the trigger. Use this
    * method to accomplish any final operations such as creation or updates of other records.
    */
    
   /* 
    public void andFinally(){
        
    }*/
}