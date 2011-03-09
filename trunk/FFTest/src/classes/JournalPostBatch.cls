/**
 * Copyright (c) 2009, FinancialForce.com, inc
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification, 
 *   are permitted provided that the following conditions are met:
 *
 * - Redistributions of source code must retain the above copyright notice, 
 *      this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright notice, 
 *      this list of conditions and the following disclaimer in the documentation 
 *      and/or other materials provided with the distribution.
 * - Neither the name of the FinancialForce.com, inc nor the names of its contributors 
 *      may be used to endorse or promote products derived from this software without 
 *      specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
 *  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES 
 *  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL 
 *  THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 *  OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 *  OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 *  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
**/

/**
 * This example shows how to implement a basic Batch Apex class around the FinancialForce.com BulkPostJournal API
 **/
global class JournalPostBatch
	implements Database.Batchable<SObject> 
{
	private final List<ID> m_ids;
	
	public JournalPostBatch(List<ID> ids)
	{
		m_ids = ids;	
	}
	
	global Database.QueryLocator start(Database.BatchableContext ctx)
	{
		// Select either all In Progress Journals or those specified 
		if(m_ids==null)
			return Database.getQueryLocator([select ID from c2g__codaJournal__c where c2g__JournalStatus__c = 'In Progress']);
		else
			return Database.getQueryLocator([select ID from c2g__codaJournal__c where id in :m_ids]);
	}

	global void execute(Database.BatchableContext ctx, List<SObject> records)
	{
        // Build list of Journal API references
        List<c2g.CODAAPICommon.Reference> refs = new List<c2g.CODAAPICommon.Reference>();
        for(SObject sobj : records)
        { 
            c2g.CODAAPICommon.Reference ref = new c2g.CODAAPICommon.Reference();
            ref.Id = sobj.id;
            refs.add(ref);
        }
        
        // Call FinancialForce API to bulk post given journals (users current company)
        if(!JournalPostWebService.TestMode)
        	c2g.CODAAPIJournal_3_0.BulkPostJournal(null, refs);		
	}
		
   	global void finish(Database.BatchableContext ctx)
   	{
   	}	
}