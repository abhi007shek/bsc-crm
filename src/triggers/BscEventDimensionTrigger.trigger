trigger BscEventDimensionTrigger on Special_Event__c (after insert)
// Purpose of this trigger is to get rid of the previous workflow Update Event Ref
// to generate the name of the event and also to create
// a dimension 4 entry and attach it to the Special_Event__c record
{
	BSCEventTriggerMethods.createDimension4(Trigger.new);
/*for (Special_Event__c se : Trigger.new)
{
   Special_Event__c b = new Special_Event__c();
   b=se.clone();
   product2 prod = [Select productcode  From product2 where id = :b.product__c][0];
   b.name = prod.productcode + '/'+ b.Event_Auto_Number__c;
   c2g__codaDimension4__c dim = new c2g__codaDimension4__c();
   dim.c2g__ReportingCode__c=b.name;
   dim.Name=b.name;
   dim.CurrencyIsoCode=se.currencyIsoCode;
   try
   {
     insert dim;
     b.Dimension_4__c = dim.id;
     try
     {
        update b;
     }
     catch(Exception e)
     {
     	se.adderror(e);
     }
   }
   catch(Exception f)
   {
   	se.adderror(f);
   }
  }*/
}