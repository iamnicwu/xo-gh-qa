@isTest
private class NewVoiceMediaUtilityTest {
    static testMethod void testMethod1() {
        createNvmSettings();
        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'OK',
                                                 '{"access_token":"123","token_type":"bearer","expires_in":3600,"scope":"newvoicemedia.com/api/statistics newvoicemedia.com/api/callcontrol newvoicemedia.com/api/callrecording newvoicemedia.com/api/account"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);

        // NewVoiceMediaUtility.pauseCallRecording();
        NewVoiceMediaUtility.pauseOrResumeCallRecording('Paused');
        // NewVoiceMediaUtility.resumeCallRecording();
        NewVoiceMediaUtility.pauseOrResumeCallRecording('Started');
        NewVoiceMediaUtility.getNVMCallRecordingPauseCookie();
        
    }

    static testMethod void testMethod2() {
        createNvmSettings();
        // Test pauseCallRecording exception
        // NewVoiceMediaUtility.pauseCallRecording();
        NewVoiceMediaUtility.pauseOrResumeCallRecording('Paused');
    }


    static testMethod void testMethod4() {
        createNvmSettings();
        Cache.Org.put('local.NVM.token', 'testToken', 3600, Cache.Visibility.ALL, true);
        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                 'OK',
                                                 '{"links":[{"rel":"testrel","href":"testhref"}],"id":"testId","currentCallGuid":"testcurrentCallGuid"}',
                                                 null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        NewVoiceMediaUtility.pauseOrResumeCallRecording('Paused');
        // NewVoiceMediaUtility.pauseCallRecording();
        
    }

    public static void createNvmSettings(){
        NVMContactWorld__Settings__c nvmSettings = new NVMContactWorld__Settings__c();
        nvmSettings.NVMContactWorld__clientId__c = 'test';
        nvmSettings.NVMContactWorld__clientSecret__c = 'test';
        nvmSettings.NVMContactWorld__baseURL__c = 'https://test/';
        nvmSettings.Token_Callout_URL__c = 'v0/oauth2/token';
        insert nvmSettings;
    }


}