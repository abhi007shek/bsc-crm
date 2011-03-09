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

global class BulkPostInvoicesWebService 
{
    /**
     * Simple web service to bulk post invoices from a List View
     *   Note: Does not validate the ID's for invoices at correct status
     **/
    webservice static void postInvoices(List<ID> invoiceIDs)
    {
        // Issue Async Apex job to maximise governor limits and improve initial response time
        postInvoicesJob(invoiceIds);
    }
    
    @future
    public static void postInvoicesJob(List<ID> invoiceIDs)
    {
        // Build list of invoice references
        List<c2g.CODAAPICommon.Reference> refs = new List<c2g.CODAAPICommon.Reference>();
        for(ID id : invoiceIDs)
        { 
            c2g.CODAAPICommon.Reference ref = new c2g.CODAAPICommon.Reference();
            ref.Id = id;
            refs.add(ref);
        }
        
        // Call FinancialForce API to bulk post given invocies (users current company)
        c2g.CODAAPISalesInvoice_3_0.BulkPostInvoice(null, refs);
        
        // TODO: Email notification of completion?
        // ...              
    }
}