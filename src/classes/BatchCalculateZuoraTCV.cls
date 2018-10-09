global class BatchCalculateZuoraTCV implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {
    global String query;
    global String defaultTemplateId;
    global String zuoraQuoteTemplateEndpoint;
    global Map<Id, Id> quoOppIds = new Map<Id, Id>();
    global String serverUrl;
    global String sessionId;
    global List<Id> oppIdList;
    
    global BatchCalculateZuoraTCV(List<Id> oppIdList) {
        this.oppIdList = oppIdList;

        this.query = 'SELECT Id FROM Opportunity WHERE StageName = \'Calculating TCV\' AND Id IN :oppIdList';

        // query and set the default Zuora Quote Template Id
        zqu__Quote_Template__c defaultQuoteTemplate = [Select zqu__Template_Id__c From zqu__Quote_Template__c Where zqu__IsDefault__c = True and zqu__Quote_Type__c = 'New Subscription' Limit 1];
        this.defaultTemplateId = defaultQuoteTemplate.zqu__Template_Id__c;

        // custom settings that holds the zuora endpoint url; use it to set the zuoraQuoteTemplateEndpoint
        Generate_Quote_Pdf_Config__c config = Generate_Quote_Pdf_Config__c.getValues('Production');
        this.zuoraQuoteTemplateEndpoint = config.URL__c;
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        Database.QueryLocator retVal = Database.getQueryLocator(query);
        return retVal;
    }

    // Batch size MUST be set to 1
    global void execute(Database.BatchableContext BC, List<Opportunity> scope) {
        List<Opportunity> oppUpdateList = new List<Opportunity>();
        for (Opportunity opp : scope) {

            system.debug('11111111 opp' + opp);

            // Calculate TCV; if it fails, set the StageName to 'TCV Calculation Failed' and do not generate the PDFs for this Opportunity
            Boolean tcvCalculationSuccess = ZuoraTCVAndPaymentSchedule.setTrueTCV(opp.Id);
            if (!tcvCalculationSuccess) {
                opp.StageName = 'TCV Calculation Failed';
                oppUpdateList.add(opp);
                continue;
            }

            List<zqu__Quote__c> quoList = [SELECT Id, Name, server_Url__c, session_Id__c, zqu__Opportunity__c FROM zqu__Quote__c WHERE zqu__Status__c = 'New' AND zqu__SubscriptionType__c != 'Cancel Subscription' AND zqu__Opportunity__c = :opp.Id];
            for (Integer i = 0; i < quoList.size(); i++) {
                zqu__Quote__c zQuote = quoList[i];
                this.quoOppIds.put(zQuote.Id, zQuote.zqu__Opportunity__c);
                if (this.serverUrl == null || this.sessionId == null) {
                    this.serverUrl = ''+EncodingUtil.urlEncode(zQuote.server_Url__c,'UTF-8');
                    this.sessionId = zQuote.session_Id__c;
                }
            }
        }
        if (!oppUpdateList.isEmpty()) {
            update oppUpdateList;
        }
    }

    global void finish(Database.BatchableContext BC) {
        // lastly, attempt to generate the PDFs and update the Opportunity StageName as appropriate
        if (this.quoOppIds.isEmpty()) {
            return;
        }

        System.debug(LoggingLevel.INFO, '*** quoOppIds: ' + this.quoOppIds);
        System.debug(LoggingLevel.INFO, '*** defaultTemplateId: ' + this.defaultTemplateId);
        System.debug(LoggingLevel.INFO, '*** : this.serverUrl' + this.serverUrl);
        System.debug(LoggingLevel.INFO, '*** this.sessionId: ' + this.sessionId);
        System.debug(LoggingLevel.INFO, '*** this.zuoraQuoteTemplateEndpoint: ' + this.zuoraQuoteTemplateEndpoint);

        Map<Id, Boolean> pdfGenerationSuccessMap = AutoGenerateQuotePdf.generatePdf(this.quoOppIds, this.defaultTemplateId, this.serverUrl, this.sessionId, this.zuoraQuoteTemplateEndpoint);
        
        System.debug(LoggingLevel.INFO, '*** pdfGenerationSuccessMap: ' + pdfGenerationSuccessMap);
        
        List<Opportunity> oppUpdateList = [SELECT Id, StageName FROM Opportunity WHERE Id IN :pdfGenerationSuccessMap.keySet()];
        for (Integer i = 0; i < oppUpdateList.size(); i++) {
            Opportunity oppRec = oppUpdateList[i];
            oppRec.StageName = pdfGenerationSuccessMap.get(oppRec.Id) ? 'Ready for Echo-Sign' : 'PDF Generation Failed';
        }
        update oppUpdateList;
    }
}