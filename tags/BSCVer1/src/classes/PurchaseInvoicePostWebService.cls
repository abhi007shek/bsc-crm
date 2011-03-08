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
 * This code represents a basic example of how to post a selection of PurchaseInvoices 
 *   via Batch Apex using the custom chunk size feature
 **/
global class PurchaseInvoicePostWebService
{
	// Controls the execution of Apex Test environment friendly code paths
	public static Boolean TestMode = false; 
	
	/**
	 * Simple web service to issue a Batch Apex job to post the corresponding PurchaseInvoices	 
	 *
	 *   NOTE: Apply the following JavaScript logic to a custom list view button on the codaPurchaseInvoice__c object
	 *
	 **/
	/**
		{!REQUIRESCRIPT('/soap/ajax/17.0/connection.js')}
		{!REQUIRESCRIPT('/soap/ajax/17.0/apex.js')}
		var idArr= {!GETRECORDIDS($ObjectType.c2g__codaPurchaseInvoice__c)};
		var result = sforce.apex.execute('PurchaseInvoicePostWebService', 'postPurchaseInvoices', { ids : idArr } );
		alert('A background task to post the selected PurchaseInvoices has been submitted.\nReview Apex Jobs for completion status.');	
	 **/	 
	webservice static void postPurchaseInvoices(List<ID> ids)
	{
		// Create Batch Apex handler
		PurchaseInvoiceBulkPost PurchaseInvoicePostBatch = new PurchaseInvoiceBulkPost(ids);
						
		// Special code path for Apex Unit tests?
		if(TestMode)
		{
			// Within an Apex test method context (especially a packaged one) we cannot simply assume PurchaseInvoices exist 
			//   so we must create some dummy in memory records
			List<c2g__codaPurchaseInvoice__c> rows = new List<c2g__codaPurchaseInvoice__c>();
			for(Id rowId : ids)
				rows.add(new c2g__codaPurchaseInvoice__c());
				
			// Invoke directly the Batch Apex methods called normally by the platform
			PurchaseInvoicePostBatch.start(null);
			PurchaseInvoicePostBatch.execute(null, rows);
			PurchaseInvoicePostBatch.finish(null);
			return;
		}
		
		// Start Batch Apex job to post the given PurchaseInvoices (batch chunk size 50)
		Database.executeBatch(PurchaseInvoicePostBatch, 25);		
	}

	/**
	 * Simple web service to issue a Batch Apex job to post any In Progress PurchaseInvoices
	 *
	 *   NOTE: Apply the following JavaScript logic to a custom list view button on the codaPurchaseInvoice__c object
	 *
	 **/
	/**
		{!REQUIRESCRIPT('/soap/ajax/17.0/connection.js')}
		{!REQUIRESCRIPT('/soap/ajax/17.0/apex.js')}
		var result = sforce.apex.execute('PurchaseInvoicePostWebService', 'postInProgressPurchaseInvoices', { });
		alert('A background task to post the all In Progress PurchaseInvoices has been submitted.\nReview Apex Jobs for completion status.');	 
	 **/
	webservice static void postInProgressPurchaseInvoices()
	{
		// Create Batch Apex handler
		PurchaseInvoiceBulkPost PurchaseInvoicePostBatch = new PurchaseInvoiceBulkPost(null);
						
		// Special code path for Apex Unit tests?
		if(TestMode)
		{
			// Within an Apex test method context (especially a packaged one) we cannot simply assume Purchase Invoices exist 
			//   so we must create some dummy in memory records
			List<c2g__codaPurchaseInvoice__c> rows = new List<c2g__codaPurchaseInvoice__c>();
			rows.add(new c2g__codaPurchaseInvoice__c());
			rows.add(new c2g__codaPurchaseInvoice__c());
			rows.add(new c2g__codaPurchaseInvoice__c());
			rows.add(new c2g__codaPurchaseInvoice__c());
			
			// Invoke directly the Batch Apex methods called normally by the platform
			PurchaseInvoicePostBatch.start(null);
			PurchaseInvoicePostBatch.execute(null, rows);
			PurchaseInvoicePostBatch.finish(null);
			return;
		}
		
		// Start Batch Apex job to post In Progress Purchase Invoices (batch chunk size 50)
		Database.executeBatch(PurchaseInvoicePostBatch, 25);		
	}
}