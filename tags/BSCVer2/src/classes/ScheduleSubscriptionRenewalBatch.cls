global class ScheduleSubscriptionRenewalBatch implements Schedulable {
	
	private String query = 'SELECT '
		+ 'Account_Name__r.Pricebook__c, Account_Name__r.OwnerId, Subscription_Manager__c, '
		+ 'Renewal_Reminders__c, Renewal_Opportunity__c, Id, First_Reminder_Date__c, '
		+ 'End_Date__c, Account_Name__c, '
		+ '(SELECT Quantity__c, Product__c, Renewal_Price__c FROM Subscription_Lines__r) '
		+ 'FROM Subscription__c '
		+ 'WHERE Renewal_Opportunity__c = true '
		+ 'AND Renewal_Opportunity_Created__c <> true '
		+ 'AND Status__c = \'Current - Renewing\'';
	 
    global void execute(SchedulableContext SC) {
    	
    	System.debug('** running ScheduleSubscriptionRenewalBatch');
    	System.debug('** query: ' + query);
    	
        SubscriptionRenewalBatch subsRenewal = new SubscriptionRenewalBatch(query); 
        ID batchprocessid = Database.executeBatch(subsRenewal, 50);
    }
    
}