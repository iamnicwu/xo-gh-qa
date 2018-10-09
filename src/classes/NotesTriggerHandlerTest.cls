/* 
<class>
<name>NotesTriggerHandlerTest</name>
<purpose>Tests the NotesTriggerHandler apex class</purpose>
<created>
<by>Harikrishnan Mohan</by>
<date>8/10/2015</date>
<ticket>SF-791</ticket>        
</created>
</class>
*/
@isTest
private class NotesTriggerHandlerTest {
    
    @isTest static void test_method_one() {
        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                                       'Complete',
                                                                       '{"companyName": "Test Account"}',
                                                                       null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        /*
        testDataFactoryT tdf = new testDataFactoryT();
        tdf.CreateLocalTestObjects();
		*/
        Deactivate_Trigger__c dtNote = TestClassUtility.createNotesDeactivateTriggerSetting(true);       
        List<User> userList = [select Id, Name from User where Id != :UserInfo.getUserId() and isActive = true limit 2];
        //Create a custom setting named ProfilesExemptDeletingNotesNAttachment__c to hold the profiles exempt for deleting N&A
        ProfilesExemptDeletingNotesNAttachment__c pfl = new ProfilesExemptDeletingNotesNAttachment__c();
        pfl.Name = 'Test Profile';
        insert pfl;
        
        /* tdf.dtNote.After_Delete__c = false;
        tdf.dtNote.After_Insert__c = false;
        tdf.dtNote.After_Update__c = false;
        tdf.dtNote.Before_Delete__c = false;
        tdf.dtNote.Before_Insert__c = false;
        tdf.dtNote.Before_Update__c = false;
        update tdf.dtNote; */
        
        //Create Notes        
        /* Note testnote = new Note();
        testnote.Title = 'Test';
        testnote.ParentId = tdf.testAccount.id;
        testnote.Body = 'Test Note';
        try{    
        insert testnote;
        }catch(exception e){}
        
        tdf.dtNote.Before_Update__c = true;
        tdf.dtNote.Before_Delete__c = true;
        update tdf.dtNote;*/
        Note testnote = TestClassUtility.createNote(true); 
        testnote.Body  = 'Test Note1';
        System.runAs(userList[1]){
            try{    
                update testnote;
            }catch(exception e){}
            try{    
                delete testnote;
            }catch(exception e){}
        }   
    }
    @isTest static void test_method_two() {
        SingleRequestMockTest fakeResponse = new SingleRequestMockTest(200,
                                                                       'Complete',
                                                                       '{"companyName": "Test Account"}',
                                                                       null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        
        /*
        testDataFactoryT tdf = new testDataFactoryT();
        tdf.CreateLocalTestObjects();*/
        Deactivate_Trigger__c dtNote;
        if(Deactivate_Trigger__c.getValues('Note') == null){
            dtNote = new Deactivate_Trigger__c();
            dtNote.Name = 'Note';
            dtNote.After_Delete__c = True;
            dtNote.After_Insert__c = True;
            dtNote.After_Update__c = True;
            dtNote.Before_Delete__c = True;
            dtNote.Before_Insert__c = True;
            dtNote.Before_Update__c = True;
            insert dtNote;  
        }
        System.debug('--'+dtNote);
        List<User> userList = [select Id, Name from User where Id != :UserInfo.getUserId() and isActive = true limit 2];
        //Create a custom setting named ProfilesExemptDeletingNotesNAttachment__c to hold the profiles exempt for deleting N&A
        ProfilesExemptDeletingNotesNAttachment__c pfl = new ProfilesExemptDeletingNotesNAttachment__c();
        pfl.Name = 'System Administrator';
        insert pfl;
        System.debug(userList);
        /* tdf.dtNote.After_Delete__c = false;
        tdf.dtNote.After_Insert__c = false;
        tdf.dtNote.After_Update__c = false;
        tdf.dtNote.Before_Delete__c = false;
        tdf.dtNote.Before_Insert__c = false;
        tdf.dtNote.Before_Update__c = false;
        update tdf.dtNote; */
        
        //Create Notes
        
        Note testnote = TestClassUtility.createNote(true); 
        /* Note testnote = new Note();
        testnote.Title = 'Test';
        testnote.ParentId = tdf.testAccount.id;
        testnote.Body = 'Test Note';
        try{    
        insert testnote;
        }catch(exception e){}
        
        tdf.dtNote.Before_Update__c = true;
        tdf.dtNote.Before_Delete__c = true;
        update tdf.dtNote;*/
        testnote.Body  = 'Test Note1';
        System.runAs(userList[1]){
            try{    
                update testnote;
            }catch(exception e){}
            
            try{    
                delete testnote;
            }catch(exception e){}
        }
    }
    
}