trigger AB_SpecialEventBookingCreate on Special_Event__c (before insert)
{
/*	Set<Id> idMap = new Set<Id>();
	
	for (Special_Event__c event : trigger.new)
		idMap.add(event.Opportunity__c);
	Map<Id, Opportunity> opMap = new Map<Id, Opportunity>([
		SELECT Id, AccountId FROM Opportunity WHERE Id IN :idMap]);
	
	for (Special_Event__c event : trigger.new)
	{
		Opportunity opportunity = opMap.get(event.Opportunity__c);
		if (opportunity != null && opportunity.AccountId != null)
		{
			// For test runs only
			event.Venue__c = opportunity.AccountId;
		}
		//event.Status__c = 'Confirmed';
		//event.Stage__c = 'Provisional';
	}*/
}