/* 
<class>
  <name>EmailMessageDeleteAttachmentsController</name>
  <purpose>Manage Attachment belonging to EmailMessage</purpose>
  <created>
    <by>Steven Shen</by>
  </created>

  All logic for ticket 2976: Credit Card Update Forms Attaching to Cases
</class>
*/
public with sharing class EmailMessageDeleteAttachmentsController {
	// attachment list shown in page
	public List<AttachmentWrapper> totalAttachmentWrapperList {get; set;}

	// is Allowed to delete
	public Boolean isAllowedToDeleteAttachments {get;set;}

 	// current Email Message record
	private Id emailMessageId;
	private EmailMessage currentEmailMessage;

	// allowed profile names 
	private Set<String> allowedProfileNamesSet;

	// delimiter
	private static final String DELIMITER = '\r\n';

	// current user profile name
	private static final String currentUserProfileName = [SELECT Name FROM Profile WHERE Id =: UserInfo.getProfileId() LIMIT 1].Name;

	// attachment query string
  private static final String ATTACHMENT_QUERY = 	' SELECT'
																				        + ' Parent.RecordType.Name,'
																				        + ' Parent.CaseNumber,'
																				        + ' ParentId,'
																				        + ' Parent.Account.Name,'
																				        + ' Parent.AccountId,'
																				       	+   ' ('
	                                              +   ' SELECT'
	                                                  +   ' Id,'
	                                                  +   ' Name,'
	                                                  +   ' BodyLength,'                                                  
	                                                  +   ' LastModifiedDate,'
	                                                  +   ' CreatedById,'
	                                                  +   ' OwnerId'
	                                              		+   ' FROM'
	                                                  +   ' Attachments'
	                                          		+   ' )'
																				        +	' FROM'
																				        +	' EmailMessage'
																				        +	' WHERE'
																				        +	' {WHERECLAUSE}'
																				        + ' LIMIT 1';
	
  public EmailMessageDeleteAttachmentsController() { 
		emailMessageId = ApexPages.currentPage().getParameters().get('id');
		totalAttachmentWrapperList = new List<AttachmentWrapper>(); 
		isAllowedToDeleteAttachments = false;
		allowedProfileNamesSet = new Set<String>();

		if(String.isNotBlank(emailMessageId)){
			if(String.isNotBlank(Label.Delete_Attachments_Allowed_Profile_Names)){
				for(String profileName : Label.Delete_Attachments_Allowed_Profile_Names.split(DELIMITER)){
					allowedProfileNamesSet.add(profileName.trim());
				}
				if(allowedProfileNamesSet.contains(currentUserProfileName)){
					isAllowedToDeleteAttachments = true;
				}
			}
			doInit();
		}else{
			ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Invalid Id of EmailMessage record'));
		}
  }


	  /**
	   *   [do initial operation to retrieve attachment and wrapper attachment]
	   *
	   *   @author [Steven Shen]
	   *   @date   2018-07-11
	   *   @return [description]
	   */
	  public void doInit(){  
	  		totalAttachmentWrapperList.clear();
	      String attachmentQuery = ATTACHMENT_QUERY;
	      attachmentQuery = attachmentQuery.replace('{WHERECLAUSE}', 'Id = \'' + emailMessageId + '\'');
	      currentEmailMessage = Database.query(attachmentQuery);
				for(Attachment attTemp : currentEmailMessage.Attachments){
					totalAttachmentWrapperList.add(new AttachmentWrapper(currentEmailMessage, attTemp, false));
				}
	  }

	  /**
	   *   [delete selected attachments]
	   *
	   *   @author [Steven Shen]
	   *   @date   2018-07-11
	   *   @return [description]
	   */
		public PageReference deleteSelectedAttachments() {
			Map<Id, Attachment> attachmentMapToUpdate = new Map<Id, Attachment>();
			List<Attachment> attachmentListToUpdate = new List<Attachment>();
			List<XO_Exception__C> xoExceptionList = new List<XO_Exception__C>();

			for(AttachmentWrapper attWrapper : totalAttachmentWrapperList){
				if(attWrapper.isSelected == true){
					attachmentListToUpdate.add(attWrapper.attachment);
				}
			}
			
			// update owner of all attachments firstly
			if (!attachmentListToUpdate.isEmpty()) {
				for(Attachment att : attachmentListToUpdate){
					att.OwnerId = UserInfo.getUserId();
				}
				Database.SaveResult[] updateResults = Database.update(attachmentListToUpdate, false);
        xoExceptionList.addAll(ExceptionUtility.consumeException(updateResults));
				
				// then delete attachments after update
				Database.DeleteResult[] deleteResults = Database.delete(attachmentListToUpdate, false);
        xoExceptionList.addAll(ExceptionUtility.consumeException(deleteResults));
				if(xoExceptionList.size() > 0){
					insert xoExceptionList;
				}
      }
			return new PageReference('/' + emailMessageId);
		}

		// Wrapper to wrap the Checkbox value and Attachment record together  
		public class AttachmentWrapper{
			// parent case
			public EmailMessage parentEmailMessage {get;set;}
			// attachment
			public Attachment attachment {get; set;}
			//attachment size
			public String attachmentSize {get;set;}
			// selected to delete
			public Boolean isSelected {get; set;}

			public AttachmentWrapper(EmailMessage emailMessage, Attachment att, boolean isChecked){
				attachment = att;
				attachmentSize = (Integer.valueOf(att.BodyLength) < 1024) ? att.BodyLength + ' bytes' : String.ValueOf(Integer.valueOf(att.BodyLength)/1024) + 'KB';
				isSelected = isChecked;
				parentEmailMessage = emailMessage;
			}
		}
   
}