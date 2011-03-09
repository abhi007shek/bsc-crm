@isTest
private class testAccountHierarchy {

	static testMethod void testAccountHierarchy()
	{
		// Instanciate Page		
	
		AccountHierarchyTestData.createTestHierarchy();

		Account topAccount = [
			SELECT
				id,
				Name
			FROM
				account
			WHERE
				Name = 'HierarchyTest0'
			LIMIT
				1];
				
		Account middleAccount = [
			SELECT
				id,
				parentID,
				Name
			FROM
				account
			WHERE
				Name = 'HierarchyTest4'
			LIMIT
				1];
				
		Account bottomAccount = [
			SELECT
				id,
				parentID,
				Name
			FROM
				account
			WHERE
				Name = 'HierarchyTest9'
			LIMIT
				1];
				
		List<Account> accountList = new List<Account>([
			SELECT
				id,
				parentID,
				Name
			FROM
				account
			WHERE
				Name
			LIKE
				'HierarchyTest%']);

		test.startTest();
		
		System.debug('DEBUG: AccountList size: '+ accountList.size());
	
		PageReference AccountHierarchyPage = Page.AccountHierarchyPage;
		Test.setCurrentPage(AccountHierarchyPage);
		ApexPages.currentPage().getParameters().put('id', topAccount.id);
	
		// Instanciate Controller
		AccountStructure controller = new AccountStructure();
		
		// Call Methodes for top account
		controller.setcurrentId(null);
		AccountStructure.ObjectStructureMap[] smt1 = new AccountStructure.ObjectStructureMap[]{};
		smt1 = controller.ObjectStructure;
		System.Assert(smt1.size() > 0, 'Test failed at Top account, no Id');

		controller.setcurrentId(String.valueOf(topAccount.id));
		AccountStructure.ObjectStructureMap[] smt2 = new AccountStructure.ObjectStructureMap[]{};
		smt2 = controller.ObjectStructure;
		System.Assert(smt2.size() > 0, 'Test failed at Top account, with Id: '+smt2.size());

		//Call ObjectStructureMap methodes
		smt2[0].setnodeId('1234567890');
		smt2[0].setlevelFlag(true);
		smt2[0].setlcloseFlag(false);
		smt2[0].setnodeType('parent');
		smt2[0].setcurrentNode(false);
		smt2[0].setaccount(topAccount);
		String nodeId = smt2[0].getnodeId();
		Boolean[] levelFlag = smt2[0].getlevelFlag();
		Boolean[] closeFlag = smt2[0].getcloseFlag();
		String nodeType = smt2[0].getnodeType();
		Boolean currentName = smt2[0].getcurrentNode();
		Account smbAccount = smt2[0].getaccount();


		// Call Methodes for middle account
		controller.setcurrentId(String.valueOf(middleAccount.id));
		AccountStructure.ObjectStructureMap[] smm = new AccountStructure.ObjectStructureMap[]{};
		smm = controller.ObjectStructure;
		System.Assert(smm.size() > 0, 'Test failed at middle account');

		// Call Methodes for bottom account
		controller.setcurrentId(String.valueOf(bottomAccount.id));
		AccountStructure.ObjectStructureMap[] smb = new AccountStructure.ObjectStructureMap[]{};
		smb = controller.ObjectStructure;
		System.Assert(smb.size() > 0, 'Test failed at top account');
		
		delete topAccount;
		test.stopTest();
	}

}