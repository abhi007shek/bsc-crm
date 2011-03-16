@istest
class TestSubscriptionRenewal
{
	static testmethod void TestSubscriptionRenewalMethod()
	{
		 		 
		Product2 prod = new Product2(Name = 'Product Test', Initial_Reminder_Days__c = 1);
		insert prod;		
		
		Pricebook2 stdPricebook = [Select Id From Pricebook2 Where IsStandard = true Limit 1];		
		PricebookEntry pbe = new PricebookEntry(
			Pricebook2Id = stdPricebook.Id,
			Product2Id = prod.Id,
			UnitPrice = 100,
			IsActive = true);
		insert pbe;
		
		Account account  = new Account(Name = 'test account');
		
		System.debug('** inserting account');
		insert account;
  		System.debug('** finished inserting account');
  		
        Subscription__c subscription=new Subscription__c(
        	Account_Name__c = account.id,
        	Status__c = 'Current - Renewing',
        	Start_Date__c = System.Today(),
        	End_Date__c = System.Today(),
        	Type__c = 'New',
        	Renewal_Opportunity__c = true,
        	Renewal_Opportunity_Created__c = false,
        	Renewal_Reminders__c = true);
        insert subscription;
        
		Subscription_Line__c subscriptionLineItem = new Subscription_Line__c(
			Subscription__c = subscription.Id,
			Quantity__c = 10,
			Quantity_Available__c = 10,
			Product_Sales_Price__c = 100,
			Renewal_Price__c = 100,
			Product__c =  prod.id);
		insert subscriptionLineItem;
       
		Test.startTest();

		ScheduleSubscriptionRenewalBatch  x= new ScheduleSubscriptionRenewalBatch();
		Schedulablecontext  y;
		x.execute(y);

		Test.stopTest();
		
		/* Retrieve the created record */
		RecordType recordType = [SELECT Id FROM RecordType WHERE SobjectType = 'Opportunity' AND Name = 'Subscription' LIMIT 1];
		List<Opportunity> renewalApps = [select Id from Opportunity where Type = 'Subscription Renewal' and
			StageName = 'Qualifying' and Name = 'Subscription Renewal' and Renewal_Opportunity__c = true
			and AccountId = :account.Id];
		
		Integer numberOfOppsCreated = renewalApps.size();
		
		//System.assertEquals(1, numberOfOppsCreated);
	}
}