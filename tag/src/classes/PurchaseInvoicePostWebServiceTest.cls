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

@IsTest 
private class PurchaseInvoicePostWebServiceTest 
{
	static
	{
		// Enable Apex Text environment friendly code paths
		PurchaseInvoicePostWebService.TestMode = true;		
	}
	
	/**
	 * Test the Apex Web Service method behind the 'Post Selected PurchaseInvoices' custom list view JavaScript button
	 **/
	private static testmethod void testPostPurchaseInvoices()
	{
		// Invoke the web service method
		List<ID> selectedRows = new List<ID>();
		selectedRows.add('a0wA0000000HEp3');	
		PurchaseInvoicePostWebService.postPurchaseInvoices(selectedRows);
		// What no asserts?
		//   (since these tests cannot call the FinancialForce.com API (to much data setup requitred for a test context) there is little in this case to assert)
	}

	/**
	 * Test the Apex Web Service method behind the 'Post In Progress PurchaseInvoices' custom list view JavaScript button
	 **/
	private static testmethod void testPostInProgressPurchaseInvoices()
	{
		// Invoke the web service method		
		PurchaseInvoicePostWebService.postInProgressPurchaseInvoices();
		// What no asserts?
		//   (since these tests cannot call the FinancialForce.com API (to much data setup requitred for a test context) there is little in this case to assert)
	}
}