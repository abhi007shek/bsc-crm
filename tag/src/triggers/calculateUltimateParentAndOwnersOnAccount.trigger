trigger calculateUltimateParentAndOwnersOnAccount on Account (before delete, before insert, after insert, before update) {
    
    Account_Trigger_Flags__c settings = Account_Trigger_Flags__c.getInstance('Deactivated');
    System.debug('\nDEBUG_CLASS\nCalling "Deactivation Flags:' + settings.Account_Assignment_Deactivated__c + '"\nDEBUG_CLASS"');
    if (!settings.Account_Assignment_Deactivated__c)
    {
    	TriggerContextHelper helper = new TriggerContextHelper();
    	
    	// Run hierarchy update logic (includes updating ultimate parent and hierarchy employees)
    	System.debug('\nDEBUG_CLASS\nCalling "Account Trigger Before Call"\nDEBUG_CLASS"');
    	if ((helper.runningFirstTime || TriggerContextHelper.triggerStage == 'HIERARCHY_UPDATE') && Trigger.isBefore)
    	{
    		System.debug('\nDEBUG_CLASS\nCalling "calculateHierarchyFields"\nDEBUG_CLASS"');
        	TriggerContextHelper.triggerStage = 'HIERARCHY_UPDATE';
        	AccountHierarchyHelper.calculateHierarchyFields(trigger.new, trigger.oldmap);
    	}
    
    	// Run owner update logic
    	if ((helper.runningFirstTime || TriggerContextHelper.triggerStage == 'OWNER_UPDATE') &&
    		(!Trigger.isInsert || (Trigger.isInsert && Trigger.isAfter)))
    	{
        	TriggerContextHelper.triggerStage = 'OWNER_UPDATE';
        	AccountAssignmentHelper.calculateOwnersOnTrigger(trigger.new, trigger.oldMap, Trigger.isDelete);
    	}
    
    	// Reset all values ready for after triggers
    	if (helper.runningFirstTime)
    		TriggerContextHelper.resetRun();
    }
}