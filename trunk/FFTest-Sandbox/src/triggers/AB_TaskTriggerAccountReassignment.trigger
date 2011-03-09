/*
	2010-09-16 - Andy Bolton 
	Functionality is to update the owners of the accounts when a Task is created or updated.
*/

trigger AB_TaskTriggerAccountReassignment on Task (before insert, before update)
{
	// List of all Account objects referenced by the Activity (Task)
	Set<id> changedActivityIds = new Set<id>();
	for (Task task : trigger.new)
	{
		if (task.WhatId != null && (String.valueOf(task.WhatId).substring(0, 3) == '001'))
			// WhatId is an Account object.
			changedActivityIds.add(task.WhatId);		
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