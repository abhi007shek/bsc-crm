trigger SubscriptionTrigger on Subscription__c (after insert, after update,
after delete) {
	
	System.debug('** SubscriptionTrigger');

	Subscription__c sub;
	if(Trigger.isDelete && Trigger.old.size() == 1){
		sub = Trigger.old.get(0);
	} 
	
	if(!Trigger.isDelete && Trigger.new.size() == 1){
		sub = Trigger.new.get(0);	
	}
		
	if(sub != null && sub.Account_Name__c != null){
		AccountMemberCheck.setAccountMemberFlag(sub.Account_Name__c);
	}
}