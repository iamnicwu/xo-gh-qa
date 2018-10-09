trigger CampaignMemberTrigger on CampaignMember(before insert, before update, before delete, after insert, after update, after delete) {
    XOTriggerFactory.createAndExecuteHandler(CampaignMemberTriggerHandler.class);
}