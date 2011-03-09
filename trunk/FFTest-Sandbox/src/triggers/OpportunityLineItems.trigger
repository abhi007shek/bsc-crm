trigger OpportunityLineItems on OpportunityLineItem (after update, before update) {

   if(trigger.isBefore)
        OpportunityLineItemsTriggerMethods.countQuantity(trigger.newMap,trigger.oldMap);
    
	if(trigger.isAfter)
    {   
     	try{
     		OpportunityLineItemsTriggerMethods.updateOpportunityExt(trigger.newMap.keySet());
     	}
     	catch(System.Asyncexception e)
     	{
     		OpportunityLineItemsTriggerMethods.updateOpportunity(trigger.newMap.keySet());
     	}
    }
}