global class SubscriptionRenewalBatch implements Database.Batchable<sObject>{

	global final String query;
	
	/* Constructor */
	global SubscriptionRenewalBatch(String q){
		query = q;
	}
	
	global Database.QueryLocator start(Database.BatchableContext bc){
  		System.debug('*** Batch start  ***');
		return Database.getQueryLocator(query); 
	}
	
	global void execute(Database.BatchableContext BC, List<sObject> subscriptionList) {
		
		System.debug('** running SubscriptionRenewal batch execute. Rowcount: ' + subscriptionList.size());
		
		//Get the opportunity record type of "Subscription"
		RecordType recordType = [SELECT Id FROM RecordType WHERE
				SobjectType = 'Opportunity' AND
				Name = 'Subscription' LIMIT 1];
		
		//For each renewal subscription create an opportunity
		for (sObject item : subscriptionList) {
			
			Subscription__c subscription = (Subscription__c)item;
			
			Opportunity opportunity = new Opportunity(
				Type = 'Subscription Renewal',
				StageName = 'Qualifying',
				Name = 'Subscription Renewal',
				Subscription_Initiating_Renewal__c = subscription.Id,
				Renewal_Reminders__c = subscription.Renewal_Reminders__c,
				Renewal_Opportunity__c = true,
				CloseDate = subscription.End_Date__c,
				AccountId = subscription.Account_Name__c,
				RecordTypeId = recordType.Id);

			//Set the owner and create opportunity
			if (subscription.Subscription_Manager__c == null){
				opportunity.OwnerId = subscription.Account_Name__r.OwnerId;
			} else {
				opportunity.OwnerId = subscription.Subscription_Manager__c;
                // Change done by Navin Muneesamy -- 10/02/2011
                // Change requested by Jonathan Jones
                // if the subscription manager is used,  the field "Disable_re_assignment__c" on the new opportunity is TRUE
                opportunity.Disable_re_assignment__c = true;				
			}
			insert opportunity;
			
			System.debug('** Created opportunity: ' + opportunity.id);
			
			subscription.Renewal_Opportunity_Created__c = true;
			
			//If we dont have any line items then skip to next subscription
			if (subscription.Subscription_Lines__r == null) {
				continue;
			}				
			
			//Create opportunity line items from subscription line items
			List<OpportunityLineItem> opportunityLineItems = new List<OpportunityLineItem>();

			for (Subscription_Line__c subscriptionLine : subscription.Subscription_Lines__r) {
				
				List<PricebookEntry> pricebookEntries = null;
				 // Case 00001610 changing the reference from Account_Name__r.Pricebook__c to Account_Name__r.Pricebook2__c.
				if(subscription.Account_Name__r.Pricebook__c != null && subscriptionLine.Product__c != null){
					pricebookEntries = [SELECT Id, UnitPrice FROM PricebookEntry
						WHERE Pricebook2Id = :subscription.Account_Name__r.Pricebook2__c
						AND Product2Id = :subscriptionLine.Product__c 
						limit 1];
				}
						
				if (pricebookEntries != null && !pricebookEntries.isEmpty()) {

					PricebookEntry pricebookEntry = pricebookEntries.get(0);					

					OpportunityLineItem opportunityLineItem = new OpportunityLineItem(
						Quantity = subscriptionLine.Quantity__c,
						OpportunityId = opportunity.Id,
						PricebookEntryId = pricebookEntry.Id,
						TotalPrice = pricebookEntry.UnitPrice * subscriptionLine.Quantity__c,
						Renewal_Price__c = subscriptionLine.Renewal_Price__c > 0 ? subscriptionLine.Renewal_Price__c : null,
						Pricing_Exception__c = subscriptionLine.Renewal_Price__c > 0 ? true : false);
						
						opportunityLineItems.add(opportunityLineItem);
				}
				
			}
			insert opportunityLineItems;
		}
		
		update subscriptionList;
	}
	
	global void finish(Database.BatchableContext BC){
		System.debug('*** Batch finish ***');
	}
 
}