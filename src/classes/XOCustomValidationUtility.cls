public without sharing class XOCustomValidationUtility {

  private static final List<CountryZipREGEX__c> countryRegExList = CountryZipREGEX__c.getAll().values();

  public XOCustomValidationUtility() {
    
  }

  public static SObject assignCountryBasedOnZip(SObject record, String fieldString, String zipValue){
    for(CountryZipREGEX__c zipReg : countryRegExList){
            if(!zipReg.Active__c){
              continue;
            }
            Pattern zipCodeCheck = Pattern.compile(zipReg.RegExPattern__c);
            Matcher postalMatch = zipCodeCheck.matcher(zipValue);
            system.debug(postalMatch);
            if(postalMatch.Matches()){
                record.put(fieldString, zipReg.CountryCode__c);
                break;
            }
        }
        return record;
  }

  public static Boolean validZip(String countryCode, String zipValue){
    Boolean validValue = true;

    for(CountryZipREGEX__c zipReg : countryRegExList){
        if(!zipReg.Active__c || countryCode != zipReg.CountryCode__c){
          continue;
        }else if(zipReg.CountryCode__c == countryCode && zipReg.Active__c){
          Pattern zipCodeCheck = Pattern.compile(zipReg.RegExPattern__c);
          Matcher postalMatch = zipCodeCheck.matcher(zipValue);
          system.debug(postalMatch);
          if(!postalMatch.Matches()){
              validValue = false;
              break;
          }
      }
    }
    return validValue;
  }

  /**
   * CSP-2954, Allow Leads with incomplete (3-digit) Canadian postal codes 
   * Check if record has incomplete (3-digit) Canadian postal code or complete (6-digit) Canadian postal code
   * @Author Steven Shen
   * @Date   2018-08-06
   * @param  countryCode country code of current record
   * @param  zipValue postal code value of current record
  */
  public static Boolean hasCompleteCanadianZip(String countryCode, String zipValue){
    Boolean isCompleteCanadianZip = true;
    if(zipValue.deleteWhitespace().length() != 6 && countryCode == 'CA' ){
      isCompleteCanadianZip = false;
    }
    return isCompleteCanadianZip;
  }

  
}