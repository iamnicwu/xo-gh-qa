/**
 *    Pause or Resume NVM Call Recording:
 *	   1. Get NVM OAuth token with NVM clientId and clientsecret.
 * 	   2. Get NVM agent Id from User.
 *	   3. Get current Call Guid with token and NVM agent Id.
 *	   4. Pause or Resume Call Recording with token, Call Guid and json param. 
 *
 *   @author Scott Yang
 *   @date   2017-04-01
 *   @ticket CSP-1972
 */
public with sharing class NewVoiceMediaUtility {

	public static NVMContactWorld__Settings__c nvmSettings = NVMContactWorld__Settings__c.getInstance();
	public static String accountKey = nvmSettings.NVMContactWorld__clientId__c;
	public static String accountSecret =nvmSettings.NVMContactWorld__clientSecret__c;
	// CSP-2265 Enhance Call Pause Code
	// baseNVMUrl must end with '/'
	public static String baseNVMUrl = nvmSettings.NVMContactWorld__baseURL__c.endsWith('/') ? nvmSettings.NVMContactWorld__baseURL__c : nvmSettings.NVMContactWorld__baseURL__c + '/';
	public static String tokenUrl = nvmSettings.Token_Callout_URL__c;
	public static String nvmToken;

	public NewVoiceMediaUtility(){
		
	}

	
	/**
	 *   If token has expired in Cache, Get NVM token with NVM clientId and clientsecret and store it in Platform Cache. 
	 *   Sample URL: https://cloud17.contact-world.net/v0/oauth2/token
	 *   Sample Success response:
	 *   {
   *       "access_token": "tokenValue",
   *       "token_type": "bearer",
   *       "expires_in": 3600,
   *       "scope": "newvoicemedia.com/api/statistics newvoicemedia.com/api/callcontrol newvoicemedia.com/api/callrecording newvoicemedia.com/api/account"
   *   }
	 *   @author Scott Yang
	 *   @date   2017-04-01
	 *   @return Boolean
	 */
	public static Boolean hasAccessToken(){
		
		// retrieve access token from platform cache, if expired it will return null
		nvmToken = (String)Cache.Org.get('local.NVM.token');
		System.debug(LoggingLevel.INFO, '*** Cache nvmToken: ' + nvmToken);

		if(String.isEmpty(nvmToken)){

			try{
				// Base64 encrpting the client key and secret
				String authInfo = accountKey + ':' + accountSecret;
				String base64AuthInfo = EncodingUtil.base64Encode(Blob.valueOf(authInfo));
				String url = baseNVMUrl + tokenUrl;

				// put header information in a map
				Map<String, String> headerMap = new Map<String, String>();
				headerMap.put('Content-Type', 'application/x-www-form-urlencoded');
				headerMap.put('Authorization','Basic ' + base64AuthInfo);
				List<String> bodyList = new List<String>();
				bodyList.add('grant_type=client_credentials');
				
				// make rest call to retrieve access token
				String calloutResult = nvmRestCallout(url, 'POST', headerMap, bodyList);

				System.debug(LoggingLevel.INFO, '*** calloutResult: ' + calloutResult);
				
				// create a result wrapper for getting the token and expiration time
				NVMTokenWrapper tokenWrap = new NVMTokenWrapper();
				tokenWrap = tokenWrap.parse(calloutResult);
				nvmToken = tokenWrap.access_token;
				System.debug(LoggingLevel.INFO, '*** REST Callout nvmToken : ' + nvmToken);

				// stored the token with expiration time in platform cache 'local.NVM.token'
				Cache.Org.put('local.NVM.token', nvmToken, Integer.valueOf(tokenWrap.expires_in) - 60, Cache.Visibility.ALL, true);
			}
			catch(Exception ex){
				nvmToken = 'Invalid token!';
				ExceptionUtility.consumeException(ex, true);
				return false;
			}
		}

		return true;
	}

	/**
	 *   Get NVM Agent Id from User
	 *
	 *   @author Scott Yang
	 *   @date   2017-04-01
	 *   @return NVM Agent ID
	 */
	public static String getAgentID(){
		List<User> userList = [Select Id, NVMContactWorld__NVM_Agent_Id__c FROM User where Id = :UserInfo.getUserId()];
		//CSP-2265 Enhance Call Pause Code
		String agentID;
		if(userList.size() > 0){
			agentID = userList[0].NVMContactWorld__NVM_Agent_Id__c;
		}
		return agentID;
	}

	/**
	 *   Get current Call Guid with unique Agent Id
	 *   Sample URL: https://cloud17.contact-world.net/V0/{accountKey}/agents/462
	 *   @author Scott Yang
	 *   @date   2017-04-01
	 *   @return NVM Call Guid
	 */
	public static String getNVMCurrentCallGuid(){
		String nvmCurrentCallGuid;
		// getting the rest URL
		//CSP-2265 Enhance Call Pause Code
		String agentId = getAgentID();

		if(String.isNotEmpty(agentId)){

			String url = baseNVMUrl +'v0/' + accountKey + '/agents/' + agentId;
		
			try{
				// put the header information in a header map
				Map<String, String> headerMap = new Map<String, String>();
				headerMap.put('Authorization', 'Bearer ' + nvmToken);
				headerMap.put('Accept', 'application/json;version=2');
				List<String> bodyList = new List<String>();

				// make a rest call to get the NVMGuid
				String calloutResult = nvmRestCallout(url, 'GET', headerMap, bodyList);
				
				// Creating a result wrapper to parsing the callout result
				NVMCallGuidWrapper callGuidWrapper = new NVMCallGuidWrapper();
				callGuidWrapper = callGuidWrapper.parse(calloutResult);
				nvmCurrentCallGuid = callGuidWrapper.currentCallGuid;
				System.debug(LoggingLevel.INFO, '*** currentCallGuid: ' + nvmCurrentCallGuid);
			}
			catch(Exception ex){
				// nvmCallGuid = 'Invalid Call Guid!';
				ExceptionUtility.consumeException(ex, true);
			}

		}
		
		return nvmCurrentCallGuid;
	}


	 /**
   *   Add RemoteAction method to seperate NVM callout and Zuora Payment Method page callout.
   *   Pause the NVM call
   *   @author Scott Yang
   *   @date   2017-04-13
   *   @return pause result
   */
	// @RemoteAction
	// public static String pauseCallRecording(){
	// 	String resPaused;
 //    resPaused = NewVoiceMediaUtility.pauseOrResumeCallRecording('Paused');
 //    // Stored a cookie to inticated that the call had been paused when the call had been paused sucessed, 
 //    if(resPaused.contains('Paused Call Recording Sucessfully')){
 //      NewVoiceMediaUtility.setNVMCallRecordingPauseCookie('Paused');
 //    }
 //    return resPaused;
	// }

	/**
   *   Resume the NVM call
   *   @author Scott Yang
   *   @date   2017-04-13
   *   @return Start result
   */
	// public static String resumeCallRecording(){
	// 	return pauseOrResumeCallRecording('Started');
	// }


	/**
	 *   Combine Pause and Resume call recording code 
	 *   Sample URL: "https://cloud17.contact-world.net/v0/accountkey/calls/callGuid
	 *   @author Scott Yang
	 *   @date   2017-04-01
	 *   @param  callAction: Paused / Started
	 *   @return Boolean
	 */
	public static String pauseOrResumeCallRecording(String callAction){
		System.debug(LoggingLevel.INFO, '*** pauseOrResumeCallRecording Ready ');

		// check if has access token stored in platform cache
		// yes, use the token as header to pause call recording
		if(hasAccessToken()){

			// Rest call to get callGuid
			String nvmCurrentCallGuid = getNVMCurrentCallGuid();
			String url = baseNVMUrl +'v0/' + accountKey + '/calls/' + nvmCurrentCallGuid;

			if(String.isNotEmpty(nvmCurrentCallGuid)){
				try{

					// request json
					String reqJson;
					JSONGenerator generator = Json.createGenerator(true);
					
					// creating a json wrapper to get the recording status
					NVMCallRecordingStatusJson nvmRecJson = new NVMCallRecordingStatusJson();
					nvmRecJson.recordingStatus = callAction;
					generator.writeObject(nvmRecJson);
					reqJson = generator.getAsString();

					Map<String, String> headerMap = new Map<String, String>();
					headerMap.put('Authorization', 'Bearer ' + nvmToken);
					headerMap.put('Content-Type', 'application/json');
					List<String> bodyList = new List<String>();
					bodyList.add(reqJson);

					// to make a rest call for requesting Paused / Started
					String calloutResult = nvmRestCallout(url, 'POST', headerMap, bodyList);
					System.debug(LoggingLevel.INFO, '*** pauseOrResumeCallRecording NVM calloutResult: ' + calloutResult);
					return callAction + ' Call Recording Sucessfully';

				}catch(Exception ex){
					ExceptionUtility.consumeException(ex, true);
					return callAction + ' Call Recording Failed';
				}
			}else{
				return 'No Current Call';
			}
		}

		return 'Get NVM Token Failed';
	}

	
	/**
	 *   Handle all NVM http request 
	 *   @author Scott Yang
	 *   @date   2017-04-01
	 *   @param  url        
	 *   @param  method       
	 *   @param  headerMap    used for HttpRequest.setHeader(String key, String value) 
	 *   @param  bodyList     used for HttpRequest.setBody(String value) 
	 *   @return HttpResponse body
	 */
	public static String nvmRestCallout(String url, String method, Map<String, String> headerMap, List<String> bodyList){
		
		try{
			Http h = new Http();
			HttpRequest req = new HttpRequest();
			req.setEndpoint(url);
			req.setMethod(method);
			for(String headerKey : headerMap.keySet()){
				req.setHeader(headerKey, headerMap.get(headerKey));
			}

			for(String bodyStr : bodyList){
				req.setBody(bodyStr);
			}

			HttpResponse res = h.send(req);
			System.debug(LoggingLevel.INFO, '*** res.getBody(): ' + res.getBody());
			return res.getBody();
		}catch(Exception ex){
			ExceptionUtility.consumeException(ex, true);
			return 'Callout Failed!';
		}
	}

/**
 *   Set cookie to indicate NVM Call Recording has been paused
 *
 *   @author Scott Yang
 *   @date   2017-04-01
 *   @param  cookieValue 
 */
	public static void setNVMCallRecordingPauseCookie(String cookieValue, String currentURL){
		// Cookie nvmPauseCookie = ApexPages.currentPage().getCookies().get('NVMCallRecordingPause');
    Cookie nvmPauseCookie = new Cookie('NVMCallRecordingPause', cookieValue, null, -1, false);
    PageReference pf = new PageReference(currentURL);
    pf.setCookies(new Cookie[]{nvmPauseCookie});
    System.debug(LoggingLevel.INFO, '*** nvmPauseCookie: ' + nvmPauseCookie);
	}

/**
 *   Get Cookie NVMCallRecordingPause value
 *
 *   @author Scott Yang
 *   @date   2017-04-01
 *   @return Cookie NVMCallRecordingPause Value
 */
	public static String getNVMCallRecordingPauseCookie(){
		Cookie nvmPauseCookie = ApexPages.currentPage().getCookies().get('NVMCallRecordingPause');
		if (nvmPauseCookie == null) {
			return null;
		}else {
			return nvmPauseCookie.getValue();
		}
	}

	// Parse NVM token json
	public class NVMTokenWrapper{
		public String access_token;
		public String token_type;
		public String expires_in;
		public String scope;

		public  NVMTokenWrapper parse(String jsonStr) {
			return (NVMTokenWrapper) JSON.deserialize(jsonStr, NVMTokenWrapper.class);
		}
	}

	// Parse NVM Call Guid json
	public class NVMCallGuidWrapper{

		public String id;
		public String previousCallGuid;
		public String currentCallGuid;
		public List<NVMCallGuidDetailWrapper> links;
		
		public NVMCallGuidWrapper parse(String jsonStr) {
			return (NVMCallGuidWrapper) JSON.deserialize(jsonStr, NVMCallGuidWrapper.class);
		}
	}

	public class NVMCallGuidDetailWrapper{
		public String href;
		public String rel;
	}

	// Parse NVM Call Recording Status
	public class NVMCallRecordingStatusJson{
		public String recordingStatus;
	}

	public class NVNPauseCallRecordingResultWrapper{
		public String statusCode;
		public String message;
	}

}