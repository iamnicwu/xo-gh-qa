public without sharing class DateUtility {

  public static Boolean IsWeekendDay(Date dateParam){

    boolean result  = false;

    //Recover the day of the week
    Date startOfWeek= dateParam.toStartOfWeek();
    Integer dayOfWeek = startOfWeek.daysBetween(dateParam);
    result = dayOfWeek == 0 || dayOfWeek == 6 ? true : false;
    return result;
  }
  
  
  public static Date AddBusinessDays(Datetime startDateTime, integer businessDaysToAdd){

    return AddBusinessDays(date.newinstance(startDateTime.year(), 
                          startDateTime.month(), 
                          startDateTime.day()), 
                          businessDaysToAdd);
  }
  
  public static Date AddBusinessDays(Datetime startDateTime, decimal businessDaysToAdd){

    return AddBusinessDays(date.newinstance(startDateTime.year(), 
                          startDateTime.month(), 
                          startDateTime.day()), 
                          integer.valueof(businessDaysToAdd));
  }
  
  public static Date AddBusinessDays(Date startDate, decimal businessDaysToAdd){
    return AddBusinessDays(startDate, integer.valueof(businessDaysToAdd));
  }
  
  public static Date AddBusinessDays(Date StartDate, integer businessDaysToAdd){

    //Add or decrease in BusinessDaysToAdd days 
    Date finalDate = StartDate;
    Integer direction = BusinessDaysToAdd < 0 ? -1 : 1;

    while(BusinessDaysToAdd != 0){

      finalDate = finalDate.AddDays(direction);
      if (!isWeekendDay(finalDate)){
        BusinessDaysToAdd -= direction;
      }
    }
    
    return finalDate;
  }

  /**
   * This method used to add business days and skip weekend and holiday
   * 
   * @Author Mason Qiu
   * @Date   2017-12-22
   * @param  businessHourId, startDate, businessDays
   * @return Date finalDate             
   */
  public static Date AddBusinessDays(Id businessHourId, Date startDate, Integer businessDays){

    //Add or decrease in BusinessDaysToAdd days 
    Date finalDate = StartDate;
    Datetime startDateTime = Datetime.newInstance(StartDate, Time.newInstance(12, 00, 00, 0000));

    if(businessDays != 0 && businessHourId != NULL) {
      Integer milliseconds =  businessDays * 9* 60* 60* 1000;
      Datetime nextBusinessDateTime = BusinessHours.add(businessHourId, startDateTime, milliseconds);
      finalDate = nextBusinessDateTime.date();
    }

    return finalDate;
  }

  /**
   * This method used to add business days and skip weekend and holiday
   * 
   * @Author Mason Qiu
   * @Date   2017-12-22
   * @param  businessHourId, startDate, businessDays
   * @return Datetime finalDate             
   */
	public static Datetime AddBusinessDays(Id businessHourId, Datetime startDate, Integer businessDays) {
		//Add or decrease in BusinessDaysToAdd days 
		Datetime finalDate = StartDate;
		Time satrtTime = startDate.time();
		Datetime startDateTime = Datetime.newInstance(StartDate.date(), Time.newInstance(12, 00, 00, 0000));

		if(businessDays != 0 && businessHourId != NULL) {
			Integer milliseconds =  businessDays * 9* 60* 60* 1000;
			Datetime nextBusinessDateTime = BusinessHours.add(businessHourId, startDateTime, milliseconds);
			Date nextBusinessDate = nextBusinessDateTime.date();
			finalDate = Datetime.newInstance(nextBusinessDate, satrtTime);
		}

		return finalDate;
	}


  /**
   *   CSP-2835 Update Duplicate Approval Rule to Recognize Term Start and End Dates
   *   This method used to valid two time periods do overlap or not
   *   Allow one day to overlap
   *   @author Mason
   *   @date   2018-04-20
   *   @param  Date date1StartDate, Date date1EndDate, Date date2StartDate, Date date2EndDate
   *   @return Boolean
   */
  public static Boolean isOverlapDate(Date date1StartDate, Date date1EndDate, Date date2StartDate, Date date2EndDate) {
    Boolean isOverlap = false;

    if((date1StartDate <= date2StartDate && date2StartDate < date1EndDate) 
      || (date1StartDate < date2EndDate && date2EndDate <= date1EndDate)
      || (date1StartDate >= date2StartDate && date2EndDate > date1StartDate)) {

          isOverlap = true;
    }
    return isOverlap;
  }

  /**
   *   CSP-2925 Compensation Roles - Set up Custom Object
   *   This method used to valid two time periods do overlap or not 
   *   Not allow one day to overlap
   *   @author Mason
   *   @date   2018-06-08
   *   @param  Date date1StartDate, Date date1EndDate, Date date2StartDate, Date date2EndDate
   *   @return Boolean
   */
  public static Boolean isStrictOverlapDate(Date date1StartDate, Date date1EndDate, Date date2StartDate, Date date2EndDate) {
    Boolean isOverlap = false;

    if((date1StartDate <= date2StartDate && date2StartDate <= date1EndDate) 
      || (date1StartDate <= date2EndDate && date2EndDate <= date1EndDate)
      || (date1StartDate >= date2StartDate && date2EndDate >= date1StartDate)) {

          isOverlap = true;
    }
    return isOverlap;
  }
}