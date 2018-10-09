global class AddRemoveRatePlan implements zqu.SelectProductComponentOptions.IAddRemoveRatePlanPlugin{
   public void onAdd(String quoteId, List<String> addedRatePlans){
      List<zqu__ProductRatePlan__c> prp =
         [select Id,name from zqu__ProductRatePlan__c where id in :addedRatePlans and Name = 'Rate Plan 1'];
      if(prp.size() > 0){
         //If SomeSampleRatePlan is added, add Basic rate plan, as well.
         zqu__ProductRatePlan__c prp1 =
            [select Id,name from zqu__ProductRatePlan__c where Name = 'NY - Long Island - Photographers'];
         zqu.zChargeGroup zcg = zqu.zQuoteUtil.getChargeGroup((ID) quoteId, (ID)prp1.Id);
         zqu.zQuoteUtil.addChargeGroup(zcg);
      }
   }
     
   public void onRemove(String quoteId, List<String> removedRatePlans){
      List<zqu__ProductRatePlan__c> prp1 = [select Id,name from zqu__ProductRatePlan__c where id in :removedRatePlans and Name = 'SomeSampleRatePlan'];
      if(prp1.size() == 0){ //If the SomeSampleRatePlan is not in the list of rate plans to be removed     
         List<zqu__ProductRatePlan__c> prp =
            [select Id, Name from zqu__ProductRatePlan__c where id in :removedRatePlans and Name = 'Basic'];
         if(prp.size() > 0){
            //You cannot remove the Basic rate plan without removing the SomeSampleRatePlan.
            throw new zqu.PropertyComponentController.PropertyComponentPluginException
               ('The Rate Plan, '+prp[0].Name+', cannot be removed from the quote.');
         }
      }
   }
}