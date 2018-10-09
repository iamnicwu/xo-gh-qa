public class SubsEntityWrapper implements Comparable {
    public zuora__Subscription__c zSub{get;set;}
    public Boolean showRenewalButton{get;set;}
    public Boolean showRemoveButton{get;set;}
    public String oppStageName{get;set;}
    public Id oppId{get;set;}
    public Decimal totalRenewal{get;set;}
    public Integer recordNum{get;set;}
    public String autoRenew{get;set;}
    
    public subsentityWrapper()
    {
        this.showRenewalButton =false;
        this.showRemoveButton =false;
        this.oppStageName = '';
        this.oppId=null; 
        this.totalRenewal = 0;
        this.recordNum = 0;
        this.autoRenew = '';
        this.zSub = new zuora__Subscription__c ();
    }
    
    public subsentityWrapper(zuora__Subscription__c zSub, Boolean showRenewalButton, Boolean showRemoveButton, String oppStageName, Id oppId, Decimal totalrenewal, Integer recordNum,String autoRenew)
    {
        this.zSub = zSub;
        this.showRenewalButton =showRenewalButton;
        this.showRemoveButton =showRemoveButton;
        this.oppStageName =oppStageName;
        this.oppId=oppId;
        this.totalrenewal =totalrenewal;
        this.recordNum =recordNum;
        this.autoRenew = autoRenew;
    }

    public static String sortBy;
    public static String ascOrDesc;

    public Integer compareTo(Object objToCompare) {
        SubsEntityWrapper compareToEmp = (SubsEntityWrapper)objToCompare;
        if(sortBy == 'SubscriptionName'){
            if(ascOrDesc == 'ASC'){
                if (this.zSub.name== compareToEmp.zSub.name) return 0;
                if (this.zSub.name> compareToEmp.zSub.name ) return 1;
                return -1;  
            }else{
                if (this.zSub.name== compareToEmp.zSub.name) return 0;
                if (this.zSub.name> compareToEmp.zSub.name) return -1;
                return 1;  
            }
        }else if(sortBy == 'Account'){
            if(ascOrDesc == 'ASC'){
                if (this.zSub.Zuora__Account__r.Name == compareToEmp.zSub.Zuora__Account__r.Name) return 0;
                if (this.zSub.Zuora__Account__r.Name > compareToEmp.zSub.Zuora__Account__r.Name) return 1;
                return -1;  
            }else{
                if (this.zSub.Zuora__Account__r.Name == compareToEmp.zSub.Zuora__Account__r.Name) return 0;
                if (this.zSub.Zuora__Account__r.Name > compareToEmp.zSub.Zuora__Account__r.Name) return -1;
                return 1; 
            }
        }else if(sortBy == 'TermStartDate'){
            if(ascOrDesc == 'ASC'){
                if (this.zSub.Zuora__TermStartDate__c == compareToEmp.zSub.Zuora__TermStartDate__c) return 0;
                if (this.zSub.Zuora__TermStartDate__c > compareToEmp.zSub.Zuora__TermStartDate__c) return 1;
                return -1;  
            }else{
                if (this.zSub.Zuora__TermStartDate__c == compareToEmp.zSub.Zuora__TermStartDate__c) return 0;
                if (this.zSub.Zuora__TermStartDate__c > compareToEmp.zSub.Zuora__TermStartDate__c) return -1;
                return 1; 
            }
        }
        else if(sortBy == 'TermEndDate'){
            if(ascOrDesc == 'ASC'){
                if (this.zSub.Zuora__TermEndDate__c == compareToEmp.zSub.Zuora__TermEndDate__c) return 0;
                if (this.zSub.Zuora__TermEndDate__c > compareToEmp.zSub.Zuora__TermEndDate__c) return 1;
                return -1;  
            }else{
                if (this.zSub.Zuora__TermEndDate__c == compareToEmp.zSub.Zuora__TermEndDate__c) return 0;
                if (this.zSub.Zuora__TermEndDate__c > compareToEmp.zSub.Zuora__TermEndDate__c) return -1;
                return 1; 
            }
        }else if(sortBy == 'ReportingRep'){
            if(ascOrDesc == 'ASC'){
                if (this.zSub.Reporting_Rep__c == compareToEmp.zSub.Reporting_Rep__c) return 0;
                if (this.zSub.Reporting_Rep__c > compareToEmp.zSub.Reporting_Rep__c) return 1;
                return -1;  
            }else{
                if (this.zSub.Reporting_Rep__c == compareToEmp.zSub.Reporting_Rep__c) return 0;
                if (this.zSub.Reporting_Rep__c > compareToEmp.zSub.Reporting_Rep__c) return -1;
                return 1; 
            }
        }else if(sortBy == 'RenewalRep'){
            if(ascOrDesc == 'ASC'){
                if (this.zSub.Renewal_Rep__c == compareToEmp.zSub.Renewal_Rep__c) return 0;
                if (this.zSub.Renewal_Rep__c > compareToEmp.zSub.Renewal_Rep__c) return 1;
                return -1;  
            }else{
                if (this.zSub.Renewal_Rep__c == compareToEmp.zSub.Renewal_Rep__c) return 0;
                if (this.zSub.Renewal_Rep__c > compareToEmp.zSub.Renewal_Rep__c) return -1;
                return 1; 
            }
        }else if(sortBy == 'Total'){
            if(ascOrDesc == 'ASC'){
                if (this.zSub.Zuora__TCV__c == compareToEmp.zSub.Zuora__TCV__c) return 0;
                if (this.zSub.Zuora__TCV__c > compareToEmp.zSub.Zuora__TCV__c) return 1;
                return -1;  
            }else{
                if (this.zSub.Zuora__TCV__c == compareToEmp.zSub.Zuora__TCV__c) return 0;
                if (this.zSub.Zuora__TCV__c > compareToEmp.zSub.Zuora__TCV__c) return -1;
                return 1; 
            }
        }else if(sortBy == 'MonthlyRate'){
            if(ascOrDesc == 'ASC'){
                if (this.zSub.Zuora__MRR__c == compareToEmp.zSub.Zuora__MRR__c) return 0;
                if (this.zSub.Zuora__MRR__c > compareToEmp.zSub.Zuora__MRR__c) return 1;
                return -1;  
            }else{
                if (this.zSub.Zuora__MRR__c == compareToEmp.zSub.Zuora__MRR__c) return 0;
                if (this.zSub.Zuora__MRR__c > compareToEmp.zSub.Zuora__MRR__c) return -1;
                return 1; 
            }
        }else if(sortBy == 'autoRenew'){
            // if(this.zSub.AutoRenewal__c == true){
            //     this.autoRenew = 'true';
            // }else{
            //     this.autoRenew = 'false';
            // }
            // if(compareToEmp.zSub.Zuora__autoRenew__c == true){
            //     compareToEmp.autoRenew = 'true';
            // }else{
            //     compareToEmp.autoRenew = 'false';
            // }
            // if(ascOrDesc == 'ASC'){
            //     if (this.autoRenew == compareToEmp.autoRenew) return 0;
            //     if (this.autoRenew > compareToEmp.autoRenew) return 1;
            //     return -1;  
            // }else{
            //     if (this.autoRenew == compareToEmp.autoRenew) return 0;
            //     if (this.autoRenew > compareToEmp.autoRenew) return -1;
            //     return 1; 
            // }
            if(ascOrDesc == 'ASC'){
                if (this.zSub.AutoRenewal__c == compareToEmp.zSub.AutoRenewal__c) return 0;
                if (this.zSub.AutoRenewal__c > compareToEmp.zSub.AutoRenewal__c) return 1;
                return -1;  
            }else{
                if (this.zSub.AutoRenewal__c == compareToEmp.zSub.AutoRenewal__c) return 0;
                if (this.zSub.AutoRenewal__c > compareToEmp.zSub.AutoRenewal__c) return -1;
                return 1; 
            }
        }else if(sortBy == 'AccountCreditHoldStatus'){
            if(ascOrDesc == 'ASC'){
                if (this.zSub.Zuora__Account__r.Credit_Hold__c == compareToEmp.zSub.Zuora__Account__r.Credit_Hold__c) return 0;
                if (this.zSub.Zuora__Account__r.Credit_Hold__c== FALSE && compareToEmp.zSub.Zuora__Account__r.Credit_Hold__c == TRUE) return -1;
                return 1;  
            }else{
                if (this.zSub.Zuora__Account__r.Credit_Hold__c == compareToEmp.zSub.Zuora__Account__r.Credit_Hold__c) return 0;
                if (this.zSub.Zuora__Account__r.Credit_Hold__c== FALSE && compareToEmp.zSub.Zuora__Account__r.Credit_Hold__c == TRUE) return 1;
                return -1; 
            }
        }
        else{
            if(ascOrDesc == 'ASC'){
                if (this.oppStageName == compareToEmp.oppStageName) return 0;
                if (this.oppStageName > compareToEmp.oppStageName) return 1;
                return -1;  
            }else{
                if (this.oppStageName == compareToEmp.oppStageName) return 0;
                if (this.oppStageName > compareToEmp.oppStageName) return -1;
                return 1; 
            }
        }
    }
}