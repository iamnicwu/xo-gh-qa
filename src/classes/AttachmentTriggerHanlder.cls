/* 
<class>
  <name>AttachmentTriggerHanlder</name>
  <purpose>For handling save/update and delete events on an Attachment</purpose>
  <created>
    <by>Harikrishnan Mohan</by>
    <date>8/7/2015</date>
    <ticket>SF-791</ticket>
  </created>
</class>
*/
public without sharing class AttachmentTriggerHanlder{

    public static Boolean forceDelete = false; 
    /* 
    <method>
      <name>modifyAttachments</name>
      <purpose>If the attachment on an object is modified by anybody other than the owner throw an error</purpose>
      <created>
        <by>Harikrishnan Mohan</by>
        <date>8/7/2015</date>
        <ticket>SF-791</ticket>
      </created>
    </method>
    */
    public static void modifyAttachments(Attachment[] attachments){        
        // csp-1833. If this flag is true, we skip all the other logic assoicated with this method.
        // We set this flag in deleteZuoraQuotePDFAttachmentsFromOpportunities
        if(forceDelete) {
            return;
        }

        Set<String> pList = new Set<String>();
        
        //retrieve and populate the current users profile name
        String cUsrPfl = [Select id, Name from Profile where id=: userinfo.getProfileId()].Name;
        
        // Populate the SET "pList" with the list of profiles that are exempt from deleting Notes & Attachment
        for(ProfilesExemptDeletingNotesNAttachment__c p : ProfilesExemptDeletingNotesNAttachment__c.getAll().values()){
            pList.add(p.Name);
        }
        
        //Check if the SET contains the current users profile
        if(!pList.contains(cUsrPfl)){
            for(Attachment a : attachments){
                // for CSP-369 and CSP-1623 we are allowing anyone to delete Zuora Quote PDFs, which contain the word "preview" or "PSB"
                if(a.ownerid <> userinfo.getuserid() && !a.Name.endsWithIgnoreCase('preview.pdf') && !a.Name.endsWithIgnoreCase('PSB.pdf')){
                    a.addError('You do not have permission to modify the record. Only the owner can modify the record!');
                }
            }        
        }
    }

    // CSP-369 | delete all Zuora Quote PDF attachments from the specified Opportunity records
    public static void deleteZuoraQuotePDFAttachmentsFromOpportunities(List<Id> oppIds) {

        List<Attachment> zuoraQuotePDFAttachmentsList = new List<Attachment>();

        for (Attachment a : [SELECT Id, Name, ParentId FROM Attachment WHERE ParentId IN :oppIds]) {
            if ((a.Name.endsWithIgnoreCase('preview.pdf')) || (a.Name.endsWithIgnoreCase('PSB.pdf'))) {
                zuoraQuotePDFAttachmentsList.add(a);
            }
        }

        if (!zuoraQuotePDFAttachmentsList.isEmpty()) {
            forceDelete = true;
            delete zuoraQuotePDFAttachmentsList;
        }
    }
}