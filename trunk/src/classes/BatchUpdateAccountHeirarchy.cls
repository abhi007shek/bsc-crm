global class BatchUpdateAccountHeirarchy implements Database.Batchable<sObject>
{
	global final String Query;
	public List<TreeStructureMap> tsm = new List<TreeStructureMap>();
	public Map<String, TreeStructureMap> masm = new Map<String, TreeStructureMap>();
	public List<Integer> maxLevel = new List<Integer>();
	public static boolean isTest = false;
	
	global BatchUpdateAccountHeirarchy(Integer size)
	{
		if (isTest)
			Query = 'SELECT Id FROM Account WHERE ParentId != null LIMIT ' + size;
		else
			Query = 'SELECT Id FROM Account LIMIT ' + size;
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC)
	{
		return Database.getQueryLocator(query);
	}
	
	global void execute(Database.BatchableContext BC, List<Account> scope)
	{
		for (Account s : scope)
		{
			tsm.clear();
			tsm = formatTreeStructure(s.Id);
			
			// Calculate employees
	        TreeNode treenode = null;
	        for (TreeStructureMap treeObj : tsm)
	        {
	            if (treeObj.account.ParentId == null)
	            {
	                treenode = new TreeNode(treeObj.account, null);
	            }
	            else
	            {
	                treenode.AddNode(treeObj.account);
	            }
	        }
	        
	        Map<Id, Account> accountMap = treeNode.GetList();

	        for (TreeStructureMap treeObj : tsm)
	        {
	        	Account a = accountMap.get(treeObj.account.Id);
	        	if (a != null)
	        	{
	        		treeObj .account.Hierarchy_Employees__c = a.Hierarchy_Employees__c;
	        	}
	        	else
	        	{
	        		System.debug('\nOOOOOOOOOOOOOOOOOO\nUnknown account Id  \n');
	        	}
	        }
	        Account_Trigger_Flags__c settings =Account_Trigger_Flags__c.getInstance('Deactivated');
			settings.Account_Assignment_Deactivated__c = true;
			update settings;
			update accountMap.Values();

			settings.Account_Assignment_Deactivated__c = false;
			update settings;	        
		}
		//update scope;
	}
	
	public TreeStructureMap[] formatTreeStructure(String currentId)
    {
        List<TreeStructureMap> asm = new List<TreeStructureMap>();
        masm.clear();

        List<Account> al = new List<Account>{};
        List<ID> currentParent = new List<ID>{};
        Map<ID, String> nodeList = new Map<ID, String>{};
        List<String> nodeSortList = new List<String>{};
        List<Boolean> levelFlag = new List<Boolean>{};
        List<Boolean> closeFlag = new List<Boolean>{};
        String nodeId = '0';
        String nodeType = 'child';
        Integer count = 0;
        Integer level = 0;
        Boolean endOfStructure = false;
        
        // Find highest level obejct in the structure
        //
        currentParent.add(GetTopElement(currentId));

        // Loop though all children
        while (!endOfStructure )
        {
            if(level==0)
            {     
                al = [
                	SELECT
                		a.ParentId,
                		a.NumberOfEmployees,
                		a.Id,
                		a.Hierarchy_Employees__c,
                		a.Employees_Group__c
                	FROM
                		Account a
                	WHERE
                		a.id
                	IN
                		:CurrentParent ORDER BY a.Name];
            }
            else
            {
   
                al = [
                	SELECT
                		a.ParentId,
                		a.NumberOfEmployees,
                		a.Id,
                		a.Hierarchy_Employees__c,
                		a.Employees_Group__c
                	FROM
                		Account a
                	WHERE
                		a.ParentID
                	IN
                		:CurrentParent ORDER BY a.Name];
            }

            if(al.size() == 0)
            {
                endOfStructure = true;
            }
            else
            {
                currentParent.clear();
                for (Integer i = 0 ; i < al.size(); i++)
                {
                    Account a = al[i];
                    if (level > 0)
                    {
                        nodeId=NodeList.get(a.ParentId)+'.'+String.valueOf(i);
                    }
                    else
                    {
                        nodeId=String.valueOf(i);
                    }
                    masm.put( NodeID, new TreeStructureMap(nodeID, levelFlag, closeFlag, nodeType, false, false, a));
                    currentParent.add(a.id);
                    nodeList.put(a.id,nodeId);
                    nodeSortList.add(nodeId);
                }
                maxLevel.add(level);                
                level++;
            }
        }
        
        NodeSortList.sort();
        for (Integer i = 0; i < NodeSortList.size();i++)
        {
            List<String> pnl = new List<String> {};
            List<String> cnl = new List<String> {};
            List<String> nnl = new List<String> {};
            
            if (i > 0)
            {
                String pn = NodeSortList[i-1];
                pnl = pn.split('\\.',-1);
            }

            String cn = NodeSortList[i];
            cnl = cn.split('\\.',-1);

            if (i < NodeSortList.size()-1)
            {
                String nn = NodeSortList[i+1];
                nnl = nn.split('\\.',-1);
            }
            TreeStructureMap tasm = masm.get(cn);
            if (cnl.size() < nnl.size())
            {
                //Parent
                if (isLastNode(cnl))
                {
                    tasm.nodeType='parent_end';
                }
                else 
                {
                    tasm.nodeType='parent';
                }
            }
            else if (cnl.size() > nnl.size())
            {
                tasm.nodeType='child_end';
                tasm.closeFlag=setcloseFlag(cnl, nnl, tasm.nodeType);
            }
            else
            {
                tasm.nodeType='child';
            }
            tasm.levelFlag = setlevelFlag(cnl, tasm.nodeType); 

            if (tasm.account.id == currentId)
            {
                tasm.currentNode=true;
            }

            asm.add(tasm);
        }
        asm[0].nodeType='start';
        asm[asm.size()-1].nodeType='end';
        return asm;
    }
    
    public List<Boolean> setlevelFlag(List<String> nodeElements, String nodeType)
    {
        List<Boolean> flagList = new List<Boolean>{};
        String searchNode = '';
        String workNode = '';
        Integer cn = 0;
        for(Integer i = 0; i < nodeElements.size()-1;i++)
        {
            cn = Integer.valueOf(nodeElements[i]);
            cn++;
            searchNode=workNode + String.valueOf(cn);
            workNode=workNode + nodeElements[i] + '.';
            if (masm.containsKey(searchNode))
            {
                flagList.add(true);
            }
            else
            {
                flagList.add(false);
            }
        }
        return flagList;
    }
    
    public List<Boolean> setcloseFlag(List<String> cnl, List<String> nnl, String nodeType)
    {
        List<Boolean> flagList = new List<Boolean>{};
        String searchNode = '';
        String workNode = '';
        Integer cn = 0;
        for(Integer i = nnl.size(); i < cnl.size();i++)
        {
        	flagList.add(true);
        }
        return flagList;
    }
    
    public Boolean isLastNode(List<String> nodeElements)
    {
        String searchNode = '';
        Integer cn = 0;
        for(Integer i = 0; i < nodeElements.size();i++)
        {
            if (i == nodeElements.size()-1)
            {
                cn = Integer.valueOf(nodeElements[i]);
                cn++;
                searchNode=searchNode + String.valueOf(cn);
            }
            else
            {
                searchNode=searchNode + nodeElements[i] + '.';
            }
        }
        if (masm.containsKey(searchNode))
        {
            return false;
        }
        else
        {
            return true;
        }
    }
    
    public String GetTopElement(String objId)
    {
        Boolean top = false;
        while (!top)
        {
            Account a = [
            	SELECT
            		a.id,
            		a.ParentId,
            		a.NumberOfEmployees,
                	a.Hierarchy_Employees__c
            	FROM
            		Account a
            	WHERE
            		a.id = :objId LIMIT 1];

            if (a.ParentID != null)
            {
                objId = a.ParentID;
            }
            else
            {
                top=true;
            }
        }
        return objId ;
    }
    
    global void finish(Database.BatchableContext BC)
	{
		AsyncApexJob a = [
			SELECT
				Id,
				Status,
				NumberOfErrors,
				JobItemsProcessed,
				TotalJobItems,
				CreatedBy.Email
			FROM
				AsyncApexJob
			WHERE
				Id = : BC.getJobId()];
				
		String message = 'The batch Apex job processed ' + a.TotalJobItems + ' batches with '+
			a.NumberOfErrors + ' failures.';
		
		// Send an email to the Apex job's submitter notifying of job completion.
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		String[] toAddresses = new String[] {a.CreatedBy.Email, 'navin.muneesamy@2020management.com'};
		mail.setToAddresses(toAddresses);
		mail.setSubject('BatchUpdateAccountHeirarchy ' + a.Status);
		mail.setPlainTextBody('The batch Apex job processed ' + a.TotalJobItems + ' batches with '+ a.NumberOfErrors + ' failures.');
		Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
	}
	
	
	
	public class TreeNode
	{
		List<TreeNode> Nodes		{ get; set; }
        TreeNode ParentNode			{ get; set; }
        Account account				{ get; set; }
		
		public TreeNode(Account account, TreeNode parent)
        {
            this.account = account;
            this.ParentNode = parent;
            this.Nodes = new List<TreeNode>();
            if (account.NumberOfEmployees == null)
            	account.NumberOfEmployees = 0;
            account.Hierarchy_Employees__c = account.NumberOfEmployees;
            
            if (this.ParentNode != null)
                this.SetHierarchyEmployees(account.NumberOfEmployees);
        }
		
		public void AddNode(Account account)
        {
            if (this.account.Id == account.ParentId)
            {
                this.Nodes.Add(new TreeNode(account, this));
            }
            else
            {
                RecurseNodes(account, this);
            }
        }
		
		private void RecurseNodes(Account account, TreeNode parentNode)
        {
            for (TreeNode node : parentNode.Nodes)
            {
                if (node.account.Id == account.ParentId)
                {
                    node.Nodes.Add(new TreeNode(account, node));
                }
                if (node.Nodes.Size() > 0)
                {
                    RecurseNodes(account, node);
                }
            }
        }

        public void SetHierarchyEmployees(Integer nEmployees)
        {
            TreeNode parentNode = this.ParentNode;
            while (parentNode != null && parentNode.account != null)
            {
            	if (parentNode.account.Hierarchy_Employees__c == null)
                	parentNode.account.Hierarchy_Employees__c = nEmployees;
                else
                	parentNode.account.Hierarchy_Employees__c += nEmployees;
                parentNode = parentNode.ParentNode;
            } 
        }
        
        public Map<Id, Account> GetList()
        {
        	Map<Id, account> retMap = new Map<Id, Account>();
        	this.account.Employees_Group__c = this.account.Hierarchy_Employees__c;
        	retMap.put(this.account.Id, this.account);
            retMap.putAll(RecurseNodes(this.Nodes));
            return retMap;
            
        }

        private Map<Id, Account> RecurseNodes(List<TreeNode> nodes)
        {
        	Map<Id, account> retMap = new Map<Id, Account>();
            for (TreeNode childNode : nodes)
            {
            	childNode.account.Employees_Group__c = this.account.Hierarchy_Employees__c;
            	retMap.put(childNode.account.Id, childNode.account);
                if (childNode.Nodes.Size() > 0)
                    retMap.putAll(RecurseNodes(childNode.Nodes));
            }
            return retMap;
        }
        
	}
	
	public class TreeStructureMap
	{
        public String nodeId;
        public Boolean[] levelFlag = new Boolean[]{};
        public Boolean[] closeFlag = new Boolean[]{};
        public String nodeType;
        public Boolean currentNode;
        
        public Account account;

        //public String getnodeId() { return nodeId; }
        //public Boolean[] getlevelFlag() { return levelFlag; }
        //public Boolean[] getcloseFlag() { return closeFlag; }
        //public String getnodeType() { return nodeType; }
        //public Boolean getcurrentNode() { return currentNode; }

        //public Account getaccount() { return account; }

        //public void setnodeId( String n ) { this.nodeId = n; }
        //public void setlevelFlag( Boolean l ) { this.levelFlag.add(l); }
        //public void setlcloseFlag( Boolean l ) { this.closeFlag.add(l); }
       // public void setnodeType( String nt ) { this.nodeType = nt; }
        //public void setcurrentNode( Boolean cn ) { this.currentNode = cn; }

        //public void setaccount( Account a ) { this.account = a; }

        public TreeStructureMap(String nodeId, Boolean[] levelFlag, Boolean[] closeFlag,
        	String nodeType, Boolean lastNode, Boolean currentNode, Account a)
        {
            this.nodeId = nodeId;
            this.levelFlag = levelFlag; 
            this.closeFlag = closeFlag;
            this.nodeType = nodeType;
            this.currentNode = currentNode;

            this.account = a;
        }
    }
    
    public static testMethod void tests()
	{
		Test.startTest();
		BatchUpdateAccountHeirarchy.isTest = true;
		BatchUpdateAccountHeirarchy batch = new BatchUpdateAccountHeirarchy(1);		
		Database.executeBatch(batch, 100);
		Test.stopTest();
	}  
}