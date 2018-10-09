@isTest
private class DateUtilityTest{

    private static testmethod void TestAddBusinessDay() {

    	  BusinessHours stdBusinessHours = [select id from BusinessHours where Name = 'XO Business Hours'];
        Integer TestInt = 1;
        decimal TestDec = 1;
        Date date1 = Date.newInstance(2018, 09, 20);
        Datetime dateTime1 = Datetime.newInstance(2018, 09, 20);

        test.startTest();
        DateUtility du = new DateUtility();
        Boolean b = DateUtility.IsWeekendDay(Date.today());
        Date TestDate1 = DateUtility.AddBusinessDays(dateTime1, TestInt);
        Date TestDate2 = DateUtility.AddBusinessDays(dateTime1, TestDec);
        Date TestDate3 = DateUtility.AddBusinessDays(date1, TestDec);
        system.assert(TestDate3 == date1.addDays(1));
        Date TestDate4 = DateUtility.AddBusinessDays(stdBusinessHours.Id, date1, TestInt);
        system.assert(TestDate4 == date1.addDays(1));
        Datetime TestDate5 = DateUtility.AddBusinessDays(stdBusinessHours.Id, dateTime1, TestInt);
        test.stopTest();

    }
    private static testmethod void TestDateOverLap() {
       	Date date1Star = Date.newInstance(2017, 02, 21);
       	Date date1End = Date.newInstance(2017, 07, 20);
       	Date date2Star = Date.newInstance(2017, 01, 11);
       	Date date2End = Date.newInstance(2017, 05, 21);

        test.startTest();
        Boolean isoverlap1 = DateUtility.isStrictOverlapDate(date1Star,date1End,date2Star,date2End);
        system.assert(isoverlap1);
        Boolean isoverlap2 = DateUtility.isOverlapDate(date1Star,date1End,date2Star,date2End);
        system.assert(isoverlap2);
        test.stopTest();
    }

}