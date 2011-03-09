/*
	2010-08-03 - Richard Durrant 
	Functionality is to update the owners of the accounts when the areas' territory is changed.
	
	
*/
trigger TriggerAreaAssignment on Area__c (after update) {


	set<id> changedAreaIds = new set<id>();
	for(Area__c a : trigger.new){
		if(a.Territory__c != trigger.oldMap.get(a.Id).Territory__c){
			changedAreaIds.add(a.id);
		}
	}
	
	if(changedAreaIds.size() > 0){
		AccountAssignmentHelper.doAreaAssignment(changedAreaIds);
	}
}