global class BatchUpdateAccountArea implements Database.Batchable<sObject>
// Case 0001359 and Case 0001254
// New Class to Update Area on Account object
{
	global final String Query;
	public List<Integer> maxLevel = new List<Integer>();
	public static boolean isTest = false;
	
	global BatchUpdateAccountArea(Integer size)
	{
		if (isTest)
			Query = 'SELECT Id, Hierarchy_Employees__c, ParentId, NumberOfEmployees FROM Account WHERE ParentId != null LIMIT ' + size;
		else
		{
			// Query = 'SELECT Id, Hierarchy_Employees__c, ParentId, NumberOfEmployees FROM Account order by name' + ' LIMIT ' + size;
			Query = 'SELECT Id, Hierarchy_Employees__c, ParentId, NumberOfEmployees FROM Account order by name';
		}
			
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC)
	{
		return Database.getQueryLocator(query);
	}

	global void execute(Database.BatchableContext BC, List<Account> scope)
	{
		Account_Trigger_Flags__c settingsTrig =Account_Trigger_Flags__c.getInstance('Deactivated');
		settingsTrig.Account_Assignment_Deactivated__c = true;
		update settingsTrig;
		List<Account> accArea = new List<Account>();
		// System.Debug('*********************batchAccounts:'+batchAccounts.size());
		for (Account a: scope)
		{
			System.Debug('*********************batchAccounts Account:'+a);
			Account accUpdate =new Account(id=a.Id, Area__c=null);
			// Case 1359 and 1254
			if (a.parentId == null&&( (a.Hierarchy_Employees__c==null&&a.NumberOfEmployees!=null)||(a.Hierarchy_Employees__c<>a.NumberOfEmployees)))
	        {
	        	System.Debug('*********************batchAccounts Updating employees Hierarchy:'+a.NumberOfEmployees);
	        	accUpdate.Hierarchy_Employees__c = a.NumberOfEmployees;
	        	accUpdate.Employees_Group__c = accUpdate.Hierarchy_Employees__c;
	        }
		
			accArea.add(accUpdate);
		}
		update accArea;

		set<id>accountIds = new set<id>();
		for(Account a : scope)
		{
			/*Boolean result;
			result = accountIds.contains(a.Id);
			if (!result)
			{
				try
				{*/
					accountIds.add(a.Id);
				/*}
				catch (exception e)
				{
					continue;
				}
			}*/                    
		}
		if(accountIds.size() > 0){
			AccountAssignmentHelper.calculateOwnersBatch(accountIds);
		}
		
		settingsTrig.Account_Assignment_Deactivated__c = false;
		update settingsTrig;	
	}
	
    
    global void finish(Database.BatchableContext BC)
	{
		AsyncApexJob a = [
			SELECT
				Id,
				Status,
				NumberOfErrors,
				JobItemsProcessed,
				TotalJobItems,
				CreatedBy.Email
			FROM
				AsyncApexJob
			WHERE
				Id = : BC.getJobId()];
				
		String message = 'The batch Apex job processed ' + a.TotalJobItems + ' batches with '+
			a.NumberOfErrors + ' failures.';
		
		// Send an email to the Apex job's submitter notifying of job completion.
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		// Email the current user regarding the completion of the process
		user getCurrentUser = [Select u.email from user u where u.id = :UserInfo.getUserId()];
        // system.debug(getCurrentUser.email);
		// String[] toAddresses = new String[] {a.CreatedBy.Email, getCurrentUser.email};
		String[] toAddresses = new String[] {a.CreatedBy.Email, 'navin.muneesamy@2020management.com'};
		mail.setToAddresses(toAddresses);
		mail.setSubject('BatchUpdateAccountArea ' + a.Status);
		mail.setPlainTextBody('The batch Apex job processed ' + a.TotalJobItems + ' batches with '+ a.NumberOfErrors + ' failures.');
		Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
	}
    
    public static testMethod void tests()
	{
		Test.startTest();
		BatchUpdateAccountArea.isTest = true;
		BatchUpdateAccountArea batch = new BatchUpdateAccountArea(1);		
		Database.executeBatch(batch, 100);
		Test.stopTest();
	}  
}