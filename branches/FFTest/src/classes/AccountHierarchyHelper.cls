/*
	Created by Ben Mansfield 09 July 2010
	Modified by Ben Mansfield 29 July 2010
	
	Description:
		When an account hierarchy is created or updated, the trigger finds out which account is at the top
		level and adds this account id to all accounts in that hierarchy using the Ultimate_Parent__c lookup field.
		
		Also added delete scenario which only updates the deleted account children
		
		This trigger also calculates hierarchy employees
		
	Changes:
		14 July 2010
		* Updated so that if there is a circular reference we ignore a child update
		
		20 July 2010
		* added test methods
		
		29 July 2010
		* added support for employee numbers hierarchy
		* moved Ultimate parent code so that it fits in better with employee numbers hierarchy
		* modified code so that if any data on an account hasn't changed when recalculated it 
			doesn't update the account. This is to stop the trigger from calling the same records in the same process
		
*/
public with sharing class AccountHierarchyHelper {
	
	private static Set<Id> alreadyUpdated;
	
	public static void calculateHierarchyFields(List<Account> targets, Map<Id, Account> oldtargets)
	{
		if (alreadyUpdated == null)
			alreadyUpdated = new Set<Id>();
		
		Set<Id> modifiedParents = new Set<Id>();
		Map<Id, Account> parentAccounts = null;
		Set<Id> ultimateParents = new Set<Id>();
		if (Trigger.isInsert)
		{
			parentAccounts = getAllParentAccounts(targets, oldTargets);
			
			// Note: account ids will be null here so we can't really store already updated data
			for (Account acc : targets)
			{
				Id id = calculateUltimateParent(acc, null, parentAccounts);
				if (id != null)
					ultimateParents.add(id);
				modifiedParents.addAll(calculateHierarchyEmployeeNumbers(acc, null, parentAccounts));
			}
		}
		else if (Trigger.isUpdate)
		{
			parentAccounts = getAllParentAccounts(targets, oldTargets);
			for (Account acc : targets)
			{
				if (alreadyUpdated.contains(acc.Id))
					continue;
				System.debug('\nDEBUG_CLASS\nCalling "calculateHierarchyEmployeeNumbers" from Update for ' + acc.Id + '\nDEBUG_CLASS"');
				Id id = calculateUltimateParent(acc, oldtargets.get(acc.Id), parentAccounts);
				if (id != null)
					ultimateParents.add(id);
				modifiedParents.addAll(calculateHierarchyEmployeeNumbers(acc, oldtargets.get(acc.Id), parentAccounts));
				
				alreadyUpdated.add(acc.Id);
			}
			
			calculateUltimateParentForChildren(targets, false);
		}
		else if (Trigger.isDelete)
		{
			// calculate hierarchy employee numbers but only use oldtarget account
			parentAccounts = getAllParentAccounts(oldTargets.values(), null);
			for (Account acc : oldTargets.values())
			{
				System.debug('\nDEBUG_CLASS\nCalling "calculateHierarchyEmployeeNumbers"\nDEBUG_CLASS"');
				modifiedParents.addAll(calculateHierarchyEmployeeNumbers(null, acc, parentAccounts));
			}
			
			// If is delete we need to get the deleted children and update these with a null ultimate parent reference
			ultimateParents.addAll(calculateUltimateParentForChildren(oldtargets.values(), true));
		}
		
		// Only update parents that have been modified
		//Map<Id, Account> ultimateParentMap = CalculateUltimateParentEmployees(ultimateParents);
		
		List<Account> parentsToUpdate = new List<Account>();
		
		if (parentAccounts != null)
		{
			for (Id id : modifiedParents)
			{
			//	if (ultimateParentMap.ContainsKey(id))
			//		parentsToUpdate.add(parentAccounts.get(id));
			//	else
					parentsToUpdate.add(parentAccounts.get(id));
			}
		}
		//update ultimateParentMap.values();
		
		

/*		Boolean bFound;
		for (Account account : ultimateParentList)
		{
			bFound = false;
			for (Account tAccount : parentsToUpdate)
			{
				if (tAccount.Id == account.Id)
					bFound = true;
			}
			if (!bFound)
				parentsToUpdate.add(account);				
		}*/
		if (parentsToUpdate.size() > 0)
			update parentsToUpdate;
	}
	
	public static Map<Id, Account> CalculateUltimateParentEmployees(Set<Id> ultimateParents)
	{
		Map<Id, List<Account>> ultimateParentMap = new Map<Id, List<Account>>();
		List<Account> ultimateParentList = new List<Account>();
		map<Id, Account> modifiedMap = new Map<Id, Account>();
		for (Account ultimateParent : [
			SELECT
				Id,
				Hierarchy_Employees__c,
				NumberOfEmployees
			FROM
				Account
			WHERE
				Id IN : ultimateParents])
		{
			ultimateParentList.add(ultimateParent);
			ultimateParentMap.put(ultimateParent.Id, new List<Account>());
		}
		
		for (Account sibling : [
			SELECT
				Id,
				Hierarchy_Employees__c,
				NumberOfEmployees,
				Ultimate_Parent__c
			FROM
				Account
			WHERE
				Ultimate_Parent__c IN : ultimateParentMap.KeySet()])
		{
			ultimateParentMap.get(sibling.Ultimate_Parent__c).add(sibling);
		}
		Double dTotal = 0.0;
		for (Account ultimateParent : ultimateParentList)
		{
			if (ultimateParent.NumberOfEmployees == null)
				ultimateParent.NumberOfEmployees = 0;
			dTotal = ultimateParent.NumberOfEmployees;
			for (Account sibling : ultimateParentMap.get(ultimateParent.Id))
			{
				if (sibling.NumberOfEmployees == null)
					sibling.NumberOfEmployees = 0;
				dTotal += sibling.NumberOfEmployees;
				sibling.Hierarchy_Employees__c = sibling.NumberOfEmployees;
				modifiedMap.put(sibling.Id, sibling);				
			}
			ultimateParent.Hierarchy_Employees__c = dTotal;
			modifiedMap.put(ultimateParent.Id, ultimateParent);
		}
		return modifiedMap;
	}
	
	private static Map<Id, Account> getAllParentAccounts(List<Account> targets, Map<Id, Account> oldtargets)
	{
		Set<Id> parentIds = new Set<Id>();
		// Get all parent ids from new and old trigger records
		for (Account acc : targets)
		{
			if (acc.ParentId != null)
				parentIds.add(acc.ParentId);
			if (oldtargets != null && oldtargets.get(acc.Id).ParentId != null)
				parentIds.add(oldtargets.get(acc.Id).ParentId);
		}
		
		System.debug('\nDEBUG_CLASS\nCalling "getAllParentAccounts": ' + parentIds + '\nDEBUG_CLASS"');
		
		return new Map<Id, Account>([
			SELECT
				Id,
				Name,
				ParentId,
				Ultimate_Parent__c,
				NumberOfEmployees,
				Hierarchy_Employees__c
			FROM
				Account
			WHERE
				Id in :parentIds]);
	}
	
	private static Id calculateUltimateParent(Account target, Account oldtarget, Map<Id, Account> parents)
	{
		// brm - removed ultimate parent check since this recalculates unnecessarily when we update the children
		if (oldTarget == null ||
			(target.ParentId != oldTarget.ParentId /*|| acc.Ultimate_Parent__c != oldTargets.get(acc.Id).Ultimate_Parent__c*/))
		{
			// If this account has a parent and the parent is in the map
			if (target.ParentId != null && parents.containsKey(target.ParentId))
			{
				// Get parent
				Account parent = parents.get(target.ParentId);
				// find the current accounts ultimate parent
				return updateAccount(target, parent);
			}
			else
			{
				target.Ultimate_Parent__c = null;
			}
		}
		return null;
	}
	
	private static Set<Id> calculateUltimateParentForChildren(List<Account> targets, Boolean targetsDeleted)
	{
		Set<Id> accountIdsForChildren = new Set<Id>();
		Set<Id> ultimateParentIds = new Set<Id>();
		for (Account acc : targets)
		{
			accountIdsForChildren.add(acc.Id);
		}
		
		// get the children below this record
		Map<Id, List<Account>> childAccounts = getAccountChildren(accountIdsForChildren);
		
		List<Account> childrenToUpdate = new List<Account>();
		for (Account acc : targets)
		{
			// Update children with a new ultimate parent
			if (childAccounts.containsKey(acc.Id))
			{
				for (Account child : childAccounts.get(acc.Id))
				{
					// brm - 14 July 2010 - If this account has already been updated, don't update again
					if (alreadyUpdated.contains(child.Id))
					{
						continue;
					}
					
					String oldUltimate = child.Ultimate_Parent__c;
					Id id = updateAccount(child, (!targetsDeleted ? acc : null));
					if (id != null)
					{
						ultimateParentIds.add(id);
					}
					// brm - 29 July 2010 - If the ultimate parent field has changed
					if (oldUltimate != child.Ultimate_Parent__c)
						childrenToUpdate.add(child);
					
					// brm - 14 July 2010 - Store which accounts are currently being updated
					alreadyUpdated.add(child.Id);
				}
			}
		}
		if (childrenToUpdate.size() > 0)
			update childrenToUpdate;
		return ultimateParentIds;
	}
	
	private static Id updateAccount(Account acc, Account parent)
	{
		// If there is no parent force the child account to have a null ultimate parent
		if (parent == null)
		{
			acc.Ultimate_Parent__c = null;
			return null;
		}
		
		// If the parent's ultimate parent is null
		if (parent.Ultimate_Parent__c == null)
		{
			// current account should have ultimate parent set as this parent
			acc.Ultimate_Parent__c = parent.Id;
		}
		// If the parent has an ultimate parent
		else
		{
			// current account should have ultimate parent set as the parent's ultimate parent
			acc.Ultimate_Parent__c = parent.Ultimate_Parent__c;
		}
		return acc.Ultimate_Parent__c;
	}
	
	private static Map<Id, List<Account>> getAccountChildren(Set<Id> parentAccountIds)
	{
		Map<Id, List<Account>> children = new Map<Id, List<Account>>();
		
		for (Account child : [
			SELECT
				Id,
				Name,
				ParentId,
				Ultimate_Parent__c
			FROM
				Account
			WHERE
				ParentId in :parentAccountIds])
		{
			if (!children.containsKey(child.ParentId))
			{
				children.put(child.ParentId, new List<Account>());
			}			
			children.get(child.ParentId).add(child);
		}
		
		return children;
	}
	
	private static Set<Id> calculateHierarchyEmployeeNumbers(Account target, Account oldtarget, Map<Id, Account> parents)
	{
		Set<Id> parentsChanged = new Set<Id>();
		System.debug('\nDEBUG_CLASS\ncalculateHierarchyEmployeeNumbers target: ' + target + '\nDEBUG_CLASS"');
		if (target == null ||
			oldtarget == null ||
			target.NumberOfEmployees != oldtarget.NumberOfEmployees ||
			target.ParentId != oldtarget.ParentId ||
			target.Hierarchy_Employees__c != oldtarget.Hierarchy_Employees__c)
		{
			System.debug('\nDEBUG_CLASS\ncalculateHierarchyEmployeeNumbers target: ' + target + '\n oldtarget:' + oldtarget + '\n parents:' + parents +'\nDEBUG_CLASS"');
			Double oldNumEmps = 0;
			// subtract (old numberofemployees + old employee hierarchy count) from old parent hierarchy count
			if (oldtarget != null)
			{
				oldNumEmps = (oldtarget.NumberOfEmployees != null ? oldtarget.NumberOfEmployees : 0);
				
				if (oldtarget.ParentId != null && parents.containsKey(oldtarget.ParentId))
				{
					// work out hierarchy employees for old parent
					Double oldCount = (oldtarget.Hierarchy_Employees__c != null ? oldtarget.Hierarchy_Employees__c : 0);
					
					if (parents.get(oldtarget.ParentId).Hierarchy_Employees__c == null)
						parents.get(oldtarget.ParentId).Hierarchy_Employees__c = 0;
					parents.get(oldtarget.ParentId).Hierarchy_Employees__c -= oldCount;
					
					parentsChanged.add(oldtarget.ParentId);
				}
			}
			
			// add (new numberofemployees + new employee hierarchy) to new parent hierarchy count
			if (target != null)
			{
				// work out hierarchy employees for this account first
				if (target.Hierarchy_Employees__c == null)
					target.Hierarchy_Employees__c = 0;
				target.Hierarchy_Employees__c -= oldNumEmps;
				target.Hierarchy_Employees__c += (target.NumberOfEmployees != null ? target.NumberOfEmployees : 0);
				//calculateEmployeeNumbersGroup(target);
				
				if (target.ParentId != null && parents.containsKey(target.ParentId))
				{
					// work out hierarchy employees for parent
					Double newCount = (target.Hierarchy_Employees__c != null ? target.Hierarchy_Employees__c : 0);
					
					if (parents.get(target.ParentId).Hierarchy_Employees__c == null)
						parents.get(target.ParentId).Hierarchy_Employees__c = 0;
					parents.get(target.ParentId).Hierarchy_Employees__c += newCount;
					
					parentsChanged.add(target.ParentId);
				}
			}
		}
		
		return parentsChanged;
	}
	
	/*
	private static void calculateEmployeeNumbersGroup(Account target)
	{
		if (target.Hierarchy_Employees__c < 50) target.Group__c = 'AE';
		else if (target.Hierarchy_Employees__c >= 50 && target.Hierarchy_Employees__c < 500) target.Group__c = 'RAM';
		else target.Group__c = 'KAM';
		
		if (target.ParentId != null) target.Group__c += '-Child';
	}
	*/
	
	@IsTest
	private static void test()
	{
		Account_Trigger_Flags__c settings = Account_Trigger_Flags__c.getInstance('Deactivated');
		if (settings.Account_Assignment_Deactivated__c)
		{
			System.debug('********************************************\n\n' +
				'Account Trigger Flags[Deactivated] must be set to false for tests to complete.' +
				'\n\n*************************************************');	
		}
		// Insert parent
		Account parent = new Account(
			Name = 'Parent Account',
			NumberOfEmployees = 1);
		insert parent;
		
		AccountHierarchyHelper.alreadyUpdated = null;
		
		// Insert child to create a hierarchy
		Account child = new Account(
			Name = 'Child Account',
			ParentId = parent.Id,
			NumberOfEmployees = 4);
		insert child;
		
		AccountHierarchyHelper.alreadyUpdated = null;
		
		// Check that the child ultimate parent has been linked to parent
		child = [
			SELECT
				Id,
				ParentId,
				Ultimate_Parent__c,
				NumberOfEmployees,
				Hierarchy_Employees__c
			FROM
				Account
			WHERE
				Id = :child.Id Limit 1];
		// Check parent id is the same as the Ultimate parent.
		System.assertEquals(parent.Id, child.Ultimate_Parent__c);
		// Check 
		System.assertEquals(child.NumberOfEmployees, child.Hierarchy_Employees__c);
		
		// Check that the parent hierarchy employees has been updated
		parent = [
			SELECT
				Id,
				Name,
				NumberOfEmployees,
				Hierarchy_Employees__c
			FROM
				Account
			WHERE
				Id = :parent.Id];
		System.assertEquals(child.NumberOfEmployees + parent.NumberOfEmployees, parent.Hierarchy_Employees__c);
		
		// Create a new top level parent
		Account newParent = new Account(
			Name = 'Top Parent Account');
		insert newParent;
		
		AccountHierarchyHelper.alreadyUpdated = null;
		
		// Update old parent to link to new top level parent
		parent.ParentId = newParent.Id;
		update parent;
		
		// Check that the top parent hierarchy employees has been updated
		newParent = [
			SELECT
				Id,
				Name,
				NumberOfEmployees,
				Hierarchy_Employees__c
			FROM
				Account
			WHERE
				Id = :newParent.Id];
		System.assertEquals(child.NumberOfEmployees + parent.NumberOfEmployees, newParent.Hierarchy_Employees__c);
		
		AccountHierarchyHelper.alreadyUpdated = null;
		
		// Check that the child ultimate parent has been linked to the new parent
		child = [
			SELECT
				Id,
				ParentId,
				Ultimate_Parent__c
			FROM
				Account
			WHERE
				Id = :child.Id Limit 1];
		System.assertEquals(newParent.Id, child.Ultimate_Parent__c);
		
		// Delete account from middle of hierarchy to cover delete part of trigger
		delete parent;
		
		AccountHierarchyHelper.alreadyUpdated = null;
		
		// Check that the top parent hierarchy employees has been updated
		newParent = [
			SELECT
				Id,
				Name,
				NumberOfEmployees,
				Hierarchy_Employees__c
			FROM
				Account
			WHERE
				Id = :newParent.Id];
		System.assertEquals(0, newParent.Hierarchy_Employees__c);
		
		// Check that the child ultimate parent has been removed
		child = [
			SELECT
				Id,
				ParentId,
				Ultimate_Parent__c
			FROM
				Account
			WHERE
				Id = :child.Id Limit 1];
		System.assertEquals(null, child.Ultimate_Parent__c);
	}
}