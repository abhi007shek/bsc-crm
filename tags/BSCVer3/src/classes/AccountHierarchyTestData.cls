public class AccountHierarchyTestData {

	public static void createTestHierarchy() {
		// Create Accounts with Hierarchy
	
		// Create Top Level Accounts
	
	
		Account[] subAccounts = new Account[]{};
		Account[] accountList = new Account[]{};
		Account[] subAccountsSideTree = new Account[]{};
		Account[] subAccountsList = new Account[]{};
		
		
		String accountName = 'HierarchyTest';
		
		Account parentAccount = new Account(
			Name = accountName + '0',
			ShippingStreet = '1 Main St.',
			ShippingState = 'VA',
			ShippingPostalCode = '12345',
			ShippingCountry = 'USA',
			ShippingCity = 'Anytown',
			Description = 'This is a test account',
			BillingStreet = '1 Main St.',
			BillingState = 'VA',
			BillingPostalCode = '12345',
			BillingCountry = 'USA',
			BillingCity = 'Anytown',
			AnnualRevenue = 10000,
			NumberOfEmployees = 10);
		Account subTreeParent  = new Account();
		Account subTreeSideParent  = new Account();

		insert parentAccount;
		parentAccount = [
			SELECT
				id,
				Name
			FROM
				Account
			WHERE
				name = 'HierarchyTest0'];
		Id parentID = parentAccount.id;
		System.Assert(parentID != null, 'Parent Id not found');
		
		// Create sub accounts
	
		for (Integer i = 0;i < 10; i++)
		{
			subAccounts.add(new Account(
				ParentId = parentAccount.Id,
				Name = accountName + i,
				ShippingStreet = '1 Main St.',
				ShippingState = 'VA',
				ShippingPostalCode = '12345',
				ShippingCountry = 'USA',
				ShippingCity = 'Anytown',
				Description = 'This is a test account',
				BillingStreet = '1 Main St.',
				BillingState = 'VA',
				BillingPostalCode = '12345',
				BillingCountry = 'USA',
				BillingCity = 'Anytown',
				AnnualRevenue = 10000,
				NumberOfEmployees = i));	
		}
		
		insert subAccounts;
		
		accountList = [
			SELECT
				id,
				parentID,
				name
			FROM
				account
			WHERE
				name
			LIKE
				'HierarchyTest%'
			ORDER BY
				Name];
				
		/*for (Integer x = 0; x < accountList.size(); x++)
		{
			if (accountList[x].name != 'HierarchyTest0')
			{
				accountList[x].parentID = parentID;
				parentID=accountList[x].Id;	
			}
		}
		
		update accountList;*/
		
		subTreeParent = [
			SELECT
				id,
				parentID,
				Name
			FROM
				account
			WHERE
				name = 'HierarchyTest4'];
		parentID = subTreeParent.Id;

		for (Integer y = 0; y < 10; y++)
		{
			subAccountsSideTree.add(new Account(
				Name = accountName + '4.' + y,
				ParentId = parentID,
				ShippingStreet = '1 Main St.',
				ShippingState = 'VA',
				ShippingPostalCode = '12345',
				ShippingCountry = 'USA',
				ShippingCity = 'Anytown',
				Description = 'This is a test account',
				BillingStreet = '1 Main St.',
				BillingState = 'VA',
				BillingPostalCode = '12345',
				BillingCountry = 'USA',
				BillingCity = 'Anytown',
				AnnualRevenue = 10000,
				NumberOfEmployees = y));	
		}

		insert subAccountsSideTree;
		
		subAccountsList = [
			SELECT
				id,
				parentID,
				name
			FROM
				account
			WHERE
				name
			LIKE
				'HierarchyTest4%'];

		/*for (Integer z = 1; z < subAccountsList.size(); z++)
		{
			subAccountsList[z].parentID = parentID;
			parentID=accountList[z].Id;	
		}
		
		update subAccountsList;*/
	}
}