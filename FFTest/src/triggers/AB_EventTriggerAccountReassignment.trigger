/*
	2010-09-16 - Andy Bolton 
	Functionality is to update the owners of the accounts when an Event is created or updated.
*/

trigger AB_EventTriggerAccountReassignment on Event (before insert, before update)
{
	// List of all Account objects referenced by the Activity (Event)
	Set<id> changedActivityIds = new Set<id>();
	for (Event event : trigger.new)
	{
		if (event.WhatId != null && (String.valueOf(event.WhatId).substring(0, 3) == '001'))
			// WhatId is an Account object.
			changedActivityIds.add(event.WhatId);		
	}
	if (!changedActivityIds.isEmpty())
	{
		// Get a list of associated accounts.
		
		List<Account> accountList = new List<Account>([
			SELECT
				Id
			From
				Account
			WHERE
				Id
			IN
				:changedActivityIds]);
		if (!accountList.isEmpty())
			update accountList;
	}
}