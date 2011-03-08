global class BatchUpdateAccountArea implements Database.Batchable<sObject>
{
	global final String Query;
	public List<Integer> maxLevel = new List<Integer>();
	public static boolean isTest = false;
	
	global BatchUpdateAccountArea(Integer size)
	{
		if (isTest)
			Query = 'SELECT Id FROM Account WHERE ParentId != null LIMIT ' + size;
		else
			Query = 'SELECT Id FROM Account Where area__c != null order by name' + ' LIMIT ' + size;
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC)
	{
		return Database.getQueryLocator(query);
	}

	global void execute(Database.BatchableContext BC, List<Account> scope)
	{
		//List<Account> a = new List<Account>();
		for (Account s : scope)
		{
			s.Area__c = null;	        
		}
		update scope;
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