/*
	2010-08-03 - Richard Durrant 
	Functionality is to update the owners of the accounts when the territory manager is changed.
	
	NOTE: commented out old functionality 
*/
trigger TriggerTerritoryAssignment on Territory__c (after update)
{
	Set<id> changedTerritoryIds = new Set<id>();
	for(Territory__c t : trigger.new)
	{	
		if(t.Territory_Manager__c != trigger.oldMap.get(t.Id).Territory_Manager__c)
		{
			changedTerritoryIds.add(t.Id);
		}
	}
	
	Set<id>accountIds = new Set<id>();
	for(Account a : [
		SELECT
			id,
			name
		FROM
			Account
		WHERE
			Exclude_From_Assignment__c = false
		AND
			Area__r.Territory__c in : changedTerritoryIds])
	{
		accountIds.add(a.Id);
	}
	if(accountIds.size() > 0)
	{
		AccountAssignmentHelper.calculateOwners(accountIds);
	}

/*

//RJD - 2010-08-03 - This is NOT- bulkified follows bad practice
for(Territory__c tt :Trigger.new)
	{
		Id tManagerId=tt.Territory_Manager__c; 
		Area__c[] Areas=[Select id,Type__c, Area_Postcode__c From Area__c where Area__c.Territory__c =:tt.Id];
		for(Area__c Area :Areas)
		{
			Account[] Orgs=[Select Principle_Address_4_ZIP_Postal_Code__c, Id From Account where group__c=:Area.Type__c and Principle_Address_4_ZIP_Postal_Code__c=:Area.Area_Postcode__c ];
			for(Account org:Orgs)
			{
				org.OwnerId=tManagerId;
				Update org;
			}
		}
	}
	
	*/
}