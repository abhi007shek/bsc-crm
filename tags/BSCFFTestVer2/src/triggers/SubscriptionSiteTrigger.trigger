trigger SubscriptionSiteTrigger on Subscription_Site__c (after insert, after update,
after delete) {
	
	System.debug('** SubscriptionSiteTrigger');
	
	Subscription_Site__c site;
	if(Trigger.isDelete && Trigger.old.size() == 1){
		site = Trigger.old.get(0);
	} 
	
	if(!Trigger.isDelete && Trigger.new.size() == 1){
		site = Trigger.new.get(0);	
	}
		
	if(site != null && site.Site_Account__c != null){
		AccountMemberCheck.setAccountMemberFlag(site.Site_Account__c);
	}
}