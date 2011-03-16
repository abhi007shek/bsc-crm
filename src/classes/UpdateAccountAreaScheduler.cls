global with sharing class UpdateAccountAreaScheduler implements Schedulable 
// Case 0001359 and Case 0001254
// New class to schedule the batch BatchUpdateAccountArea 
{
	global void execute(SchedulableContext SC) 
	{
		BatchUpdateAccountArea batch = new BatchUpdateAccountArea(1);
        	Database.executeBatch(batch, 40);
	}
}