public class MigratedSubscriptionInventoryQueuedJob {

//  ------------------------------------------------------------------------------------------------------------------
    /**
     * @Desc:   
     */
    @future(callout=true)
    public static void FutureChaining() {
        System.enqueueJob(new MigratedSubscriptionInventoryQueuedJob.QueueableOne());
    }

//  ------------------------------------------------------------------------------------------------------------------
    /**
     * @Desc:   
     */
      public class QueueableOne implements Queueable, Database.AllowsCallouts {
            
        /**
         * @Desc: Overriden execute Method from Queueable interface.
         */
        public void execute(QueueableContext context) {
            
            Zuora.ZApi zApiInstance = new Zuora.ZApi();
            // skip the login call if this is a test
            if (!Test.isRunningTest()) {
                Zuora.zApi.LoginResult loginResult = zApiInstance.zlogin();
            }

            Boolean queueAnotherJob = False;

            List<Zuora__SubscriptionProductCharge__c> newSPCList = [SELECT Id, Zuora__Zuora_Id__c, Zuora_Id_of_Migrated_Charge__c, Zuora__RatePlanName__c, Zuora__RatePlanId__c, Zuora__Subscription__r.Zuora__TermEndDate__c FROM Zuora__SubscriptionProductCharge__c WHERE Zuora_Id_of_Migrated_Charge__c != null LIMIT 101];

            if (!newSPCList.isEmpty()) {
                // max # of records that can be processed per job is 5000,
                // but if set to 5000 the job tends to time out,
                // so if more than 101 records returned, queue another job once this one is complete
                if (newSPCList.size() == 101) {
                    newSPCList.remove(100);
                    queueAnotherJob = True;
                }

                Map<String,Zuora__SubscriptionProductCharge__c> newSPCMap = new Map<String,Zuora__SubscriptionProductCharge__c>();
                Map<String,Zuora__SubscriptionProductCharge__c> oldSPCMap = new Map<String,Zuora__SubscriptionProductCharge__c>();
                Map<String,List<Zuora__SubscriptionProductCharge__c>> newSPCRecsWithoutAMigratedSPCRecMap = new Map<String,List<Zuora__SubscriptionProductCharge__c>>();
                List<Inventory__c> newInventoryList = new List<Inventory__c>();
                List<Zuora__SubscriptionProductCharge__c> spcWithNewInventoryUpdateList = new List<Zuora__SubscriptionProductCharge__c>();

                for (Zuora__SubscriptionProductCharge__c spcRecord : newSPCList) {
                    newSPCMap.put(spcRecord.Zuora_Id_of_Migrated_Charge__c, spcRecord);
                }

                for (Zuora__SubscriptionProductCharge__c oldSPCRecord : [SELECT Id, Do_not_create_inventory__c, Zuora__Zuora_Id__c FROM Zuora__SubscriptionProductCharge__c WHERE Zuora__Zuora_Id__c IN :newSPCMap.keySet()]) {
                    oldSPCMap.put(oldSPCRecord.Zuora__Zuora_Id__c, oldSPCRecord);
                }

                // CSP-919 | if an associated Migrated SPC record isn't in the oldSPCMap, set it aside for later processing
                // (aka create an inventory record and set the record's Zuora_Id_of_Migrated_Charge__c to an empty string)
                // newSPCRecsWithoutAMigratedSPCRecMap key = Zuora__RatePlanName__c, value = list of records
                for (String newSPCMapKey : newSPCMap.keySet()) {
                    if (!oldSPCMap.containsKey(newSPCMapKey)) {
                        Zuora__SubscriptionProductCharge__c zSPC = newSPCMap.remove(newSPCMapKey);
                        List<Zuora__SubscriptionProductCharge__c> zSPCList = newSPCRecsWithoutAMigratedSPCRecMap.containsKey(zSPC.Zuora__RatePlanName__c) ? newSPCRecsWithoutAMigratedSPCRecMap.get(zSPC.Zuora__RatePlanName__c) : new List<Zuora__SubscriptionProductCharge__c>();
                        zSPCList.add(zSPC);
                        newSPCRecsWithoutAMigratedSPCRecMap.put(zSPC.Zuora__RatePlanName__c, zSPCList);
                    }
                }

                if (!newSPCRecsWithoutAMigratedSPCRecMap.isEmpty()) {

                    Inventory_Hold_Expiry_Date_Offsets__c invHoldExpDate = Inventory_Hold_Expiry_Date_Offsets__c.getOrgDefaults();

                    for (zqu__ProductRatePlan__c prp : [SELECT Id, Name FROM zqu__ProductRatePlan__c WHERE Name IN :newSPCRecsWithoutAMigratedSPCRecMap.keySet() AND zqu__Deleted__c = false AND zqu__Product__r.zqu__Deleted__c = false]) {
                        for (Zuora__SubscriptionProductCharge__c zSPCRec : newSPCRecsWithoutAMigratedSPCRecMap.get(prp.Name)) {
                            Inventory__c newInventory = new Inventory__c();
                            newInventory.Product_Rate_Plan__c = prp.Id;
                            newInventory.Quote_Rate_Plan__c = null;
                            newInventory.Waitlist_Account__c = null;
                            newInventory.Held_By_Migrated_Subscription__c = false;
                            newInventory.Subscription_Product_Charge__c = zSPCRec.Id;
                            newInventory.Subscription_RatePlan_Id__c = zSPCRec.Zuora__RatePlanId__c;
                            newInventory.Inventory_Hold_Expiry_Date__c = DateUtility.AddBusinessDays(zSPCRec.Zuora__Subscription__r.Zuora__TermEndDate__c, (Integer)invHoldExpDate.Subscription_Product_Charge_Day_Offset__c);                          
                            newInventoryList.add(newInventory);

                            zSPCRec.Zuora_Id_of_Migrated_Charge__c = '';
                            spcWithNewInventoryUpdateList.add(zSPCRec);
                        }
                    }
                }


                List<Zuora.zObject> zuoraZObjectList = new List<Zuora.zObject>();

                for (Zuora__SubscriptionProductCharge__c record : oldSPCMap.values()) {
                    Zuora.zObject sub = new Zuora.zObject('RatePlanCharge');
                    sub.setValue('Id',record.Zuora__Zuora_Id__c);
                    sub.setValue('Do_not_create_inventory__c','Yes');
                    
                    zuoraZObjectList.add(sub);

                    // CSP-2113 | also update the "new" SPC record in Zuora at the same time to clear out the Zuora_Id_of_Migrated_Charge__c value
                    if (newSPCMap.containsKey(record.Zuora__Zuora_Id__c)) {
                        Zuora__SubscriptionProductCharge__c newRecord = newSPCMap.get(record.Zuora__Zuora_Id__c);
                        Zuora.zObject newSPC = new Zuora.zObject('RatePlanCharge');
                        newSPC.setValue('Id', newRecord.Zuora__Zuora_Id__c);
                        newSPC.setValue('Zuora_Id_of_Migrated_Charge__c', '');
                        zuoraZObjectList.add(newSPC);
                    }

                    if(zuoraZObjectList.size() == 50){

                        List<Zuora.zApi.SaveResult> results = new List<Zuora.zApi.SaveResult>();

                        if (!Test.isRunningTest()) {
                            // callout method documention is here: https://knowledgecenter.zuora.com/CA_Commerce/E_Development_Resources/B_Order_Builder/D_Programming_with_Order_Builder
                            results.addAll(zApiInstance.zupdate(zuoraZObjectList));
                        }

                        if (Test.isRunningTest()) {
                            // test Sucess
                            Zuora.zApi.SaveResult testSuccessSalesResult = new Zuora.zApi.SaveResult();
                            testSuccessSalesResult.Success = True;
                            // this Id is set in the testDataFactoryT
                            testSuccessSalesResult.Id = '8675309abcdefghi';
                            results.add(testSuccessSalesResult);
                            // test Failure
                            Zuora.zApi.SaveResult testFailSalesResult = new Zuora.zApi.SaveResult();
                            testFailSalesResult.Success = False;
                            results.add(testSuccessSalesResult);
                        }
                       
                        for (Zuora.zApi.SaveResult result : results) {
                            if (result.Success && newSPCMap.containsKey(result.Id)) {
                                // update new SPC value to remove value from Zuora_Id_of_Migrated_Charge__c field
                                Zuora__SubscriptionProductCharge__c spc1 = newSPCMap.get((String)result.Id);
                                spc1.Zuora_Id_of_Migrated_Charge__c = '';
                                newSPCMap.put((String)result.Id, spc1);
                            }else{
                                //failure, get the errors
                                System.debug('CALLOUT FAILED');
                                // TODO: add error logic
                                /*
                                Zuora.zObject[] errors = result.errors;
                                for (Zuora.zObject error : errors) {
                                    String errorCode = (String)error.getValue('Code');
                                    String message = (String)error.getValue('Message');
                                    System.debug(errorCode + ' ' + message);
                                }
                                throw new ApplicationException('Callout Failed');
                                */
                            }
                        }
                        zuoraZObjectList.clear();
                    }
                }

                if(!zuoraZObjectList.isEmpty()) {

                    List<Zuora.zApi.SaveResult> results = new List<Zuora.zApi.SaveResult>();

                    if (!Test.isRunningTest()) {
                        // callout method documention is here: https://knowledgecenter.zuora.com/CA_Commerce/E_Development_Resources/B_Order_Builder/D_Programming_with_Order_Builder
                        results.addAll(zApiInstance.zupdate(zuoraZObjectList));
                    }

                    if (Test.isRunningTest()) {
                        // test Sucess
                        Zuora.zApi.SaveResult testSuccessSalesResult = new Zuora.zApi.SaveResult();
                        testSuccessSalesResult.Success = True;
                        // this Id is set in the testDataFactoryT
                        testSuccessSalesResult.Id = '8675309abcdefghi';
                        results.add(testSuccessSalesResult);
                        // test Failure
                        Zuora.zApi.SaveResult testFailSalesResult = new Zuora.zApi.SaveResult();
                        testFailSalesResult.Success = False;
                        results.add(testSuccessSalesResult);
                    }
                   
                    for (Zuora.zApi.SaveResult result : results) {
                        if (result.Success && newSPCMap.containsKey(result.Id)) {
                            // update new SPC value to remove value from Zuora_Id_of_Migrated_Charge__c field
                            Zuora__SubscriptionProductCharge__c spc2 = newSPCMap.get((String)result.Id);
                            spc2.Zuora_Id_of_Migrated_Charge__c = '';
                            newSPCMap.put((String)result.Id, spc2);
                        }else{
                            //failure, get the errors
                            System.debug('CALLOUT FAILED');
                            // TODO: add error logic
                            /*
                            Zuora.zObject[] errors = result.errors;
                            for (Zuora.zObject error : errors) {
                                String errorCode = (String)error.getValue('Code');
                                String message = (String)error.getValue('Message');
                                System.debug(errorCode + ' ' + message);
                            }
                            throw new ApplicationException('Callout Failed');
                            */
                        }
                    }
                }

                Database.update(newSPCMap.values(), false);

                if (!newInventoryList.isEmpty()) {
                    Database.insert(newInventoryList, false);
                    Database.update(spcWithNewInventoryUpdateList, false);
                }               

                if (queueAnotherJob) {
                    MigratedSubscriptionInventoryQueuedJob.FutureChaining();
                }
            }
        }
    }
//  ------------------------------------------------------------------------------------------------------------------
}