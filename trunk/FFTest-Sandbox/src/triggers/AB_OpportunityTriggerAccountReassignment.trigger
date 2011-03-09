/*
	2010-09-16 - Andy Bolton 
	Functionality is to update the owners of the accounts when an Opportunity is created or updated.
*/
trigger AB_OpportunityTriggerAccountReassignment on Opportunity (before insert, before update) {
	
	Account_Trigger_Flags__c settings = Account_Trigger_Flags__c.getInstance('Deactivated');
	
	System.debug('** Account assignment deactivated flag is: ' + settings.Account_Assignment_Deactivated__c);
	
	//If account assignment is active (i.e. not in data migration mode)
    if (!settings.Account_Assignment_Deactivated__c) {
		
		List<Id> accountIdList = new List<Id>();
		for (Opportunity opportunity : trigger.new){
			if(opportunity.IsClosed == false)
				accountIdList.add(opportunity.AccountId);
		}
		if(!accountIdList.isEmpty())
		{
			//Create a map of the account vs owner id
			Map<Id, Account> accountOwners =  new Map<Id, Account> ([SELECT Id, OwnerId From Account
				WHERE Id IN :accountIdList]);
			
			//For each opportunity update the owner to be the account owner 
			for (Opportunity opportunity : trigger.new)
			{
				Account acc = accountOwners.get(opportunity.AccountId);
			
				if(opportunity.Disable_re_assignment__c == false && acc != null)
					opportunity.OwnerId = acc.OwnerId;
				
		   }
		
	 	}

    }
}