/*
    Created by Ben Mansfield 30 July 2010
    Modified by Ben Mansfield 16 August 2010
    
    Description:
        Assigns account owners based on Group, Territory and Area.
        Owners are also assigned to Contacts, Open Opportunities and Open Activities linked to the accounts
        
    Changes:
    
        2 August 2010
        * Added trigger logic so that owner updates run when there is a change of address details
        
        16 August 2010
        * Modified postcode lookup so that it uses Area_Postcode__c on an Area__c record instead of 
            Postcode_District__c
        
        
*/
public with sharing class AccountAssignmentHelper {
	
	//@future(callout=false)
	public static void doAreaAssignment(set<id> changedAreaIds){
		
		set<id>accountIds = new set<id>();
		
		for(Account a : [select id, name from Account where Exclude_From_Assignment__c=false and Area__c in : changedAreaIds]){
			accountIds.add(a.Id);
		}
		
		if(accountIds.size() > 0){
			calculateOwners(accountIds);
		}
	}
    
    public static void calculateOwnersOnTrigger(List<Account> updatedAccounts, Map<Id, Account> oldAccounts, Boolean isDelete)
    {
        Set<Id> accountsToUpdate = new Set<Id>();
        
        if (!isDelete)
        {
            for (Account acc : updatedAccounts)
            {
            	// Only update if insert - filter updates, only update if specific criteria. 
            	// oldAccounts == null or # Employees has changed or Principle_Address_ZIP_Postal_Code has changed or
            	// Principle_Address_Country has changed or Ultimate_Parent has changed.
            	
                if (oldAccounts == null || acc.NumberOfEmployees != oldAccounts.get(acc.Id).NumberOfEmployees ||
                    acc.Hierarchy_Employees__c != oldAccounts.get(acc.Id).Hierarchy_Employees__c ||
                    // brm - 2 August 2010 - added logic to work with change of country or postcode
                    acc.Principle_Address_ZIP_Postal_Code__c != oldAccounts.get(acc.Id).Principle_Address_ZIP_Postal_Code__c ||
                    acc.Principle_Address_Country__c != oldAccounts.get(acc.Id).Principle_Address_Country__c ||
                    // brm - 3 August 2010 - added logic to work with changing parents
                    acc.Ultimate_Parent__c != oldAccounts.get(acc.Id).Ultimate_Parent__c)
                {
                    accountsToUpdate.add(acc.Id);
                }
            }
        }
        else
        {
            Set<Id> deletedAccounts = new Set<Id>();
            for (Account acc : oldAccounts.values())
            {
                // Force an update on the parent
                accountsToUpdate.add(acc.ParentId);
                
                // Get this account id
                deletedAccounts.add(acc.Id);
            }
            
            // Add child accounts of the updated accounts to the update list.
            for (Account child : [
            	SELECT
            		Id
            	FROM
            		Account
            	WHERE
            		ParentId IN :deletedAccounts])
            {
                accountsToUpdate.add(child.Id);
            }
        }
        
        if (accountsToUpdate.size() > 0)
        	calculateOwners(accountsToUpdate);
    }
    
    //****
    // calculateOwners
    //
    // Calculate owners based on location of Account address for Accounts and child Accounts.
    //****
    @future(callout=false)
    public static void calculateOwners(Set<Id> accountIds)
    {
    	System.debug('** calculate owners');
    	
        Set<Id> ultimateParents = new Set<Id>();
        
        // AB 17/09/2001
        // Create a list of accounts for post-processing,
        // added 'Principle_Address_Country__c' for PostprocessNonUKAccounts
        
        
        List<Account> accountList = new List<Account>([
        	SELECT
        		Id,
        		ParentId,
        		Ultimate_Parent__c,
        		Principle_Address_Country__c
        	FROM
        		Account
        	WHERE
        		Id
        	IN
        		:accountIds]);
        			
        for (Account a : accountList)
        {
            // Get out ultimate parents
            // If parent is null, this must be an ultimate parent, add to set.
            if (a.ParentId == null)
            	ultimateParents.add(a.Id);
            // otherwise if this account already has an Ultimate parent, add this to set.
            else if (a.Ultimate_Parent__c != null)
            	ultimateParents.add(a.Ultimate_Parent__c);
            // else this account has a parent, but it is not an ultimate parent, i.e., it too has a parent.
            
            // We lose this account object at this point. 
            
        }
               
        updateAccountOwners(ultimateParents);		// Standard processing
       // PostprocessNonUKAccounts(accountList); 		// Custom processing for non-UK accounts.
        
        
    }
    
    /*private static void PostProcessNonUKAccounts(List<Account> accounts)
    {
    	Set<Id> parentIds = new Set<Id>();
    	for (Account account : accounts)
    	{
    		// Create a list of Top level Ids for current accounts.
    		// This account has a parent, i.e., it cannot be a top level account,
    		// therefore must have an ultimate parent. Add the ultimate parent to the 
    		// list.
    		if (account.ParentId != null)
    			parentIds.add(account.Ultimate_Parent__c);
    		// else this must be a top level account, and already has the owner assigned.
    	}
    	
    	
    	// List of all accounts in the supplied Account's hierarchy, not in any sort of order.
    	List<Account> hierarchicalAccounts = new List<Account>();
    	hierarchicalAccounts.addAll(accounts);	// Add all Accounts retrieved so far.
    	List<Account> temp = null;
    	
    	
    	if (!parentIds.isEmpty())
    	{
    		// Accounts contains only top-level account objects.
    		do
    		{
    			// Clear out temporary account list.
    			if (temp != null)
    				temp.clear();
    			// Select the accounts with parents contained in parentIds.
    			temp = new List<Account>([
    				SELECT
    					Id,
    					ParentId,
    					Principle_Address_Country__c
    				FROM
    					Account
    				WHERE
    					Id
    				IN
    					:parentIds]);
    			
    			// Done, clear the parentIds list
    			parentIds.clear();
    			
    			// Re-populate the parentIds list.
    			for (Account a : temp)
    			{
    				if (a.ParentId != null)
    					parentIds.add(a.ParentId);
    			}
    			

				// Add the recently selected accounts to the master list.
    			hierarchicalAccounts.addAll(temp);
    		}    		  	
    		while (!temp.isEmpty());// Loop until we get no more accounts. 
    	}
    	

    	// Create a linked list of accounts, use a map to prevent dupes.
    	Map<Id, AccountLinkedList> accountMap = new Map<Id, accountLinkedList>();
    	
    	
    	for (Account account :hierarchicalAccounts)
    	{
    		if (!accountMap.containsKey(account.Id))
    		{
    			AccountLinkedList all = new AccountLinkedList(account);
    			all.AddChildren(hierarchicalAccounts);
    			accountMap.put(all.account.Id, all);
    		}  		
    	}
    	
    	// Convert to list for iteration.   	
    	List<AccountLinkedList> accountList = accountMap.values();
    	List<Account> nonUKAccounts = new List<Account>();
    	Set<String> countries = new Set<String>();
    	
    	for (AccountLinkedList accountLink : accountList)
    	{
    		if (accountLink.childAccounts.isEmpty())
    		{
    			// Process reverse hierarchical chain (i.e., account has no children).
    			// Navigate up through the hierarchy until we get an account with no parent.
    			List<AccountLinkedList> parentChildList = new List<AccountLinkedList>();
    			parentChildList.add(accountLink);
    			
    			AccountLinkedList link = accountLink;
    			
    			while (link != null && link.account != null && link.account.ParentId != null)
    			{
    				// Hive off the non-UK accounts only
    				if (link.account.Principle_Address_Country__c != 'United Kingdom')
    				{
    					countries.add(link.account.Principle_Address_Country__c);
    					nonUKAccounts.add(link.account); 	
    				}
    					   					
    				AccountLinkedList tempAll = accountMap.get(link.account.ParentId);
    				if (tempAll != null)
    					parentChildList.add(tempAll);
    				link = tempAll;
    			}
    		}
    	}
    	
    	// Process locations for non-UK Accounts
    	for (Account account : nonUKAccounts)
    	{
    		// Locate territory for country.
    		Map<String, Map<String, Area__c>> areas = getNonUkAreas(countries);
    		Area__c found = findAreaFromAddress(account, areas);
    		if (found != null)
    			account.OwnerId = found.Territory__r.Territory_Manager__c;
    	}
    	// Create new trigger context helper so that when updating accounts it 
        // doesn't try to do any hierarchy logic or rerun the owner assignment
        TriggerContextHelper helper = new TriggerContextHelper();
    	update nonUKAccounts; 	
    }*/
    
    private static void updateAccountOwners(Set<Id> topLevelAccounts)
    {
    	Map<String, RecordType> accountRecordTypes = GetRecordTypes('Account');
    	// Updating Account owners for Ultimate Parent.
    	
        Set<String> countries = new Set<String>();
        Set<String> postCodes = new Set<String>();
        
        Map<Id, AccountHierarchy> hierarchy = new Map<Id, AccountHierarchy>();
        for (Account a : [
        	Select
        		Id,
        		Name,
        		ParentId,
        		Ultimate_Parent__c,
        		Ultimate_Parent__r.Exclude_From_Assignment__c,
                Principle_Address_Country__c,
                Principle_Address_ZIP_Postal_Code__c,
                Group_Formula__c,
                Exclude_From_Assignment__c,
                OwnerId,
                Ultimate_Parent__r.OwnerId,
                Area__c,
                RecordTypeId,
                NumberOfEmployees
            FROM
            	Account
            WHERE
            	Id IN :topLevelAccounts
            OR
            	Ultimate_Parent__c IN :topLevelAccounts])
        {
            // If ultimate parent is null it means this account is the ultimate parent
            if (a.Ultimate_Parent__c == null)
            {
                // If there is a hierarchy with this id, set the parent to this Account
                if (hierarchy.containsKey(a.Id))
                	hierarchy.get(a.Id).parent = a;
                // else, create a new hierarchy
                else
                	hierarchy.put(a.Id, new AccountHierarchy(a));
                
                // calculate address criteria to use when finding an area
                if (a.Principle_Address_Country__c == 'United Kingdom')
                {
                    // get first part of postcode
                    String postcode = parsePostcode(a.Principle_Address_ZIP_Postal_Code__c);
                    if (postcode != null && postcode != '')
                    {
                    	// If there is a valid postcode, add it to the Account Heirarchy record.
                        postCodes.add(postcode);
                        hierarchy.get(a.Id).postcodeDistrict = postcode;
                    }
                }
                else
                	// Non-UK country, add to parentCountry.
                	countries.add(a.Principle_Address_Country__c);
                continue;
            }
            // If ultimate parent is not null it means this account is not an ultimate parent
            else
            {
                // Check to see if there is a hierarchy with this ultimate parent
                if (!hierarchy.containsKey(a.Ultimate_Parent__c))
                {
                	// Add this Account
                    hierarchy.put(a.Ultimate_Parent__c, new AccountHierarchy(null));
                }
                
                // add this account to hierarchy and parent
                hierarchy.get(a.Ultimate_Parent__c).children.add(a);
                
                if (a.Principle_Address_Country__c == 'United Kingdom')
                {
                	// get first part of postcode
                	String postcode = parsePostcode(a.Principle_Address_ZIP_Postal_Code__c);
                	if (postcode != null && postcode != '')
                	{
                		// If there is a valid postcode, add it to the Account Heirarchy record.
                    	postCodes.add(postcode);
                	}
                }
                else
                	countries.add(a.Principle_Address_Country__c);
                
                
                if (!a.Ultimate_Parent__r.Exclude_From_Assignment__c)
                {
	                if (!a.Exclude_From_Assignment__c)
	                {
	                	if (a.Principle_Address_Country__c == 'United Kingdom')
	                	{
	                		a.OwnerId = a.Ultimate_Parent__r.OwnerId;
	                	}
	                }
                }
                else
                {
                	if (a.Principle_Address_Country__c == 'United Kingdom')
	                {
	                	a.OwnerId = a.Ultimate_Parent__r.OwnerId;
	                }
                }         
            }
        }
        
        List<Account> accountsToUpdate = new List<Account>();
        
        Map<String, Map<String, Area__c>> ukAreas = getUkAreas(Countries, PostCodes);		// UK Countries
        Map<String, Map<String, Area__c>> nonUkAreas = getNonUkAreas(Countries);			// Non UK Countries
        for (AccountHierarchy accountHierarchy : hierarchy.values())
        {
        	// May need to modify this to take into account UltimateParent
  	
        	if (accountHierarchy.parent.RecordTypeId == accountRecordTypes.get('Private Delegate').Id)
        	{
        		
        		Area__c found;
        		found = FindAreaFromAddressEx(accountHierarchy, accountHierarchy.parent, ukAreas, 'Private Delegate');
        		if (found == null)
        			found = FindAreaFromAddressEx(accountHierarchy, accountHierarchy.parent, nonUkAreas, 'Private Delegate');        		
        		if (found != null)
        		{
        			accountHierarchy.parent.Area__c = found.Id;
        			//accountHierarchy.parent.Group_Formula__c = found.Type__c;
        			if (accountHierarchy.parent.OwnerId != found.Territory__r.Territory_Manager__c)
        				accountHierarchy.parent.OwnerId = found.Territory__r.Territory_Manager__c;
        			accountsToUpdate.add(accountHierarchy.parent);
        		}
        	}
        	else
        	{
        		Area__c found;
        		found = FindAreaFromAddressEx(accountHierarchy, accountHierarchy.parent, ukAreas, 'Last weeks washing');
        		if (found == null)
        			found = FindAreaFromAddressEx(accountHierarchy, accountHierarchy.parent, nonUkAreas, 'Last weeks washing');
        		System.debug('\n@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\n' + found + '\n@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\n');        		
        		if (found != null)
        		{
        			accountHierarchy.parent.Area__c = found.Id;
        			//account.Group_Formula__c = found.Type__c + '-Child';
        			if (accountHierarchy.parent.OwnerId != found.Territory__r.Territory_Manager__c)
        			{
        				accountHierarchy.parent.OwnerId = found.Territory__r.Territory_Manager__c;
        			}
        			accountsToUpdate.add(accountHierarchy.parent);
        		}        		
        	}
        	
        	
        	for (Account account : accountHierarchy.children)
        	{
        		Area__c found;
        		found = FindAreaFromAddressEx(accountHierarchy, account, ukAreas, 'Last weeks washing');
        		if (found == null)
        			found = FindAreaFromAddressEx(accountHierarchy, account, nonUkAreas, 'Last weeks washing');        		
        		if (found != null)
        		{
        			account.Area__c = found.Id;
        			//account.Group_Formula__c = found.Type__c + '-Child';
        			if (account.OwnerId != found.Territory__r.Territory_Manager__c)
        			{
        				account.OwnerId = found.Territory__r.Territory_Manager__c;
        			}
        			accountsToUpdate.add(account);
        		}        		
        	}
        	
        	
        	
        	
        	
        	
        	
        	
/*            if (h.parent != null)
            {
                // use the parent to figure out account owners
                Id accountOwner = null;
                
                // Find area from parent address
                Area__c found = findAreaFromAddress(h, areas);
                if (found != null)
                	accountOwner = found.Territory__r.Territory_Manager__c;
                
                if (h.parent.Exclude_From_Assignment__c == false && (h.parent.OwnerId != accountOwner || h.parent.Area__c != found.Id))
                {
                    if (accountOwner != null)
                    	h.parent.OwnerId = accountOwner;
                    h.parent.Area__c = (found != null ? found.Id : null);
                    accountsToUpdate.add(h.parent);
                }
                
                // Modify all child owners
                for (Account child : h.children)
                {
                    if (child.Exclude_From_Assignment__c == false && (child.OwnerId != accountOwner || child.Area__c != found.Id))
                    {
                        if (accountOwner != null)
                        	child.OwnerId = accountOwner;
                        child.Area__c = (found != null ? found.Id : null);
                        accountsToUpdate.add(child);
                    }
                }
            }*/
        }
        
        // Create new trigger context helper so that when updating accounts it 
        // doesn't try to do any hierarchy logic or rerun the owner assignment
        TriggerContextHelper helper = new TriggerContextHelper();
        update accountsToUpdate;
        
        // update all associated records
        
        // Update associated contacts - select all contacts where the account id is the top parent or 
        // account's ultimate parent field is the top parent
        List<Contact> contactsToUpdate = new List<Contact>();
        for (Contact contact : [
        	SELECT
        		Id,
        		OwnerId,
        		AccountId,
        		Account.Ultimate_Parent__c 
            FROM
            	Contact 
            WHERE
            	AccountId IN :hierarchy.keySet()
            OR
            	Account.Ultimate_Parent__c in :hierarchy.keySet()])
        {
            Id key = null;
            if (hierarchy.containsKey(contact.AccountId))
            	key = contact.AccountId;
            else if (hierarchy.containsKey(contact.Account.Ultimate_Parent__c))
            	key = contact.Account.Ultimate_Parent__c;
            
            if (key != null && hierarchy.get(key).parent.OwnerId != contact.OwnerId)
            {
                contact.OwnerId = hierarchy.get(key).parent.OwnerId;
                contactsToUpdate.add(contact);
            }
        }
        update contactsToUpdate;
        
        // Update associated opportunities (open only) - select all opportunities where the account id is 
        // the top parent or account's ultimate parent field is the top parent
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        for (Opportunity opp : [
        	SELECT
        		Id,
        		OwnerId,
        		AccountId,
        		Account.Ultimate_Parent__c 
            FROM
            	Opportunity 
            WHERE
               (AccountId in :hierarchy.keySet()
            OR
            	Account.Ultimate_Parent__c in :hierarchy.keySet())
            AND
            	IsClosed = false])
        {
            Id key = null;
            if (hierarchy.containsKey(opp.AccountId))
            	key = opp.AccountId;
            else if (hierarchy.containsKey(opp.Account.Ultimate_Parent__c))
            	key = opp.Account.Ultimate_Parent__c;
            
            if (key != null && hierarchy.get(key).parent.OwnerId != opp.OwnerId)
            {
                opp.OwnerId = hierarchy.get(key).parent.OwnerId;
                oppsToUpdate.add(opp);
            }
        }
        update oppsToUpdate;
        
        // Update associated tasks (open only) - select all tasks where the account id is 
        // the top parent or account's ultimate parent field is the top parent
        List<Task> tasksToUpdate = new List<Task>();
        for (Task task : [
        	SELECT
        		Id,
        		OwnerId,
        		AccountId,
        		Account.Ultimate_Parent__c 
            FROM
            	Task 
            WHERE
               (AccountId in :hierarchy.keySet()
            OR
            	Account.Ultimate_Parent__c in :hierarchy.keySet())
            AND
            	IsClosed = false])
        {
            Id key = null;
            if (hierarchy.containsKey(task.AccountId))
            	key = task.AccountId;
            else if (hierarchy.containsKey(task.Account.Ultimate_Parent__c))
            	key = task.Account.Ultimate_Parent__c;
            
            if (key != null && hierarchy.get(key).parent.OwnerId != task.OwnerId)
            {
                task.OwnerId = hierarchy.get(key).parent.OwnerId;
                tasksToUpdate.add(task);
            }
        }
        update tasksToUpdate;
        
        // Update associated events (open only) - select all events where the account id is 
        // the top parent or account's ultimate parent field is the top parent
        List<Event> eventsToUpdate = new List<Event>();
        for (Event event : [
        	SELECT
        		Id,
        		OwnerId,
        		AccountId,
        		Account.Ultimate_Parent__c 
            FROM
            	Event 
            WHERE
               (AccountId in :hierarchy.keySet()
            OR
            	Account.Ultimate_Parent__c in :hierarchy.keySet())
            AND
            	StartDateTime > :System.now()])
        {
            Id key = null;
            if (hierarchy.containsKey(event.AccountId))
            	key = event.AccountId;
            else if (hierarchy.containsKey(event.Account.Ultimate_Parent__c))
            	key = event.Account.Ultimate_Parent__c;
            
            if (key != null && hierarchy.get(key).parent.OwnerId != event.OwnerId)
            {
                event.OwnerId = hierarchy.get(key).parent.OwnerId;
                eventsToUpdate.add(event);
            }
        }
        update eventsToUpdate;
    }
    
    private static Map<String, RecordType> GetRecordTypes(String sObjectType)
    {
    	Map<String, RecordType> recordTypes = new Map<String, RecordType>();
    	for (RecordType recordType : [
            SELECT
                Id,
                Name
            FROM
                RecordType
            WHERE
                SobjectType = :sObjectType
            AND
            	IsActive = true])
        {
        	recordTypes.put(recordType.Name, recordType);        	
        }
        return recordTypes;
    }
    
    /*
    	AB
    	Lookup areas based on country only, for processing non-UK accounts (no postcode).
    */
    private static Map<String, Map<String, Area__c>> getNonUKAreas(Set<String> countries)
    {
    	Map<String, Map<String, Area__c>> areas = new Map<String, Map<String, Area__c>>();
        
        for (Area__c a : [
        	SELECT
        		Id,
        		Name,
        		Area_Postcode__c,
        		Country__c,
        		Postcode_District__c, 
                Territory__c,
                Territory__r.Territory_Manager__c,
                Type__c 
            FROM
            	Area__c 
            WHERE
            	Country__c IN :countries
            AND
            	Country__c != 'United Kingdom'])
        {
            String key = a.Country__c;
            
            if (!areas.containsKey(key))
            	areas.put(key, new Map<String, Area__c>());
            areas.get(key).put(a.Type__c, a);
        }
        
        return areas;
    }
    
    private static Map<String, Map<String, Area__c>> getUKAreas(Set<String> countries, Set<String> postcodes)
    {
        Map<String, Map<String, Area__c>> areas = new Map<String, Map<String, Area__c>>();
        
        for (Area__c a : [
        	SELECT
        		Id,
        		Name,
        		Area_Postcode__c,
        		Country__c,
        		Postcode_District__c, 
                Territory__c,
                Territory__r.Territory_Manager__c,
                Type__c 
            FROM
            	Area__c 
            WHERE
            	Country__c = 'United Kingdom'
            AND
            	Area_Postcode__c in :postcodes])
        {
            // brm - 16 August 2010 - Changed area lookup field from postcode district to area postcode
            String key = a.Country__c + (a.Country__c == 'United Kingdom' ? '-' + a.Area_Postcode__c : '');
            
            if (!areas.containsKey(key))
            	areas.put(key, new Map<String, Area__c>());
            areas.get(key).put(a.Type__c, a);
        }
        
        return areas;
    }
    
    private static Area__c FindAreaFromAddressEx(AccountHierarchy hierarchy, Account account, Map<String, Map<String, Area__c>> areas, String areaType)
    {
    	String searchCriteria = hierarchy.parent.Principle_Address_Country__c + (hierarchy.parent.Principle_Address_Country__c == 'United Kingdom' ? '-' + hierarchy.postcodeDistrict : '');
        boolean bFound = false;
        if (areas.containsKey(searchCriteria))
        {
            Map<String, Area__c> foundDistricts = areas.get(searchCriteria);
            if(areaType == 'Private Delegate' && foundDistricts.get('Private Delegate') != null)
            {
            	return foundDistricts.get('Private Delegate');
            }
            else
            {
            	if (account.NumberOfEmployees > 499)
            	{
            		if(foundDistricts.get('KAM') != null)
            			return foundDistricts.get('KAM');
            		else{
            			if(foundDistricts.get('RAM') != null)
            				return foundDistricts.get('RAM');
            		    else{
            		    	if(foundDistricts.get('AE') != null)
            				return foundDistricts.get('AE');
            		    }
            		}
            	}
            	if (account.NumberOfEmployees > 49 && account.NumberOfEmployees < 500 )
            	{
            		if(foundDistricts.get('RAM') != null)
            			return foundDistricts.get('RAM');
            		else{
            			if(foundDistricts.get('AE') != null)
            				return foundDistricts.get('AE');
            		}
            	}
            	if (account.NumberOfEmployees < 50 )
            	{
            		return foundDistricts.get('AE');
            	}
            }            
        }
        return null;	
    }
    
    
    private static Area__c findAreaFromAddress(AccountHierarchy accounts, Map<String, Map<String, Area__c>> areas)
    {
        // Match Country and (if UK) Postcode to list of areas   
        
        String searchCriteria = accounts.parent.Principle_Address_Country__c + (accounts.parent.Principle_Address_Country__c == 'United Kingdom' ? '-' + accounts.postcodeDistrict : '');
        
        if (areas.containsKey(searchCriteria))
        {
            Map<String, Area__c> foundDistricts = areas.get(searchCriteria);
            
            if(isPrivateDelegate(accounts.parent)){
            	for(Area__c thisArea : foundDistricts.values()){
            		if(thisArea.Type__c == 'Private Delegate'){
            			return thisArea;
            		}
            	}
            }
            
            // Match parent group with area type
            if (accounts.parent.Group_Formula__c == 'KAM' && foundDistricts.containsKey('KAM'))
            {
                return foundDistricts.get('KAM');
            }
            else if ((accounts.parent.Group_Formula__c == 'KAM' || accounts.parent.Group_Formula__c == 'RAM') && foundDistricts.containsKey('RAM'))
            {
                return foundDistricts.get('RAM');
            }
            else if ((accounts.parent.Group_Formula__c == 'KAM' || accounts.parent.Group_Formula__c == 'RAM' || accounts.parent.Group_Formula__c == 'AE') && foundDistricts.containsKey('AE'))
            {
                return foundDistricts.get('AE');
            }
        }
        
        return null;
    }
    
    private static Area__c findAreaFromAddress(Account account, Map<String, Map<String, Area__c>> areas)
    {
        // Match Country and (if UK) Postcode to list of areas   
        
        String searchCriteria = account.Principle_Address_Country__c;
        
        if (areas.containsKey(searchCriteria))
        {
            Map<String, Area__c> foundDistricts = areas.get(searchCriteria);
            
            if(isPrivateDelegate(account)){
            	for(Area__c thisArea : foundDistricts.values()){
            		if(thisArea.Type__c == 'Private Delegate'){
            			return thisArea;
            		}
            	}
            }
            
            // Match parent group with area type
            if (account.Group_Formula__c == 'KAM' && foundDistricts.containsKey('KAM'))
            {
                return foundDistricts.get('KAM');
            }
            else if ((account.Group_Formula__c == 'KAM' || account.Group_Formula__c == 'RAM') && foundDistricts.containsKey('RAM'))
            {
                return foundDistricts.get('RAM');
            }
            else if ((account.Group_Formula__c == 'KAM' || account.Group_Formula__c == 'RAM' || account.Group_Formula__c == 'AE') && foundDistricts.containsKey('AE'))
            {
                return foundDistricts.get('AE');
            }
        }        
        return null;
    }
    
    private static String parsePostcode(String postcode)
    {
        if (postcode != null && postcode != '')
        {
            // Get the first letters of postcode (before the numbers)
            String[] splitted = postcode.split('[0-9]');
            if (splitted.size() > 0 && splitted[0] != null && splitted[0] != '') 
                return splitted[0];
        }
        
        return null;
    }
    
    public class AccountHierarchy
    {
        public Account parent				{ get; set; }
        public List<Account> children		{ get; private set; }
        public String postcodeDistrict		{ get; set; }
        
        public AccountHierarchy(Account p)
        {
        	if (p != null)
            	this.parent = p;
            this.children = new List<Account>();
        }
    }
    
    public class AccountLinkedList
    {
    	public Account account				{ get; set; }
    	public List<Account> childAccounts	{ get; set; }
    	public boolean hasChildren			{ get; set; }
    	public AccountLinkedList(Account account)
    	{
    		this.account = account;
    		childAccounts = new List<Account>();
    		hasChildren = false;
    	}
    	public void AddChildren(List<Account> accounts)
    	{
    		for (Account account : accounts)
    		{
    			if (account.ParentId == this.account.Id)
    			{
    				hasChildren = true;
    				childAccounts.add(account);
    			}
    				
    		}
    	}
    }
    
    private static boolean isPrivateDelegate(Account acc){
    	
    	System.debug('** isPrivateDelegate account: ' + acc.id);
    	
        Id privateDelegateRecordTypeId = [select Id from RecordType where 
        	SObjectType = 'Account' and Name = 'Private Delegate' limit 1].get(0).Id;
       
        boolean isPrivateDelegate = false;
        if(acc.RecordTypeId == privateDelegateRecordTypeId){
        	isPrivateDelegate = true;
        }
        
        System.debug('** isPrivateDelegate result: ' + isPrivateDelegate);
        
        return isPrivateDelegate;
        
    }
}