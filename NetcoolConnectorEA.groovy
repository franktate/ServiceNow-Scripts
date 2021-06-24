/*
 Author: Frank Tate
 Description:
 This snippet of code is used to extract all name/value pairs from the Netcool ExtendedAttr field. 
 It is meant to be included in the Netcool Connector Groovy script. For each name/value pair
 in ExtendedAttr, it will create a "ea_name":"value" pair in the additional_info field of the 
 ServiceNow Event.
*/
def noNewLinesEA = it.ExtendedAttr.replace('\u0000','').replaceAll(/\n/,"");
if (noNewLinesEA =~ /=\"/) {
// we have a case where "ExtendedAttr" is formatted nicely and may have some additional useful information
	def cleanea = noNewLinesEA;
   
	//Log.debug("ExtendedAttr = " + cleanea);

   
	def a = cleanea.split("\";");
	a.each { field ->
		def b = field.split("=(?=\")");
		if (b.length == 2) {
			def name = 'ea_' + b[0];
			def value1 = b[1].replaceFirst(/^\"/,"");
			def value = value1.replaceFirst(/\"$/,"");
			//println 'ea_' + b[0] + ':' + b[1] + '"';
			//println name + ":" + value;
			event.setField(name,value);
		}
	   
	}
}
