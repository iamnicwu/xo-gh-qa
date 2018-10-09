Public Class OpportunityTriggerhelper{


public boolean CheckOpptEditable(){

String profileName=[Select Id,Name from Profile where Id=:UserInfo.getProfileId()].Name;
string sId = ApexPages.currentPage().getParameters().get('retURL');

system.debug('=====>'+profileName+sId);
return null;
}
}