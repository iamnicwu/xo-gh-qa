// handles authentication from our Google
global class GoogleInternalRegHandler implements Auth.RegistrationHandler{
    global User createUser(Id portalId, Auth.UserData data){
        
        System.debug(data.email);
        
        if (data.email == '')
        {
        	throw new ApplicationException('SSO authentication did not pass an email address');
        }
        
        return ValidateUserLogin(data.email);
    }
    
    global void updateUser(Id userId, Id portalId, Auth.UserData data){
    	// verify that the authenticated user has a valid matching GoogleID
    	
       	User u = ValidateUserLogin(data.email);

        try
        {
            u.LastName	= data.lastName;
            u.FirstName = data.firstName;
            //u.Email = data.email;
            String strAlias = data.email.substringBefore('@');
            if (strAlias.length() > 8)
            {
                strAlias = strAlias.substring(0,8);
            }
            u.Alias = strAlias;
            update(u); } catch(Exception e){}
        finally
        {
	        system.debug('update user called');         
        }
    }
    
    private User ValidateUserLogin(String userEmail)
    {
        List<User> uList = [SELECT Id, FirstName, LastName, email, GoogleID__c FROM user WHERE GoogleID__c =: userEmail];
        
		if (uList.size() < 1)
        {
        	throw new ApplicationException('No user found with matching Google ID ' + userEmail);
        }
        else
        {
        	System.debug('Found user with matching Google ID ' + userEmail);
        }
        
        return uList[0];
    }
}