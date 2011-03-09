public with sharing class RunBatchUpdateAccountController {
	Public RunBatchUpdateAccountController()
	{
		
	}
	Public PageReference RunBatchUpdateHierarchy ()
	{
		integer accountCount = [select count() from account];
		BatchUpdateAccountHeirarchy batch = new BatchUpdateAccountHeirarchy(accountCount);
	    Database.executeBatch(batch, 100);
	    return null;
	}
}