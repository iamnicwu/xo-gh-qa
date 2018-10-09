public with sharing class LocalAdministrationController {

	private List<String> vfPageNames = new List<String>{'LocalSalesRepReAssignment', 'LocalSalesRepTeamAssignment'};

	public Map<String, Boolean> showPageMap {get; set;}

	public LocalAdministrationController() {
		showPageMap = new Map<String, Boolean>();
		for(String record : vfPageNames){
			showPageMap.put(record, false);
		}

		Map<String, String> pageIdNameMap = new Map<String, String>();

		for(ApexPage record : [select Id, Name from ApexPage where Name IN :vfPageNames]){
			pageIdNameMap.put(record.Id, record.Name);
		}

		for(SetupEntityAccess record : [SELECT Id, SetupEntityId FROM SetupEntityAccess WHERE 
												SetupEntityId IN (SELECT Id FROM ApexPage WHERE NamespacePrefix = null AND Name IN :vfPageNames) 
												AND ParentId IN (SELECT PermissionSetId FROM PermissionSetAssignment WHERE AssigneeId = :UserInfo.getUserId())]){
				showPageMap.put(pageIdNameMap.get(record.SetupEntityId), true);
		}
		system.debug(showPageMap);
	}
}