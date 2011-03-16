trigger OpportunityTrigger on Opportunity (before update,after update ) {

    if(trigger.isBefore)
        OpportunityTriggerMethods.updateOpportunityFields(trigger.newMap);
        
    if(trigger.isAfter) {
        OpportunityTriggerMethods.updateAccountFields(trigger.new);
        
        //Only fire when saving a single opportunity, we dont want this
        //to fire for bulk data migration
        if(trigger.new.size() == 1){
        	Opportunity thisOpp = trigger.new.get(0);
        	//if(thisOpp.Migrated__c == false){
        		OpportunityRollup.rollUpOpportunityValue(thisOpp);
        	//}
        }
    }
}